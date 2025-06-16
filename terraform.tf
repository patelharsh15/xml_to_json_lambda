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

  backend "s3" {
    bucket         = "comtech-coop-data"                  
    key            = "xml-to-json-converter/terraform.tfstate"   
    region         = "us-east-1"
  }
}