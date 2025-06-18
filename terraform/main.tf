# terraform/main.tf
#
# Contains top-level data sources used across other configuration files.

data "aws_caller_identity" "current" {
  # Fetches the AWS account ID of the caller, used for constructing ARNs.
}