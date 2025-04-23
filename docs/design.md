# Design Choices
## Technology Choices
- ECS with Fargate for simplified management
- RDS MySQL for relational database
- CloudWatch for metrics and logging
- ECR for container registry
- Terraform to provision infrastructure
- SNS for alert notifications

## Infrastructure Design

### VPC Architecture
- Multi-AZ deployment for high availability
- Internet Gateway for public-facing resources
- 2 VPCs for application and client environments
- VPC peering between application and client VPCs

#### Application VPC (VPC01)
- 3 subnets: to run application in public and private subnet, separate subnet for DB
    - resources connected to public subnet:
        - Bastion host (accessible via Session Manager)
        - Public facing Application Load Balancer (only listens to HTTPS port)
        - NAT Gateway
        - ECS Cluster for frontend application
    - resources connected to private subnet:
        - Private ECS Cluster for backend application
    - resources connected to DB subnet:
        - RDS MySQL database

#### Client VPC (VPC02)
- 1 subnets: to run client in public
    - Bastion host (accessible via Session Manager)

### Networking Design
- Internet-facing subnets for public resources
- Private subnet can access internet via NAT Gateway
- DB subnet does not have acess to the internet
- Frontend application finds the backend load balancer via DNS name
- VPC peering for cross-VPC communication

## Security Design
- Bastion host for secure access
- DB password is stored in AWS Secrets Manager and gets rotated every 7 days
- TLS certificates for secure communication
    - Both fronend and backend load balancers use TLS certificates
- Tighter Security groups for access control
    - Security groups for frontend application:
        - Load balancer and bastion host can access frontend application
    - Security groups for backend application:
        - backend application can access backend application
    - Security groups for DB access:
        - backend application and bastion host can access DB
- IAM roles for AWS resource access
    - Task role for ECS Task
    - Execution role for ECS Task
       - Access to CloudWatch logs
       - Access to ECR repository

### Design for scalability
- Auto-scaling based on CPU utilization (maximum number of tasks are defined in terraform.tfvars)
- While scaling up ECS tasks, they are spread across AZs
- DB instance with read replicas for high availability

#### Both VPCs are connected via VPC peering
- If we had more VPCs then connect them using Transit Gateway
