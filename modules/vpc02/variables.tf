variable "vpc_cidr" {
    description = "The CIDR block for VPC 02"
    type = string
}
variable "public_subnets" {
    description = "List of CIDR blocks for public subnets"
    type = list(string)
}
variable "availability_zones" {
    description = "List of availability zones to use"
    type = list(string)
}