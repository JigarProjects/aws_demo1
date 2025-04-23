variable "region" {
    description = "The AWS region to deploy to"
    type        = string
    default     = "us-east-1"
}

// Define variables for VPC 01
variable "vpc01_cidr" {
    description = "The CIDR block for VPC 01"
    type = string
}
variable "vpc01_private_subnets" {
    description = "List of CIDR blocks for VPC 01 private subnets"
    type = list(string)
}
variable "vpc01_public_subnets" {
    description = "List of CIDR blocks for VPC 01 public subnets"
    type = list(string)
}
variable "vpc01_db_subnets" {
    description = "List of CIDR blocks for VPC 01 DB subnets"
    type = list(string)
    validation {
        condition = length(var.vpc01_db_subnets) == 2
        error_message = "Exactly 2 DB subnets must be specified."
    }
}
variable "availability_zones" {
    description = "List of availability zones to use"
    type = list(string)
}

// Define variables for VPC 02
variable "vpc02_cidr" {
    description = "The CIDR block for VPC 02"
    type = string
}
variable "vpc02_public_subnets" {
    description = "List of CIDR blocks for VPC 02 public subnets"
    type = list(string)
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive alert notifications"
  type        = string
}

variable "frontend_max_capacity" {
  description = "Maximum number of frontend ECS tasks"
  type        = number
}
variable "backend_max_capacity" {
  description = "Maximum number of backend ECS tasks"
  type        = number
}

variable "db_executor_image" {
  description = "ECR image URI for database migration Lambda function"
  type        = string
}