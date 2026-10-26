# -----------------------------------------------------------------------------
# providers.tf (bootstrap)
# Same mock-mode switch as the environments: offline by default.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.region

  access_key = var.mock_mode ? "mock-access-key" : null
  secret_key = var.mock_mode ? "mock-secret-key" : null

  skip_credentials_validation = var.mock_mode
  skip_requesting_account_id  = var.mock_mode
  skip_metadata_api_check     = var.mock_mode

  default_tags {
    tags = {
      Project    = var.project
      ManagedBy  = "terraform"
      Repository = var.github_repo
      Stack      = "bootstrap"
    }
  }
}
