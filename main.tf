module "vpc01" {
  source = "./modules/vpc01"
  vpc_cidr = var.vpc01_cidr

}
module "vpc02" {
  source = "./modules/vpc02"
  vpc_cidr = var.vpc02_cidr
}
