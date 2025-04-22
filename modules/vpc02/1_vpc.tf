# -- VPC
resource "aws_vpc" "vpc02" {
    cidr_block = var.vpc_cidr

    enable_dns_support   = true
    enable_dns_hostnames = true
    
    tags = {
        Name = "vpc02"
    }
}

# -- Internet Gateway
resource "aws_internet_gateway" "vpc02" {
    vpc_id = aws_vpc.vpc02.id

    tags = {
        Name = "vpc02-igw"
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
        Name = "vpc02-public-${count.index + 1}"
    }
}

# -- Public Route Table
resource "aws_route_table" "vpc02_public" {
    vpc_id = aws_vpc.vpc02.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.vpc02.id
    }

    route {
        cidr_block = var.vpc01_cidr
        vpc_peering_connection_id = aws_vpc_peering_connection.pc_vpc02_vpc01.id
    }

    tags = {
        Name = "vpc02-public-rt"
    }
}

# -- VPC Peering Connection
resource "aws_vpc_peering_connection" "pc_vpc02_vpc01" {
    vpc_id      = aws_vpc.vpc02.id
    peer_vpc_id = var.vpc01_id
    auto_accept = true

    tags = {
        Name = "pc_vpc02_vpc01"
    }
}

# Route Table to vpc01
resource "aws_route_table" "rt_to_vpc01" {
    vpc_id = aws_vpc.vpc02.id
    route {
        cidr_block                = var.vpc01_cidr
        vpc_peering_connection_id = aws_vpc_peering_connection.pc_vpc02_vpc01.id
    }
    tags = {
        Name = "rt_to_vpc01"
    }
}