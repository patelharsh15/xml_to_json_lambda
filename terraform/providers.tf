# providers.tf
#
# Configures the AWS provider.

provider "aws" {
  region = var.aws_region # Uses a variable for the AWS region, defined in variables.tf
}