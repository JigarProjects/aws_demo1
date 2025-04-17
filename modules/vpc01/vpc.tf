resource "aws_vpc" "vpc01" {
  cidr_block = var.vpc_cidr
  
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc01"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc01-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc01-public-b"
  }
}
