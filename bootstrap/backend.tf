# -----------------------------------------------------------------------------
# backend.tf (bootstrap)
# This stack has its OWN state, separate from dev and prod. It is applied once,
# by a human with admin rights, because it creates the identities that the
# pipeline itself will later use. (The pipeline cannot create its own keys.)
# Placeholder bucket: create it first (versioning, encryption, public access
# blocked) when you have an AWS account.
# -----------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket       = "REPLACE-ME-tfstate-bucket-bootstrap"
    key          = "bootstrap/github-oidc/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
