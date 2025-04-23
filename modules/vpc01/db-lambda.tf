# Lambda Security Group
resource "aws_security_group" "lambda" {
  name        = "lambda-db-access"
  description = "Allow Lambda outbound MySQL access"
  vpc_id      = aws_vpc.vpc01.id

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.db.id]
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "vpc01-db-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "lambda_db_secret" {
  name = "lambda-db-secret-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        aws_db_instance.default.master_user_secret[0].secret_arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_db_secret" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_db_secret.arn
}

# Lambda Function
resource "aws_lambda_function" "db_migration" {
  filename      = "${path.module}/lambda/db-migration.zip"
  function_name = "vpc01-db-migration"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  vpc_config {
    subnet_ids         = [aws_subnet.vpc01_db_az1.id, aws_subnet.vpc01_db_az2.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      RDS_ENDPOINT = aws_db_instance.default.endpoint
      DB_USERNAME  = aws_db_instance.default.username
      DB_SECRET_ARN = aws_db_instance.default.master_user_secret[0].secret_arn
      DB_NAME      = aws_db_instance.default.db_name
    }
  }
}

# Lambda Invoker
resource "aws_lambda_invocation" "migration" {
  function_name = aws_lambda_function.db_migration.function_name
  
  input = jsonencode({
    trigger = "db_created"
  })

  depends_on = [
    aws_lambda_function.db_migration,
    aws_db_instance.default
  ]
}