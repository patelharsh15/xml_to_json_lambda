# terraform/api_gateway.tf

# 1. The HTTP API Gateway itself
resource "aws_apigatewayv2_api" "xml_to_json_converter" {
  name          = "xml-to-json-api"
  protocol_type = "HTTP"
  description   = "API Gateway for XML to JSON converter"
  

  # API Gateway handles CORS configuration
  cors_configuration {
    allow_origins = ["*"] # Be more specific for production environments
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
  }

  tags = var.tags
}

# 2. The integration between the API Gateway and the Lambda function
resource "aws_apigatewayv2_integration" "xml_to_json_converter" {
  api_id             = aws_apigatewayv2_api.xml_to_json_converter.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.xml_to_json_converter.invoke_arn # Assumes your lambda is named "this"
  payload_format_version = "1.0" # Use this for the simpler event structure
}

# 3. The route that triggers the integration (e.g., POST /convert)
resource "aws_apigatewayv2_route" "xml_to_json_converter" {
  api_id    = aws_apigatewayv2_api.xml_to_json_converter.id
  route_key = "POST /convert" # Defines the path and method
  target    = "integrations/${aws_apigatewayv2_integration.xml_to_json_converter.id}"
}

# 4. A deployment stage for the API
resource "aws_apigatewayv2_stage" "xml_to_json_converter" {
  api_id      = aws_apigatewayv2_api.xml_to_json_converter.id
  name        = "$default" # Creates a default stage accessible at the root invoke URL
  auto_deploy = true
}

# 5. Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.xml_to_json_converter.function_name # Assumes your lambda is named "this"
  principal     = "apigateway.amazonaws.com"

  # The ARN should be specific to the route to follow least privilege
  source_arn = "${aws_apigatewayv2_api.xml_to_json_converter.execution_arn}/${aws_apigatewayv2_stage.xml_to_json_converter.name}/POST/convert"
}



