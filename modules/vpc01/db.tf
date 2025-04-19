# -- Subnet for DB
resource "aws_subnet" "vpc01_db_az1" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.db_subnets[0]
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "vpc01-db-az1"
  }
}

resource "aws_subnet" "vpc01_db_az2" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.db_subnets[1]
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "vpc01-db-az2"
  }
}

# -- Subnetgroup for DB
resource "aws_db_subnet_group" "default" {
    name       = "vpc01-db-subnet-group"
    subnet_ids = [aws_subnet.vpc01_db_az1.id, aws_subnet.vpc01_db_az2.id]
    tags = {
        Name = "vpc01-db-subnet-group"
    }
}

# -- Security Group for DB
resource "aws_security_group" "db" {
    name        = "db"
    description = "Allow access to DB"
    vpc_id      = aws_vpc.vpc01.id

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = var.private_subnets
        description = "Allow MySQL from private subnets"
    }
    
    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.bastion.id]
        description = "Allow MySQL from bastion host"
    }

    tags = {
        Name = "db"
    }
}

# --- RDS Instance - password managed by Secrets Manager default KMS key
resource "aws_db_instance" "default" {
    allocated_storage   = 10
    engine              = "mysql"
    engine_version      = "8.0"
    
    identifier          = "votedb"
    db_name             = "votedb"
    instance_class      = "db.t3.micro"
    username            = "admin"
    manage_master_user_password = true

    vpc_security_group_ids = [aws_security_group.db.id]
    db_subnet_group_name = aws_db_subnet_group.default.name
    
    skip_final_snapshot = true
    multi_az            = true
}

# -- Output the RDS endpoint for reference
output "rds_endpoint" {
    value = aws_db_instance.default.endpoint
}
