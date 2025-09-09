# Security groups for the challenge setup
# Keeping things locked down but functional

# Management box security group
resource "aws_security_group" "management" {
  name_prefix = "${var.project_name}-mgmt-"
  vpc_id      = var.vpc_id

  # Only allow SSH from the specified IP/CIDR
  ingress {
    description = "SSH access from allowed source"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_allowed_cidr]
  }

  # Allow all outbound - needed for yum updates, etc.
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mgmt-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ALB security group - public facing
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = var.vpc_id

  # HTTP from anywhere on the internet
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS too, even though we're not using it yet
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound - will be restricted by destination SG
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Web server security group
resource "aws_security_group" "application" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = var.vpc_id

  # SSH only from management box
  ingress {
    description     = "SSH from mgmt"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.management.id]
  }

  # HTTP only from the load balancer
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # All outbound for package installs, etc
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# NACLs for extra security - probably overkill but why not
resource "aws_network_acl" "application" {
  vpc_id     = var.vpc_id
  subnet_ids = var.application_subnet_ids

  # HTTP from within VPC
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 80
    to_port    = 80
  }

  # SSH from within VPC  
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 22
    to_port    = 22
  }

  # Return traffic - ephemeral ports
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow everything outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-nacl"
  })
}


# Management subnet NACL
resource "aws_network_acl" "management" {
  vpc_id     = var.vpc_id
  subnet_ids = var.management_subnet_ids

  # SSH from our allowed IP
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.management_allowed_cidr
    from_port  = 22
    to_port    = 22
  }

  # HTTP for ALB - needed since ALB is in management subnets
  ingress {
    rule_no    = 105
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # HTTPS for ALB - needed since ALB is in management subnets
  ingress {
    rule_no    = 106
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Return traffic
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # All outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mgmt-nacl"
  })
}
