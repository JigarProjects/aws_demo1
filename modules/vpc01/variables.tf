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
  description = "The domain name for the application (required if enable_tls is true)"
  type        = string
  default     = ""
  validation {
    condition     = var.enable_tls ? length(var.domain_name) > 0 : true
    error_message = "Domain name is required when enable_tls is true"
  }
}
variable "vpc02_cidr" {
    description = "CIDR block of VPC02 for routing"
    type        = string
}
variable "vpc_peering_connection_id" {
    description = "ID of the VPC peering connection"
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

variable "frontend_image" {
  description = "ECR image URI for frontend service"
  type        = string
}

variable "backend_image" {
  description = "ECR image URI for backend service"
  type        = string
}

variable "db_initializer_image" {
  description = "Docker image for the database initializer task"
  type        = string
}

variable "setup_database" {
  description = "Flag to determine if database initialization should be run"
  type        = bool
  default     = false
}
