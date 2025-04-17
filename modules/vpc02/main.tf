resource "aws_vpc" "vpc02" {
  cidr_block = "11.0.0.0/16"
  tags = {
    Name = "vpc01"
  }
}