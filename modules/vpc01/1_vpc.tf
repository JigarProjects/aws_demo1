resource "aws_vpc" "vpc01" {
  cidr_block = var.vpc_cidr
  
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc01"
  }
}

# -- Internet Gateway
resource "aws_internet_gateway" "vpc01" {
  vpc_id = aws_vpc.vpc01.id

  tags = {
    Name = "vpc01-igw"
  }
}

# -- Public Route Table
resource "aws_route_table" "vpc01_public" {
  vpc_id = aws_vpc.vpc01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc01.id
  }

  tags = {
    Name = "vpc01-public-rt"
  }
}

# -- Public Subnet
resource "aws_subnet" "vpc01_public" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.public_subnet
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc01-public"
  }
}

# -- Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "vpc01_public" {
  subnet_id      = aws_subnet.vpc01_public.id
  route_table_id = aws_route_table.vpc01_public.id
}

# -- Private Subnet
resource "aws_subnet" "vpc01_private" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.private_subnet
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "vpc01-private"
  }
}
