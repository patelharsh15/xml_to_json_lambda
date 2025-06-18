# terraform/backend.tf
#
# Defines the S3 backend for storing Terraform's state file remotely.
# This separates the state configuration from the main provider and version settings.

terraform {
  backend "s3" {
    bucket         = "comtech-coop-data"
    key            = "xml-to-json-converter/terraform.tfstate"
    region         = "us-east-1"
  }
}