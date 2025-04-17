module "vpc01" {
  source          = "./modules/vpc01"
  vpc_cidr        = var.vpc01_cidr
  private_subnet  = var.vpc01_private_subnet
  public_subnet   = var.vpc01_public_subnet
  db_subnets      = var.vpc01_db_subnets
}
module "vpc02" {
  source          = "./modules/vpc02"
  vpc_cidr        = var.vpc02_cidr
}
