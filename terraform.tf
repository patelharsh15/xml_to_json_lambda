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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0" # Required for zipping the Lambda deployment package
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0" # Required for the null_resource to run local commands
    }
  }

  # Configures the remote backend for storing Terraform state.
  # This is a critical best practice for team collaboration and state durability.
  # Replace 'your-terraform-state-bucket' and 'your-dynamodb-lock-table' with actual resources.
  # These resources should ideally be created manually or by a separate, foundational Terraform config.
  backend "s3" {
    bucket         = "your-terraform-state-bucket" # REQUIRED: Change to your S3 bucket name
    key            = "xml-to-json-converter/terraform.tfstate" # Path to the state file within the bucket
    region         = "us-east-1" # REQUIRED: Should match your deployment region
    dynamodb_table = "your-dynamodb-lock-table" # REQUIRED: Change to your DynamoDB table for state locking
    encrypt        = true                      # Encrypts the state file in S3
  }
}