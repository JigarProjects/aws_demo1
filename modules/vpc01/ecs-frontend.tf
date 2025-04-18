# IAM Configuration
resource "aws_iam_policy" "ecs_task_policy" {
    name = "ecs-task-policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:GetRepositoryPolicy",
                    "ecr:DescribeRepositories",
                    "ecr:ListImages",
                    "ecr:DescribeImages",
                    "ecr:BatchGetImage",
                    "ecr:GetLifecyclePolicy",
                    "ecr:GetLifecyclePolicyPreview",
                    "ecr:ListTagsForResource",
                    "ecr:DescribeImageScanFindings"
                ]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:CreateLogGroup"
                ]
                Resource = "${aws_cloudwatch_log_group.frontend.arn}:*"
            }
        ]
    })
}

resource "aws_iam_role" "ecs_task_role" {
    name = "ecs-task-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
    role       = aws_iam_role.ecs_task_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
    role       = aws_iam_role.ecs_task_role.name
    policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# Cloudwatch log
resource "aws_cloudwatch_log_group" "frontend" {
    name              = "/ecs/frontend"
    retention_in_days = 30
}

# ECS Cluster
resource "aws_ecs_cluster" "frontend_cluster" {
    name = "frontend-cluster"
    setting { 
        name = "containerInsights"
        value = "enabled"
    }
}

# Security Configuration
resource "aws_security_group" "frontend" {
    name        = "frontend-sg"
    description = "Security group for frontend service"
    vpc_id      = aws_vpc.vpc01.id

    ingress {
        from_port       = 3000
        to_port         = 3000
        protocol        = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "alb" {
    name        = "frontend-alb-sg"
    description = "Security group for frontend ALB"
    vpc_id      = aws_vpc.vpc01.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Load Balancer Configuration
resource "aws_lb" "frontend" {
    name               = "frontend-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb.id]
    subnets            = [aws_subnet.vpc01_public.id, "subnet-04fcdbc400d1cac44"]

    enable_deletion_protection = false
}

resource "aws_lb_target_group" "frontend" {
    name        = "frontend-tg"
    port        = 3000
    protocol    = "HTTP"
    vpc_id      = aws_vpc.vpc01.id
    target_type = "ip"

    health_check {
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        interval            = 30
        matcher            = "200"
    }
}

resource "aws_lb_listener" "frontend" {
    load_balancer_arn = aws_lb.frontend.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.frontend.arn
    }
}

# Task Definition
resource "aws_ecs_task_definition" "frontend" {
    family                   = "frontend"
    network_mode            = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                     = "256"
    memory                  = "512"
    execution_role_arn      = aws_iam_role.ecs_task_role.arn
    task_role_arn          = aws_iam_role.ecs_task_role.arn
    runtime_platform {
        operating_system_family = "LINUX"
        cpu_architecture        = "ARM64"
    }

    container_definitions = jsonencode([{
        name      = "frontend"
        image     = "934433567703.dkr.ecr.us-east-1.amazonaws.com/vote-frontend:latest"
        essential = true
        portMappings = [{
            containerPort = 3000
            protocol      = "tcp"
        }]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
                "awslogs-region"        = "us-east-1"
                "awslogs-stream-prefix" = "ecs"
            }
        }
    }])
}

# Service Configuration
resource "aws_ecs_service" "frontend" {
    name            = "frontend-service"
    cluster         = aws_ecs_cluster.frontend_cluster.id
    task_definition = aws_ecs_task_definition.frontend.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
        subnets          = [aws_subnet.vpc01_public.id, "subnet-04fcdbc400d1cac44"]
        security_groups  = [aws_security_group.frontend.id]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.frontend.arn
        container_name   = "frontend"
        container_port   = 3000
    }

    depends_on = [aws_lb_listener.frontend]
}
