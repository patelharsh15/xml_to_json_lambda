# outputs.tf
#
# Defines the output values that are available after the Terraform apply.

output "lambda_function_arn" {
  description = "The Amazon Resource Name (ARN) of the deployed Lambda function."
  value       = aws_lambda_function.xml_to_json_converter.arn
}

output "lambda_function_name" {
  description = "The name of the deployed Lambda function."
  value       = aws_lambda_function.xml_to_json_converter.function_name
}

output "lambda_function_url" {
  description = "The public URL endpoint for invoking the Lambda function."
  value       = aws_lambda_function_url.converter_url.function_url
}