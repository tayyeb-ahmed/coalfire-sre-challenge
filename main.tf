# Coalfire SRE Challenge - Main Infrastructure
# Putting together all the pieces for this demo environment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Network foundation - VPC, subnets, routing
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  project_name       = var.project_name
  common_tags        = var.common_tags
}

# Security groups and NACLs
module "security" {
  source = "./modules/security"

  vpc_id                  = module.vpc.vpc_id
  vpc_cidr_block          = module.vpc.vpc_cidr_block
  management_allowed_cidr = var.management_allowed_cidr
  application_subnet_ids  = module.vpc.application_subnet_ids
  management_subnet_ids   = module.vpc.management_subnet_ids
  project_name            = var.project_name
  common_tags             = var.common_tags
}


# ALB for web traffic distribution
module "load_balancer" {
  source = "./modules/load-balancer"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  management_subnet_ids = module.vpc.management_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  common_tags           = var.common_tags
}

# EC2 instances - both ASG and management box
module "compute" {
  source = "./modules/compute"

  project_name                  = var.project_name
  instance_type                 = var.instance_type
  key_pair_name                 = var.key_pair_name
  application_subnet_ids        = module.vpc.application_subnet_ids
  management_subnet_ids         = module.vpc.management_subnet_ids
  application_security_group_id = module.security.application_security_group_id
  management_security_group_id  = module.security.management_security_group_id
  target_group_arn              = module.load_balancer.target_group_arn
  asg_min_size                  = var.asg_min_size
  asg_max_size                  = var.asg_max_size
  asg_desired_capacity          = var.asg_desired_capacity
  common_tags                   = var.common_tags
}
