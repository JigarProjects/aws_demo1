# Execution Role - for ECS container agent permissions
resource "aws_iam_role" "ecs_execution_role" {
    name = "ecs-execution-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
        }]
    })
}

# Common CloudWatch Logs Policy
resource "aws_iam_policy" "ecs_cloudwatch_policy" {
    name = "ecs-cloudwatch-policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ]
            Resource = [
                aws_cloudwatch_log_group.frontend.arn,
                "${aws_cloudwatch_log_group.frontend.arn}:log-stream:*",
                aws_cloudwatch_log_group.backend.arn,
                "${aws_cloudwatch_log_group.backend.arn}:log-stream:*"
            ]
        }]
    })
}

# Policy for execution role (ECS agent permissions)
resource "aws_iam_policy" "ecs_execution_policy" {
    name = "ecs-execution-policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ecr:GetAuthorizationToken"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage"
                ]
                Resource = [
                    data.aws_ecr_repository.vote_frontend.arn,
                    data.aws_ecr_repository.vote_api.arn
                ]
            }
        ]
    })
}

# Attach policies to execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_policy_attachment" {
    role       = aws_iam_role.ecs_execution_role.name
    policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy_ecs" {
    role       = aws_iam_role.ecs_execution_role.name
    policy_arn = aws_iam_policy.ecs_cloudwatch_policy.arn
}

# Add data sources for ECR repositories
data "aws_ecr_repository" "vote_frontend" {
    name = "vote-frontend"
}

data "aws_ecr_repository" "vote_api" {
    name = "vote-api"
}