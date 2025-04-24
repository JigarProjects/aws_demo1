# Monitoring and Alerting

## Overview
This project uses AWS CloudWatch for monitoring infrastructure and application health with the following specific alerts configured through Terraform:

## Active Alert Configurations

### ECS Alerts
- **Scaling Blocked**: Alerts when services reach max capacity + high CPU (>80% utilization)

### Load Balancer Alerts
- **Healthy Hosts**: Triggers if no healthy hosts detected for 10 minutes

### Database Alerts (RDS)
- **CPU Utilization**: Threshold at 80% (5-minute average)
- **Storage Space**: Alerts when free space drops below 1GB
- **Connections**: Warns when exceeding 100 concurrent connections

### Bastion Host Monitoring
- **Bastion Host**: CPU >80% utilization or failed status checks

### Certificate & Security Alerts
- **Certificate Expiry**: Triggers 30 days before SSL certificate expiration

### Budget
- **Budget**: Alerts when budget goes over $80

## Alert Channels
All alerts are routed through SNS Topic `infrastructure-alerts` to:
- Email: ${var.alert_email}


## Additional alerts that can be added:
- Alerts for HTTP 5XX errors
- Memory alerts on EC2
- Response time from LB
- Read replica lag alert for DB
