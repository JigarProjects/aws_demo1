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

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "vpc01-nat-eip"
  }
}

resource "aws_nat_gateway" "vpc01" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.vpc01_public[0].id

  tags = {
    Name = "vpc01-nat"
  }

  depends_on = [aws_internet_gateway.vpc01]
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

# Private Route Table
resource "aws_route_table" "vpc01_private" {
  vpc_id = aws_vpc.vpc01.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc01.id
  }

  route {
    cidr_block = var.vpc02_cidr
    vpc_peering_connection_id = var.vpc_peering_connection_id
  }

  tags = {
    Name = "vpc01-private-rt"
  }
}

# -- Public Subnets
resource "aws_subnet" "vpc01_public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc01-public-${count.index + 1}"
  }
}

# -- Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "vpc01_public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.vpc01_public[count.index].id
  route_table_id = aws_route_table.vpc01_public.id
}

# -- Private Subnets
resource "aws_subnet" "vpc01_private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "vpc01-private-${count.index + 1}"
  }
}

# Associate Private Route Table with Private Subnets
resource "aws_route_table_association" "vpc01_private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.vpc01_private[count.index].id
  route_table_id = aws_route_table.vpc01_private.id
}

# New Route Table for VPC02 Peering
resource "aws_route_table" "rt_to_vpc02" {
    vpc_id = aws_vpc.vpc01.id
    route {
        cidr_block                = var.vpc02_cidr
        vpc_peering_connection_id = var.vpc_peering_connection_id
    }
    tags = {
        Name = "rt_to_vpc02"
    }
}
