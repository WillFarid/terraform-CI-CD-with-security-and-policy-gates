# -----------------------------------------------------------------------------
# main.tf (bootstrap)
# Lets GitHub Actions authenticate to AWS WITHOUT stored access keys (OIDC).
#
# How it works:
#   1. A workflow run asks GitHub for a short-lived signed token (a JWT).
#   2. The token says who is asking, e.g. "repo:OWNER/REPO:environment:prod".
#   3. AWS verifies the signature against the OIDC provider created below, then
#      checks the role's trust policy. If the claims match, it hands back
#      temporary credentials (1 hour). No secret is ever stored in GitHub.
#
# Three roles, three levels of trust:
#   plan role      read-only, usable from pull requests and main
#   apply role dev usable ONLY by jobs running in the "dev" environment
#   apply role prod usable ONLY by jobs running in the "prod" environment
#                  (and that environment requires a manual approval)
# -----------------------------------------------------------------------------
locals {
  # Every token from this repository starts with this "subject" prefix.
  subject = "repo:${var.github_org}/${var.github_repo}"

  environments = toset(["dev", "prod"])
}

# --- The identity provider -----------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS now validates GitHub's certificate chain itself, so these values are
  # informational. They are kept because older provider versions require them.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = { Name = "${var.project}-github-oidc" }
}

# =============================================================================
# Plan role: read-only
# =============================================================================
data "aws_iam_policy_document" "trust_plan" {
  statement {
    sid     = "GitHubPlanOnly"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # The token must be meant for AWS.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # ...and must come from a pull request or from the main branch of THIS repo.
    # A fork or another repository cannot satisfy this condition.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "${local.subject}:pull_request",
        "${local.subject}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "${var.project}-github-plan"
  description          = "Read-only role for terraform plan in GitHub Actions"
  assume_role_policy   = data.aws_iam_policy_document.trust_plan.json
  max_session_duration = 3600

  tags = { Name = "${var.project}-github-plan" }
}

# AWS-managed policy: read access to every service, no writes.
resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# State access. The plan role may READ state, but may only create and delete
# the lock file (*.tflock). It can never modify the state itself.
data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "ReadState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/${var.project}/*"]
  }

  statement {
    sid       = "ManageLockFileOnly"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/${var.project}/*/terraform.tfstate.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state-read"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

# =============================================================================
# Apply roles: one per environment
# =============================================================================
data "aws_iam_policy_document" "trust_apply" {
  for_each = local.environments

  statement {
    sid     = "GitHubApplyFrom${title(each.key)}Environment"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only a job that runs inside the matching GitHub Environment gets this
    # claim. For prod, GitHub pauses for human approval BEFORE the job starts,
    # so nobody can reach the prod role without that approval.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.subject}:environment:${each.key}"]
    }
  }
}

resource "aws_iam_role" "apply" {
  for_each = local.environments

  name                 = "${var.project}-github-apply-${each.key}"
  description          = "Role that applies Terraform for ${each.key} from GitHub Actions"
  assume_role_policy   = data.aws_iam_policy_document.trust_apply[each.key].json
  max_session_duration = 3600

  tags = { Name = "${var.project}-github-apply-${each.key}" }
}

# Broad service access, but WITHOUT IAM (PowerUserAccess excludes IAM).
# Trade-off, stated honestly: this is wider than ideal. The next step in a real
# account is to run the pipeline once, then replace this with a policy
# generated from CloudTrail by IAM Access Analyzer.
resource "aws_iam_role_policy_attachment" "apply_power_user" {
  for_each = local.environments

  role       = aws_iam_role.apply[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM is added back, but ONLY for resources whose names start with the project
# prefix. The pipeline can manage the roles this project creates and nothing else.
# It cannot touch these bootstrap roles, because their names start with
# "<project>-github-", which the Deny statement below protects.
data "aws_iam_policy_document" "apply_iam" {
  statement {
    sid    = "ManageProjectRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PassRole",
    ]
    resources = ["arn:aws:iam::*:role/${var.project}-*"]
  }

  statement {
    sid    = "ManageProjectInstanceProfiles"
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]
    resources = ["arn:aws:iam::*:instance-profile/${var.project}-*"]
  }

  # Guard rail: even though the allow above matches by prefix, the pipeline must
  # never be able to edit its own bootstrap roles (that would be privilege escalation).
  statement {
    sid    = "ProtectBootstrapRoles"
    effect = "Deny"
    actions = [
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
    ]
    resources = ["arn:aws:iam::*:role/${var.project}-github-*"]
  }
}

resource "aws_iam_role_policy" "apply_iam" {
  for_each = local.environments

  name   = "project-iam-scoped"
  role   = aws_iam_role.apply[each.key].id
  policy = data.aws_iam_policy_document.apply_iam.json
}

# Each apply role gets read/write on ITS OWN environment's state only.
# The dev role cannot read or change the prod state, and the reverse.
data "aws_iam_policy_document" "apply_state" {
  for_each = local.environments

  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid       = "ReadWriteOwnState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/${var.project}/${each.key}/*"]
  }
}

resource "aws_iam_role_policy" "apply_state" {
  for_each = local.environments

  name   = "terraform-state-${each.key}"
  role   = aws_iam_role.apply[each.key].id
  policy = data.aws_iam_policy_document.apply_state[each.key].json
}
