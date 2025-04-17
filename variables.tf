variable "region" {
    description = "The AWS region to deploy to"
    type        = string
    default     = "us-east-1"
}

variable "vpc01_cidr" {
    description = "The CIDR block for VPC 01"
    type = string
}
variable "vpc02_cidr" {
    description = "The CIDR block for VPC 01"
    type = string
}