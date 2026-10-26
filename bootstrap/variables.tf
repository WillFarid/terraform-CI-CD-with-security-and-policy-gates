# -----------------------------------------------------------------------------
# variables.tf (bootstrap)
# -----------------------------------------------------------------------------
variable "project" {
  description = "Project prefix. Must match the project name used by the environments, because the IAM permissions are scoped to resources starting with it."
  type        = string
  default     = "three-tier"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub user or organization that owns the repository."
  type        = string
  default     = "WillFarid"
}

variable "github_repo" {
  description = "GitHub repository whose workflows may assume the roles."
  type        = string
  default     = "terraform-CI-CD-with-security-and-policy-gates"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket that holds the Terraform state of dev and prod."
  type        = string
  default     = "REPLACE-ME-tfstate-bucket"
}

variable "mock_mode" {
  description = "true = fake credentials and no calls to AWS (offline plan). false for a real deployment."
  type        = bool
  default     = true
}
