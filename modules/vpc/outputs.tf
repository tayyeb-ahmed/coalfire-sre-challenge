# VPC Module Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "management_subnet_ids" {
  description = "IDs of the management subnets"
  value       = aws_subnet.management[*].id
}

output "application_subnet_ids" {
  description = "IDs of the application subnets"
  value       = aws_subnet.application[*].id
}

output "backend_subnet_ids" {
  description = "IDs of the backend subnets"
  value       = aws_subnet.backend[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}
