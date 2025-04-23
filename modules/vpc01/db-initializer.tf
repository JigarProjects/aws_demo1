# DB Initializer Task Definition
resource "aws_ecs_task_definition" "db_initializer" {
  count = var.setup_database ? 1 : 0

  family                   = "db-initializer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.backend_task_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = "db-initializer"
    image     = var.db_initializer_image
    essential = true
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
      },
      {
        name  = "INIT_DB"
        value = "true"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# Run DB Initializer Task
resource "null_resource" "setup_db_task" {
  count = var.setup_database ? 1 : 0

  triggers = {
    rds_endpoint = aws_db_instance.default.endpoint
    task_definition = aws_ecs_task_definition.db_initializer[0].revision
    force_run = var.setup_database ? timestamp() : ""
  }

  provisioner "local-exec" {
    command = <<EOT
      aws ecs run-task \
        --cluster ${aws_ecs_cluster.backend_cluster.name} \
        --task-definition ${aws_ecs_task_definition.db_initializer[0].family}:${aws_ecs_task_definition.db_initializer[0].revision} \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${join(",", aws_subnet.vpc01_private[*].id)}],securityGroups=[${aws_security_group.backend.id}],assignPublicIp=DISABLED}" \
        --count 1
    EOT
  }

  depends_on = [
    aws_db_instance.default,
    aws_ecs_cluster.backend_cluster,
    aws_ecs_task_definition.db_initializer[0]
  ]
}
