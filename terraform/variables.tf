# variables.tf
#
# Defines all input variables for the Lambda function and its associated resources.

variable "aws_region" {
  description = <<-DESC
    (Required) The AWS region where the Lambda function and associated resources will be deployed.
    
    Example: `us-east-1`
  DESC
  type        = string
  default     = "us-east-1"
}

variable "lambda_architecture" {
  description = <<-DESC
    (Optional) The instruction set architecture for the Lambda function.
    
    Valid values: `x86_64`, `arm64`
    Example: `arm64`
    Default: `arm64`
  DESC
  type        = string
  default     = "arm64"
}

variable "tags" {
  description = "A map of tags to assign to all created resources for tracking and cost allocation."
  type        = map(string)
  default = {
    Project   = "XML to JSON Converter"
    ManagedBy = "Coop Project"
  }
}

variable "lambda_memory_size" {
  description = <<-DESC
    (Optional) The amount of memory (in MB) that the Lambda function has available.
    Valid values: Multiples of 64MB, from 128MB to 10240MB.
    Example: `128`
    Default: `128`
  DESC
  type        = number
  default     = 128
}

variable "lambda_runtime" {
  description = <<-DESC
    (Required) The runtime environment for the Lambda function.
    
    Example: `python3.10`
    Default: `python3.10`
  DESC
  type        = string
  default     = "python3.10"
}

variable "lambda_timeout" {
  description = <<-DESC
    (Optional) The maximum amount of time (in seconds) that the Lambda function can run before being terminated.
    Valid values: `1` to `900` (15 minutes).
    Example: `10`
    Default: `10`
  DESC
  type        = number
  default     = 30
}

variable "log_level" {
  description = <<-DESC
    (Optional) The logging level for the Lambda function's application logs.
    This value is passed as an environment variable to the Lambda.
    
    Valid values: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`
    Example: `INFO`
    Default: `INFO`
  DESC
  type        = string
  default     = "DEBUG"
}

variable "service_name" {
  description = <<-DESC
    (Required) The base name for the Lambda service and its related AWS resources.
    This name is used as a prefix or identifier for resources like the Lambda function,
    IAM role, and CloudWatch log groups.
    
    Example: `xml-to-json-converter`
    Default: `xml-to-json-converter`
  DESC
  type        = string
  default     = "xml-to-json-converter"
}