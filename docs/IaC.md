# Infrastructure as Code (IaC) Documentation
We use terraform to provision resources on AWS. Minimal configuration is provided in the `terraform.tfvars` file.

## State Management
Terraform state file is stored in S3 bucket and DynamoDB table to lock the state file
HCP Terraform Cloud can optionally be used to manage the state file

Secure S3 bucket by blocking all public access and enable versioning

## Project Structure

| Directory      | Purpose                | Contents                        |
|---------------|------------------------|----------------------------------|
| main.tf         | Main configuration     | VPC modules and connections     |
| variables.tf    | Variable definitions   | Input parameters                |
| terraform.tfvars| Variable values        | Actual configuration values     |
| backend.tf      | State config           | S3 backend configuration        |
| providers.tf    | Provider config        | AWS provider setup              |
| modules/          | Terraform modules      | vpc01, vpc02, prerequisite      |


## Terraform Input Variables (`terraform.tfvars`)
This file defines the specific settings for your deployment. Common variables include:

**General Settings:**
- `domain_name`: The domain name registered in Route 53 for your application
- `alert_email`: The email address for receiving monitoring alerts
- `availability_zones`: The AWS Availability Zones to deploy resources into

**VPC01 (Application VPC) Settings:**
- `vpc01_cidr`: The CIDR block for the main application VPC
- `vpc01_private_subnets`: A list of private subnet CIDR blocks
- `vpc01_public_subnets`: A list of public subnet CIDR blocks
- `vpc01_db_subnets`: A list of database subnet CIDR blocks

**ECS Settings:**
- `frontend_max_capacity`: Maximum number of frontend ECS tasks
- `backend_max_capacity`: Maximum number of backend ECS tasks

**VPC02 (Client Simulation VPC) Settings:**
- `vpc02_cidr`: The CIDR block for the client simulation VPC
- `vpc02_public_subnets`: A list of public subnet CIDR blocks

# Improvements
Integrate Terratest.io for testing
Environemnt specific configuration can be added