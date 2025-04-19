module "vpc01" {
  source          = "./modules/vpc01"
  vpc_cidr        = var.vpc01_cidr
  private_subnets = var.vpc01_private_subnets
  public_subnets  = var.vpc01_public_subnets
  db_subnets      = var.vpc01_db_subnets
  availability_zones = var.availability_zones
}
module "vpc02" {
  source          = "./modules/vpc02"
  vpc_cidr        = var.vpc02_cidr
}
