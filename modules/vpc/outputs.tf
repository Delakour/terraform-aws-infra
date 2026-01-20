output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_route_table_id" {
  value = aws_route_table.private_route_table.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public_subnets : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private_subnets : s.id]
}
