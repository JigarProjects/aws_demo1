# Backend Task Role
resource "aws_iam_role" "backend_task_role" {
    name = "backend-task-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
        }]
    })
}

# Policy for backend database access
resource "aws_iam_policy" "backend_db_policy" {
    name = "backend-db-policy"
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

# Attach common CloudWatch policy to backend task role
resource "aws_iam_role_policy_attachment" "backend_cloudwatch_policy_attachment" {
    role       = aws_iam_role.backend_task_role.name
    policy_arn = aws_iam_policy.ecs_cloudwatch_policy.arn
}

# Attach database policy to backend task role
resource "aws_iam_role_policy_attachment" "backend_db_policy_attachment" {
    role       = aws_iam_role.backend_task_role.name
    policy_arn = aws_iam_policy.backend_db_policy.arn
}

# Cloudwatch log
resource "aws_cloudwatch_log_group" "backend" {
    name              = "/ecs/backend"
    retention_in_days = 7
}

# ECS Cluster
resource "aws_ecs_cluster" "backend_cluster" {
    name = "backend-cluster"
    setting { 
        name = "containerInsights"
        value = "enabled"
    }
}

# Security Configuration
resource "aws_security_group" "backend" {
    name        = "backend-sg"
    description = "Security group for backend service"
    vpc_id      = aws_vpc.vpc01.id

    ingress {
        description     = "Allow traffic from backend ALB on port 3001"
        from_port       = 3001
        to_port         = 3001
        protocol        = "tcp"
        security_groups = [aws_security_group.backend_lb.id]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "backend-sg"
    }
}

resource "aws_security_group" "backend_lb" {
    name        = "backend-lb-sg"
    description = "Security group for backend ALB"
    vpc_id      = aws_vpc.vpc01.id

    ingress {
        description = "Allow HTTP traffic from frontend"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = [aws_security_group.frontend.id]
    }

    ingress {
        description = "Allow HTTPS traffic from frontend"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        security_groups = [aws_security_group.frontend.id]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "backend-lb-sg"
    }
}

# Get RDS Secret
data "aws_secretsmanager_secret_version" "rds_secret" {
    secret_id = aws_db_instance.default.master_user_secret[0].secret_arn
}

# Load Balancer Configuration
resource "aws_lb" "backend" {
    name               = "backend-alb"
    internal           = true
    load_balancer_type = "application"
    security_groups    = [aws_security_group.backend_lb.id]
    subnets            = aws_subnet.vpc01_private[*].id
    enable_deletion_protection = false

    tags = {
        Name = "backend-alb"
        Domain = var.domain_name
    }
}

# Route53 Record for Backend ALB
resource "aws_route53_record" "backend" {
    zone_id = data.aws_route53_zone.main_domain.zone_id
    name    = "backend.${var.domain_name}"
    type    = "A"

    alias {
        name                   = aws_lb.backend.dns_name
        zone_id                = aws_lb.backend.zone_id
        evaluate_target_health = true
    }
}

resource "aws_lb_target_group" "backend" {
    name        = "backend-tg"
    port        = 3001
    protocol    = "HTTP"
    vpc_id      = aws_vpc.vpc01.id
    target_type = "ip"

    health_check {
        path                = "/results"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        interval            = 30
        matcher            = "200"
    }
}

# HTTP Listener
resource "aws_lb_listener" "backend" {
    load_balancer_arn = aws_lb.backend.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.backend.arn
    }
}

# HTTPS Listener
resource "aws_lb_listener" "backend_https" {
    load_balancer_arn = aws_lb.backend.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = aws_acm_certificate.star_domain_cert.arn

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.backend.arn
    }
}

# Task Definition
resource "aws_ecs_task_definition" "backend" {
    family                   = "backend"
    network_mode            = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                     = "256"
    memory                  = "512"
    execution_role_arn      = aws_iam_role.ecs_execution_role.arn
    task_role_arn          = aws_iam_role.backend_task_role.arn
    runtime_platform {
        operating_system_family = "LINUX"
        cpu_architecture        = "ARM64"
    }

    container_definitions = jsonencode([{
        name      = "backend"
        image     = "934433567703.dkr.ecr.us-east-1.amazonaws.com/vote-api:latest"
        essential = true
        portMappings = [{
            containerPort = 3001
            protocol      = "tcp"
        }]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group"         = aws_cloudwatch_log_group.backend.name
                "awslogs-region"        = "us-east-1"
                "awslogs-stream-prefix" = "ecs"
            }
        }
        environment = [
            {
                name  = "DB_USER"
                value = aws_db_instance.default.username
            },
            {
                name  = "DB_HOST"
                value = aws_db_instance.default.address
            },
            {
                name  = "DB_PORT"
                value = tostring(aws_db_instance.default.port)
            },
            {
                name  = "DB_NAME"
                value = aws_db_instance.default.db_name
            },
            {
                name  = "DB_SECRET_NAME"
                value = aws_db_instance.default.master_user_secret[0].secret_arn
            }
        ]
    }])
}

# Service Configuration
resource "aws_ecs_service" "backend" {
    name            = "backend-service"
    cluster         = aws_ecs_cluster.backend_cluster.id
    task_definition = aws_ecs_task_definition.backend.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
        subnets          = aws_subnet.vpc01_private[*].id
        security_groups  = [aws_security_group.backend.id]
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.backend.arn
        container_name   = "backend"
        container_port   = 3001
    }

    service_registries {
        registry_arn = aws_service_discovery_service.backend.arn
    }

    depends_on = [aws_lb_listener.backend]
}

# Auto scaling
resource "aws_appautoscaling_target" "backend_scaling_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.backend_cluster.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_scaling_policy" {
  name               = "backend-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
