# terraform/iam.tf
#
# Contains all IAM resources required for the Lambda function.

# Lambda execution role: Allows the Lambda service to assume this role and execute the function.
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.service_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
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

# IAM policy for CloudWatch Logs: Grants permission for the Lambda to write logs.
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
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.service_name}-*"
      },
    ]
  })
}

# Attach the log policy to the Lambda execution role.
resource "aws_iam_role_policy_attachment" "lambda_log_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_log_policy.arn
}

# --- DynamoDB Permissions ---

# IAM policy that allows writing to our new DynamoDB table.
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${var.service_name}-dynamodb-policy"
  description = "IAM policy for Lambda to write to the DynamoDB data store"

  # The policy document grants the PutItem action on our specific table.
  # This follows the principle of least privilege.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "dynamodb:PutItem"
        Resource = aws_dynamodb_table.data_store.arn
      },
    ]
  })
}

# Attach the new DynamoDB policy to our Lambda execution role.
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}