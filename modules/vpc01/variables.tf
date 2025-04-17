variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type = string
}
variable "private_subnet" {
    description = "CIDR block for private subnet"
    type = string
}
variable "public_subnet" {
    description = "CIDR block for public subnet"
    type = string
}
variable "db_subnets" {
    description = "List of CIDR blocks for DB subnets"
    type = list(string)
    validation {
        condition = length(var.db_subnets) == 2
        error_message = "Exactly 2 DB subnets must be specified."
    }
}