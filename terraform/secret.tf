# terraform/secrets.tf

# For securely generating a random string for the API key value
resource "random_string" "api_key_value" {
  length  = 40
  special = false # API Gateway keys must be alphanumeric
}

# 1. Create the secret container in Secrets Manager
resource "aws_secretsmanager_secret" "api_key_secret" {
  name = "xml-to-json-api/api-key-v2"
  tags = var.tags
  recovery_window_in_days = 0
}

# 2. Create the first version of the secret with the random value
resource "aws_secretsmanager_secret_version" "api_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.api_key_secret.id
  secret_string = random_string.api_key_value.result
}