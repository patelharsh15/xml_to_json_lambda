# terraform.tf
#
# Contains core Terraform settings such as required providers and backend configuration.

terraform {
  # Specifies the minimum and maximum Terraform versions this configuration is compatible with.
  required_version = ">= 1.0.0"

  # Declares the providers required by this configuration and their version constraints.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a compatible major version for AWS provider
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0" # Required for the null_resource to run local commands
    }
  }
}