# The `terraform {}` block is recognised by both OpenTofu and
# Terraform. OpenTofu additionally supports an `opentofu {}` alias if
# you prefer a cleaner tool-specific declaration.
terraform {
  required_providers {
    gigahost = {
      source  = "kradalby/gigahost"
      version = "~> 0.0.1"
    }
  }
}

provider "gigahost" {
  # Recommended: set GIGAHOST_TOKEN env var instead of passing the
  # token through a variable.
  token = var.gigahost_token
}

variable "gigahost_token" {
  type        = string
  sensitive   = true
  description = "Gigahost API bearer token."
}
