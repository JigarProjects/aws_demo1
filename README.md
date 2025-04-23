## Overview
This project provisions secure, scalable AWS infrastructure for a simple voting application based on NodeJS (https://github.com/JigarProjects/vote_cats_dogs) using Terraform. The infrastructure is organized into two VPCs: one for application services (frontend, backend, database) and one for simulating client access. See [infrastrucre diagram](diagrams/Networking_components.drawio.png)

## Quick Start
### Prerequisites
#### On your local machine:
- AWS CLI
- Terraform
- Docker or Podman
- Git
#### On your AWS account:
- Domain registered in Route 53
- S3 bucket and DynamoDB table for Terraform state
- IAM user for Terraform with permissions to create resources

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/JigarProjects/aws_demo1.git
   ```
2. Configure AWS credentials:
   ```bash
   aws configure
   ```
3. Modify backend.tf and initialize Terraform:
   ```bash
   cd aws_demo1
   terraform init
   ```
4. Ensure your `[terraform.tfvars](docs/IaC.md)` file is configured, then review and apply the infrastructure:
   ```bash
   terraform plan
   terraform apply

   terraform apply -var="setup_database=true" #to setup databse 
   ```

## Project Structure
```
.
├── docs/               # Project documentation
├── diagrams/           # Architecture diagrams
├── modules/            # Terraform modules (for both VPCs)
├── .gitignore          # Git ignore file
```

## Documentation
- [Architecture Design](docs/design.md): Implemented AWS architecture with VPC peering and security design
- [Infrastructure as Code](docs/IaC.md): Terraform modules, state management, and AWS provisioning
- [Security Configuration](docs/cert.md): domain creation and TLS/SSL setup
- [Monitoring](docs/monitoring.md): Alert configurations covering ECS, ALB, RDS, and certificate expiry
