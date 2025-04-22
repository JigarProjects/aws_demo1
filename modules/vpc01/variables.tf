variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type = string
}
variable "private_subnets" {
    description = "List of CIDR blocks for private subnets"
    type = list(string)
}
variable "public_subnets" {
    description = "List of CIDR blocks for public subnets"
    type = list(string)
}
variable "db_subnets" {
    description = "List of CIDR blocks for DB subnets"
    type = list(string)
    validation {
        condition = length(var.db_subnets) == 2
        error_message = "Exactly 2 DB subnets must be specified."
    }
}
variable "availability_zones" {
    description = "List of availability zones to use"
    type = list(string)
}
variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}
variable "vpc02_cidr" {
    description = "CIDR block of VPC02 for routing"
    type        = string
}
variable "vpc_peering_connection_id" {
    description = "ID of the VPC peering connection"
    type        = string
}
