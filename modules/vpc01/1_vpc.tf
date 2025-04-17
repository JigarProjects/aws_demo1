resource "aws_vpc" "vpc01" {
  cidr_block = var.vpc_cidr
  
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc01"
  }
}

resource "aws_subnet" "vpc01_public" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.private_subnet
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc01-public"
  }
}

resource "aws_subnet" "vpc01_private" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.public_subnet
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc01-private"
  }
}
