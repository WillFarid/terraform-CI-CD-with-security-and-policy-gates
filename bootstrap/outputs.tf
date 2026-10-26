# -----------------------------------------------------------------------------
# outputs.tf (bootstrap)
# Copy these ARNs into GitHub (see README, "Enabling deployment").
# They are identifiers, not secrets.
# -----------------------------------------------------------------------------
output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "plan_role_arn" {
  description = "Role for terraform plan. Store as the repository variable AWS_PLAN_ROLE_ARN."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arns" {
  description = "Roles for terraform apply, keyed by environment. Store each as the variable AWS_APPLY_ROLE_ARN inside the matching GitHub Environment."
  value       = { for env, role in aws_iam_role.apply : env => role.arn }
}
