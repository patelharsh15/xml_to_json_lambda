# terraform/lambda.tf
#
# Defines the Lambda function, its URL, and invocation permissions.

# The main Lambda function definition.
resource "aws_lambda_function" "xml_to_json_converter" {
  function_name    = var.service_name
  handler          = "handler.convert_xml_to_json" # Correct handler: filename.function_name
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  role             = aws_iam_role.lambda_exec_role.arn # From iam.tf
  filename         = archive_file.lambda_zip.output_path # From build.tf
  source_code_hash = archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL = var.log_level
    }
  }

  tags = {
    Service = var.service_name
  }
}

# Creates a direct HTTP endpoint for the Lambda function.
resource "aws_lambda_function_url" "converter_url" {
  function_name      = aws_lambda_function.xml_to_json_converter.function_name
  authorization_type = "NONE"

  cors {
    allow_methods = ["POST"]
    allow_origins = ["*"]
    allow_headers = ["Content-Type"]
  }
}

# Grants public access to invoke the Lambda Function URL.
resource "aws_lambda_permission" "allow_url_invocation" {
  statement_id           = "FunctionURLInvokePermission"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.xml_to_json_converter.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}