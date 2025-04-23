# Monitoring and Alerting

## Overview
This project uses AWS CloudWatch for monitoring infrastructure and application health with the following specific alerts configured through Terraform:

## Active Alert Configurations

### ECS Alerts
- **CPU Throttling**: Triggers when CPU utilization exceeds 90% for ECS tasks (5-minute average over 2 periods)
- **Scaling Blocked**: Alerts when services reach max capacity + high CPU (>80% utilization)
- **Task Failures**: Notifies after 3+ task failures within 15 minutes for both frontend and backend services

### Load Balancer Alerts
- **Healthy Hosts**: Triggers if no healthy hosts detected for 10 minutes
- **5XX Errors**: Alerts when HTTP 5XX errors exceed 10 in 5 minutes
- **Response Time**: Warns when average response time exceeds 2 seconds

### Database Alerts (RDS)
- **CPU Utilization**: Threshold at 80% (5-minute average)
- **Storage Space**: Alerts when free space drops below 1GB
- **Connections**: Warns when exceeding 100 concurrent connections

### Bastion Host Monitoring
- **Bastion Host**: CPU >80% utilization or failed status checks

### Certificate & Security Alerts
- **Certificate Expiry**: Triggers 30 days before SSL certificate expiration

## Alert Channels
All alerts are routed through SNS Topic `infrastructure-alerts` to:
- Email: ${var.alert_email}
