resource "aws_iam_role" "lambda" {
  name = "vpc01-lambda-role"
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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "lambda" {
  name        = "lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.vpc01.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Lambda Function
resource "aws_lambda_function" "db_migration" {
  function_name = "vpc01-db-migration"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = var.db_executor_image
  timeout       = 30

  vpc_config {
    subnet_ids         = [aws_subnet.vpc01_db_az1.id, aws_subnet.vpc01_db_az2.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      RDS_ENDPOINT    = aws_db_instance.default.endpoint
      DB_SECRET_ARN   = aws_db_instance.default.master_user_secret[0].secret_arn
      DB_NAME         = aws_db_instance.default.db_name
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