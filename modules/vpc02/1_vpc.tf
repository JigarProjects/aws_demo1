resource "aws_vpc" "vpc02" {
  cidr_block = var.vpc_cidr

  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "vpc02"
  }
}

# -- Public Subnets
resource "aws_subnet" "vpc02_public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc02.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc01-public-${count.index + 1}"
  }
}
