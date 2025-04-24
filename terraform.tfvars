# for TLS
domain_name             = "jigar.click"
# monitoring
alert_email             = "jigarOcp@gmail.com"

# app vpc
vpc01_cidr              = "10.0.0.0/16"
vpc01_private_subnets   = ["10.0.1.0/24", "10.0.10.0/24"]
vpc01_public_subnets    = ["10.0.2.0/24", "10.0.20.0/24"]
vpc01_db_subnets        = ["10.0.3.0/24","10.0.4.0/24"]
availability_zones      = ["us-east-1a", "us-east-1b"]

# ECS service scaling
frontend_max_capacity   = 4
backend_max_capacity    = 4

# Initlize DB
setup_database          = false
db_initializer_image    = "public.ecr.aws/p3u0m5r4/jigar-demo/db-intializer:v2"

# ECS images
frontend_image         = "public.ecr.aws/p3u0m5r4/jigar-demo/vote-frontend:v1"
backend_image          = "public.ecr.aws/p3u0m5r4/jigar-demo/vote-api:v1"

# client vpc
vpc02_cidr              = "11.0.0.0/16"
vpc02_public_subnets    = ["11.0.2.0/24", "11.0.20.0/24"]
