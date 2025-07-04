# terraform/lambda.tf
#
# Defines the Lambda function, its URL, and invocation permissions.

# The main Lambda function definition.
resource "aws_lambda_function" "xml_to_json_converter" {
  function_name    = var.service_name
  handler          = "handler.convert_xml_to_json"
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  role             = aws_iam_role.lambda_exec_role.arn # From iam.tf

  # This points to the zip file that will be created during 'apply'.
  # Terraform accepts that this file might not exist during 'plan'.
  filename = "${path.module}/${var.service_name}.zip"

  # THIS IS THE KEY FIX:
  # The hash is now based on the trigger from the build resource.
  # When the source code changes, the 'build_lambda_package' resource is marked for replacement.
  # This change in its 'source_code_hash' trigger forces the aws_lambda_function to update,
  # but only AFTER the build resource has finished its 'apply' step (the provisioner).
  source_code_hash = null_resource.build_lambda_package.triggers.source_code_hash

  # Note: The 'depends_on' is no longer strictly necessary because the reference to
  # null_resource.build_lambda_package.triggers.source_code_hash creates an *implicit* dependency.
  # However, keeping it can make the intent clearer.
  depends_on = [
    null_resource.build_lambda_package
  ]
  
  environment {
    variables = {
      LOG_LEVEL = var.log_level,
      API_KEY_SECRET_NAME = aws_secretsmanager_secret.api_key_secret.name
    }
  }

  tags = {
    Service = var.service_name
  }
}


