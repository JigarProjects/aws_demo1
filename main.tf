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
