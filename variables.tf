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
variable "vpc01_private_subnet" {
    description = "The CIDR block for VPC 01 private subnet"
    type = string
}
variable "vpc01_public_subnet" {
    description = "The CIDR block for VPC 01 public subnet"
    type = string
}
variable "vpc01_db_subnets" {
    description = "List of CIDR blocks for VPC 01 DB subnets"
    type = list(string)
    validation {
        condition = length(var.vpc01_db_subnets) == 2
        error_message = "Exactly 2 DB subnets must be specified."
    }
}

// Define variables for VPC 02
variable "vpc02_cidr" {
    description = "The CIDR block for VPC 02"
    type = string
}