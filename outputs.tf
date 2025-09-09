# Main Terraform outputs for Coalfire SRE Challenge

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# Subnet Outputs
output "management_subnet_ids" {
  description = "IDs of the management subnets"
  value       = module.vpc.management_subnet_ids
}

output "application_subnet_ids" {
  description = "IDs of the application subnets"
  value       = module.vpc.application_subnet_ids
}

output "backend_subnet_ids" {
  description = "IDs of the backend subnets"
  value       = module.vpc.backend_subnet_ids
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.load_balancer.alb_zone_id
}

output "website_url" {
  description = "URL to access the website"
  value       = "http://${module.load_balancer.alb_dns_name}"
}

# Compute Outputs
output "management_instance_id" {
  description = "ID of the management instance"
  value       = module.compute.management_instance_id
}

output "management_instance_public_ip" {
  description = "Public IP of the management instance"
  value       = module.compute.management_instance_public_ip
}

output "management_instance_private_ip" {
  description = "Private IP of the management instance"
  value       = module.compute.management_instance_private_ip
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_id
}

# Security Group Outputs
output "management_security_group_id" {
  description = "ID of the management security group"
  value       = module.security.management_security_group_id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = module.security.application_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

# S3 Bucket for Logs
output "alb_logs_bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  value       = module.load_balancer.s3_bucket_name
}

# Connection Information
output "ssh_connection_command" {
  description = "Command to SSH to the management instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${module.compute.management_instance_public_ip}"
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    vpc_id                 = module.vpc.vpc_id
    website_url            = "http://${module.load_balancer.alb_dns_name}"
    management_instance_ip = module.compute.management_instance_public_ip
    autoscaling_group_id   = module.compute.autoscaling_group_id
    s3_logs_bucket         = module.load_balancer.s3_bucket_name
  }
}
