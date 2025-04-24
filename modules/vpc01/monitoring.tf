# Data block to fetch certificate ARN
data "aws_acm_certificate" "domain" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "infrastructure-alerts"
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alerts_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 1 ECS
# Frontend Service - Scaling Blocked Alert
resource "aws_cloudwatch_metric_alarm" "frontend_scaling_blocked" {
  alarm_name          = "front-ECS-Scaling-Blocked"
  alarm_description   = "Alarm when frontend ECS is at max capacity and CPU is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  threshold          = "1"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  metric_query {
    id = "cpu_utilization"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.frontend_cluster.name
        ServiceName = aws_ecs_service.frontend.name
      }
    }
  }

  metric_query {
    id = "desired_tasks"
    metric {
      metric_name = "DesiredTaskCount"
      namespace   = "AWS/ECS"
      period      = "300"
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.frontend_cluster.name
        ServiceName = aws_ecs_service.frontend.name
      }
    }
  }

  metric_query {
    id          = "scaling_blocked"
    expression  = "IF(cpu_utilization > 80 AND desired_tasks == ${var.frontend_max_capacity}, 1, 0)"
    label       = "Scaling Blocked"
    return_data = "true"
  }
}

# Backend - Scaling Blocked Alert
resource "aws_cloudwatch_metric_alarm" "backend_scaling_blocked" {
  alarm_name          = "back-ECS-Scaling-Blocked"
  alarm_description   = "Alarm when backend ECS is at max capacity and CPU is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  threshold          = "1"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  metric_query {
    id = "cpu_utilization"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = 300
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.backend_cluster.name
        ServiceName = aws_ecs_service.backend.name
      }
    }
  }

  metric_query {
    id = "desired_tasks"
    metric {
      metric_name = "DesiredTaskCount"
      namespace   = "AWS/ECS"
      period      = "300"
      stat        = "Average"
      dimensions = {
        ClusterName = aws_ecs_cluster.backend_cluster.name
        ServiceName = aws_ecs_service.backend.name
      }
    }
  }

  metric_query {
    id          = "scaling_blocked"
    expression  = "IF(cpu_utilization > 80 AND desired_tasks == ${var.backend_max_capacity}, 1, 0)"
    label       = "Scaling Blocked"
    return_data = "true"
  }
}

##2 Load Balancer Health Alert
resource "aws_cloudwatch_metric_alarm" "front-load_balancer_health" {
  alarm_name          = "front-LoadBalancerHealth"
  alarm_description  = "Alert when load balancer has no healthy hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Minimum"
  threshold          = "1"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    LoadBalancer = aws_lb.frontend.arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }
}
resource "aws_cloudwatch_metric_alarm" "back-load_balancer_health" {
  alarm_name          = "back-LoadBalancerHealth"
  alarm_description  = "Alert when load balancer has no healthy hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Minimum"
  threshold          = "1"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    LoadBalancer = aws_lb.backend.arn_suffix
    TargetGroup  = aws_lb_target_group.backend.arn_suffix
  }
}


##3 Database Alerts
# CPU Utilization Alert
resource "aws_cloudwatch_metric_alarm" "db_cpu_utilization" {
  alarm_name          = "DB-CPU-Utilization"
  alarm_description   = "Alert when database CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period             = "300"    # 5 minutes
  statistic          = "Average"
  threshold          = "80"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.identifier
  }
}

# Storage Space exceeds 1GB
resource "aws_cloudwatch_metric_alarm" "db_free_storage_space" {
  alarm_name          = "DB-Free-Storage-Space"
  alarm_description   = "Alert when database free storage space is low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "1000000000"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.identifier
  }
}

# Database Connections Alert - if more than 100 connections
resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "DB-Connections"
  alarm_description   = "Alert when database connection count is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "100"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.default.identifier
  }
}

##4 ECS Task Failure Monitoring - 3 or more frontend tasks fail in 15 min


##5 EC2 Infrastructure Monitoring
# Bastion Host CPU Utilization over 80%
resource "aws_cloudwatch_metric_alarm" "bastion_cpu" {
  alarm_name          = "Bastion-CPU-Utilization"
  alarm_description   = "Alert when bastion host CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    InstanceId = aws_instance.bastion.id
  }
}

# Bastion Host Status Check
resource "aws_cloudwatch_metric_alarm" "bastion_status" {
  alarm_name          = "Bastion-Status-Check"
  alarm_description   = "Alert when bastion host fails status check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Maximum"
  threshold          = "0"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    InstanceId = aws_instance.bastion.id
  }
} 


##6 Certificate - Alert when cert will expire in a month
resource "aws_cloudwatch_metric_alarm" "certificate_expiry" {
  alarm_name          = "CertificateExpiryAlert"
  alarm_description  = "Alert when SSL certificate is about to expire (less than 30 days)"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period             = "86400"
  statistic          = "Minimum"
  threshold          = "30"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  dimensions = {
    CertificateArn = data.aws_acm_certificate.domain.arn
  }
}

