module "vpc01" {
  source          = "./modules/vpc01"
  vpc_cidr        = var.vpc01_cidr
  private_subnets = var.vpc01_private_subnets
  public_subnets  = var.vpc01_public_subnets
  db_subnets      = var.vpc01_db_subnets
  availability_zones = var.availability_zones
  // Peering connection
  vpc02_cidr      = var.vpc02_cidr
  vpc_peering_connection_id = module.vpc02.vpc_peering_connection_id

  domain_name     = var.domain_name
  alert_email     = var.alert_email
  enable_tls      = var.enable_tls

  frontend_max_capacity = var.frontend_max_capacity
  backend_max_capacity = var.backend_max_capacity
  frontend_image       = var.frontend_image
  backend_image        = var.backend_image
  
  db_initializer_image = var.db_initializer_image
  setup_database   = var.setup_database
}

module "vpc02" {
  source          = "./modules/vpc02"
  vpc_cidr        = var.vpc02_cidr
  public_subnets  = var.vpc02_public_subnets
  availability_zones = var.availability_zones
  // Peering connection
  vpc01_cidr      = var.vpc01_cidr
  vpc01_id        = module.vpc01.vpc_id
}
