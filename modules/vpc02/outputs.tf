output "vpc_peering_connection_id" {
    value = aws_vpc_peering_connection.pc_vpc02_vpc01.id
}

output "vpc_id" {
    value = aws_vpc.vpc02.id
} 