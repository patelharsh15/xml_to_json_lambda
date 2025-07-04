# terraform/api_gateway.tf (New REST API Version)

# 1. The REST API Gateway itself
resource "aws_api_gateway_rest_api" "xml_to_json_converter" {
  name        = "xml-to-json-rest-api"
  description = "REST API for XML to JSON converter"

  # With REST APIs, you define a binary media type for passthrough behavior
  binary_media_types = [
    "application/xml",
    "text/xml"
  ]
  
  tags = var.tags
}

# 2. The resource (path part), e.g., "/convert"
resource "aws_api_gateway_resource" "convert" {
  rest_api_id = aws_api_gateway_rest_api.xml_to_json_converter.id
  parent_id   = aws_api_gateway_rest_api.xml_to_json_converter.root_resource_id
  path_part   = "convert"
}

# 3. The method for the resource (e.g., POST on /convert)
resource "aws_api_gateway_method" "post_convert" {
  rest_api_id   = aws_api_gateway_rest_api.xml_to_json_converter.id
  resource_id   = aws_api_gateway_resource.convert.id
  http_method   = "POST"
  authorization = "NONE"

  # THIS IS KEY: Enforce the API Key requirement here
  api_key_required = true
}

# 4. The integration between the POST method and the Lambda function
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.xml_to_json_converter.id
  resource_id = aws_api_gateway_resource.convert.id
  http_method = aws_api_gateway_method.post_convert.http_method

  integration_http_method = "POST" # The method used to call the backend (Lambda)
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.xml_to_json_converter.invoke_arn
}

# 5. A deployment to make the API callable.
# This must be triggered to redeploy when the API changes.
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.xml_to_json_converter.id

  # This 'triggers' block is crucial. It tells Terraform to create a new
  # deployment whenever any of the underlying API configurations change.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.convert.id,
      aws_api_gateway_method.post_convert.id,
      aws_api_gateway_integration.lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 6. A stage, like 'dev' or 'prod', which points to a deployment
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.xml_to_json_converter.id
  stage_name    = "prod" # e.g., The API will be at https://.../prod/convert
}

# --- API KEY AND USAGE PLAN SECTION ---

# 7. The API Key resource in API Gateway
resource "aws_api_gateway_api_key" "my_api_key" {
  name  = "xml-to-json-api-key"
  
  # Pull the value directly from the secret we created
  value = aws_secretsmanager_secret_version.api_key_secret_version.secret_string
  
  tags = var.tags
  
  depends_on = [aws_secretsmanager_secret_version.api_key_secret_version]
}

# 8. A Usage Plan to associate the key with the stage
resource "aws_api_gateway_usage_plan" "my_usage_plan" {
  name = "xml-to-json-usage-plan"

  # Associate the usage plan with our API stage
  api_stages {
    api_id = aws_api_gateway_rest_api.xml_to_json_converter.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

}

# 9. The "glue" that links the API Key to the Usage Plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.my_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.my_usage_plan.id
}

# terraform/api_gateway.tf (or wherever your permission is)

# 10. UPDATED Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.xml_to_json_converter.function_name
  principal     = "apigateway.amazonaws.com"

  # This is the updated ARN format for a REST API. It's more specific.
  # It grants permission only for the POST method on the /convert resource.
  source_arn = "${aws_api_gateway_rest_api.xml_to_json_converter.execution_arn}/${aws_api_gateway_stage.prod.stage_name}/POST/convert"
}