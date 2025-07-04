# terraform/dynamodb.tf

resource "aws_dynamodb_table" "data_store" {
  # The name is based on the service_name variable for consistency
  name         = "${var.service_name}-data-store"
  
  # PAY_PER_REQUEST is ideal for serverless, unpredictable workloads.
  # You only pay for what you use.
  billing_mode = "PAY_PER_REQUEST"

  # We need a primary key (hash_key) to uniquely identify each item.
  # We'll generate a UUID for this in our Lambda function.
  hash_key     = "id"

  # Define the attributes used in the keys. 'S' stands for String.
  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}