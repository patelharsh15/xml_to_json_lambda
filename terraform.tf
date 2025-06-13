# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# --- Variables ---
variable "aws_region" {
  description = "The AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "service_name" {
  description = "Name for the Lambda service."
  type        = string
  default     = "xml-to-json-converter"
}

variable "lambda_runtime" {
  description = "The runtime for the Lambda function."
  type        = string
  default     = "python3.10"
}

variable "lambda_architecture" {
  description = "The architecture for the Lambda function."
  type        = string
  default     = "arm64"
}

variable "lambda_memory_size" {
  description = "The memory size for the Lambda function in MB."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "The timeout for the Lambda function in seconds."
  type        = number
  default     = 10
}

variable "log_level" {
  description = "Log level for the Lambda function."
  type        = string
  default     = "DEBUG"
}

# --- IAM Role for Lambda Function ---
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.service_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Service = var.service_name
  }
}

# IAM policy for CloudWatch Logs
resource "aws_iam_policy" "lambda_log_policy" {
  name        = "${var.service_name}-lambda-log-policy"
  description = "IAM policy for Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.service_name}-*:*"
      },
    ]
  })
}

# Attach the log policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_log_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}

# Data source for AWS account ID (used in log policy resource ARN)
data "aws_caller_identity" "current" {}


# --- Lambda Function Deployment Package ---

resource "null_resource" "build_lambda_package" {
  triggers = {
    handler_file_hash = filemd5("${path.module}/handler.py")
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${path.module}/.build/lambda_dist
      cp ${path.module}/handler.py ${path.module}/.build/lambda_dist/
      pip install xmltodict -t ${path.module}/.build/lambda_dist/
    EOT
    working_dir = path.module
  }
}

resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/.build/lambda_dist"
  output_path = "${path.module}/.build/${var.service_name}.zip"

  depends_on = [null_resource.build_lambda_package]
}

# --- Lambda Function ---
resource "aws_lambda_function" "xml_to_json_converter" {
  function_name    = var.service_name
  handler          = "handler.convert_xml_to_json"
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = archive_file.lambda_zip.output_path          # Path to the zipped code
  source_code_hash = archive_file.lambda_zip.output_base64sha256 # For Lambda to detect code changes

  environment {
    variables = {
      LOG_LEVEL = var.log_level # Matches serverless.yml environment
    }
  }

  tags = {
    Service = var.service_name
  }
}

# --- Lambda Function URL ---
resource "aws_lambda_function_url" "converter_url" {
  function_name  = aws_lambda_function.xml_to_json_converter.function_name
  authorization_type = "NONE"

  cors {
    allow_methods = ["POST"] # Matches handler.py support for POST only
    allow_origins = ["*"]    # Matches handler.py Access-Control-Allow-Origin
    allow_headers = ["Content-Type"] # Matches handler.py Access-Control-Allow-Headers
  }
}

resource "aws_lambda_permission" "allow_url_invocation" {
  statement_id   = "FunctionURLInvokePermission"
  action         = "lambda:InvokeFunctionUrl"
  function_name  = aws_lambda_function.xml_to_json_converter.function_name
  principal      = "*"
  function_url_auth_type = "NONE"
}

# --- Outputs ---
output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.xml_to_json_converter.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.xml_to_json_converter.arn
}

output "lambda_function_url" {
  description = "The URL of the Lambda function endpoint."
  value       = aws_lambda_function_url.converter_url.function_url
}