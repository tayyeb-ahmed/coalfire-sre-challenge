# Terraform variables for Coalfire SRE Challenge deployment

aws_region   = "us-east-1"
project_name = "coalfire-sre-challenge"
environment  = "dev"

# Your public IP address for SSH access to management box
management_allowed_cidr = "151.202.45.111/32"

# Your existing AWS key pair
key_pair_name = "coalfire-challenge-key"

# ASG configuration as per requirements
availability_zones   = ["us-east-1a", "us-east-1b"]
asg_min_size         = 2
asg_max_size         = 6
asg_desired_capacity = 2

common_tags = {
  Project     = "coalfire-sre-challenge"
  Environment = "dev"
  Owner       = "sre-team"
  ManagedBy   = "terraform"
  Purpose     = "technical-challenge"
}
