resource "aws_vpc" "vpc02" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "vpc02"
  }
}