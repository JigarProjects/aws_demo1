# Frontend Task Role
resource "aws_iam_role" "frontend_task_role" {
    name = "frontend-task-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
        }]
    })
}

# Attach common CloudWatch policy to frontend task role
resource "aws_iam_role_policy_attachment" "frontend_cloudwatch_policy_attachment" {
    role       = aws_iam_role.frontend_task_role.name
    policy_arn = aws_iam_policy.ecs_cloudwatch_policy.arn
}

# Cloudwatch log
resource "aws_cloudwatch_log_group" "frontend" {
    name              = "/ecs/frontend"
    retention_in_days = 7
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
        description     = "Allow traffic from ALB on port 3000"
        from_port       = 3000
        to_port         = 3000
        protocol        = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "frontend-sg"
    }
}

# Allow HTTP and HTTPS traffic
resource "aws_security_group" "alb" {
    name        = "frontend-alb-sg"
    description = "Security group for frontend ALB"
    vpc_id      = aws_vpc.vpc01.id

    ingress {
        description = "Allow HTTP traffic from internet"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow HTTPS traffic from internet"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "frontend-alb-sg"
    }
}

# Load Balancer Configuration
resource "aws_lb" "frontend" {
    name               = "frontend-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb.id]
    subnets            = aws_subnet.vpc01_public[*].id

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


# HTTPS Listener
resource "aws_lb_listener" "frontend_https" {
    load_balancer_arn = aws_lb.frontend.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = aws_acm_certificate.star_domain_cert.arn

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
    execution_role_arn      = aws_iam_role.ecs_execution_role.arn
    task_role_arn          = aws_iam_role.frontend_task_role.arn
    runtime_platform {
        operating_system_family = "LINUX"
        cpu_architecture        = "ARM64"
    }

    container_definitions = jsonencode([{
        name      = "frontend"
        image     = var.frontend_image
        essential = true
        portMappings = [{
            containerPort = 3000
            protocol      = "tcp"
        }]
        environment = [
            {
                name  = "MIDDLEWARE_URL"
                value = "https://backend.${var.domain_name}"
            }
        ]
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
        subnets          = aws_subnet.vpc01_public[*].id
        security_groups  = [aws_security_group.frontend.id]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.frontend.arn
        container_name   = "frontend"
        container_port   = 3000
    }
    deployment_circuit_breaker {
        enable = true
        rollback = true
    }
    depends_on = [aws_lb_listener.frontend_https]
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
    name        = "vote.local"
    description = "Private DNS namespace for ECS services"
    vpc         = aws_vpc.vpc01.id
}

# Service Discovery for Backend
resource "aws_service_discovery_service" "backend" {
    name = "backend"

    dns_config {
        namespace_id = aws_service_discovery_private_dns_namespace.main.id
        
        dns_records {
            ttl  = 10
            type = "A"
        }
    }

    health_check_custom_config {
        failure_threshold = 1
    }
}

# Auto scaling
resource "aws_appautoscaling_target" "frontend_scaling_target" {
  max_capacity       = var.frontend_max_capacity
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.frontend_cluster.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_scaling_policy" {
  name               = "frontend_scaling_policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
# register ALB with Route53
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main_domain.zone_id
  name    = "demo-app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}
