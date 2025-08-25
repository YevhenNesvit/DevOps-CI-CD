output "vpc_id" {
  description = "ID VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR блок VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs публічних підмереж"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs приватних підмереж"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "public_route_table_id" {
  description = "ID публічної Route Table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID приватної Route Table"
  value       = aws_route_table.private.id
}