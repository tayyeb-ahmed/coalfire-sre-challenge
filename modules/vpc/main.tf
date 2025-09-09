# VPC setup for the challenge environment
# Creating the network foundation with 3 subnet types across 2 AZs

data "aws_availability_zones" "available" {
  state = "available"
}

# Main VPC - using the specified 10.1.0.0/16 range
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Internet gateway for public subnet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# EIP for NAT gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

# NAT Gateway - putting it in first management subnet
# This gives private subnets internet access for updates/packages
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.management[0].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-gateway"
  })
}

# Management subnets - these are public (internet accessible)
# Using 10.1.1.0/24 and 10.1.2.0/24
resource "aws_subnet" "management" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.${count.index + 1}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mgmt-subnet-${count.index + 1}"
    Type = "Management"
  })
}

# Application subnets - private, for the web servers
# Using 10.1.11.0/24 and 10.1.12.0/24 
resource "aws_subnet" "application" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.${count.index + 11}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-subnet-${count.index + 1}"
    Type = "Application"
  })
}

# Backend subnets - also private, for future database/backend services
# Using 10.1.21.0/24 and 10.1.22.0/24
resource "aws_subnet" "backend" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.${count.index + 21}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-backend-subnet-${count.index + 1}"
    Type = "Backend"
  })
}

# Route table for public subnets (management)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-routes"
  })
}

# Route table for private subnets - routes through NAT for internet access
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-routes"
  })
}

# Route Table Associations - Management (Public)
resource "aws_route_table_association" "management" {
  count = length(aws_subnet.management)

  subnet_id      = aws_subnet.management[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Application (Private)
resource "aws_route_table_association" "application" {
  count = length(aws_subnet.application)

  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.private.id
}

# Route Table Associations - Backend (Private)
resource "aws_route_table_association" "backend" {
  count = length(aws_subnet.backend)

  subnet_id      = aws_subnet.backend[count.index].id
  route_table_id = aws_route_table.private.id
}
