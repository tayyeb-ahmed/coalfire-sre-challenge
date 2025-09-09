# Variables for the Coalfire challenge setup

variable "aws_region" {
  description = "Which AWS region to deploy everything"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging stuff"
  type        = string
  default     = "coalfire-sre-challenge"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR - using 10.1.0.0/16 as specified"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "management_allowed_cidr" {
  description = "IP/CIDR that can SSH to the management box"
  type        = string
  # TODO: Update this with actual IP in terraform.tfvars
  default = "0.0.0.0/32"
}

variable "key_pair_name" {
  description = "AWS key pair for EC2 access"
  type        = string
  # Make sure to set this in terraform.tfvars
  default = ""
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t2.micro" # keeping it cheap for demo
}

variable "asg_min_size" {
  description = "Min instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Max instances in ASG"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "How many instances we want running normally"
  type        = number
  default     = 2
}


# Tags that get applied to everything
variable "common_tags" {
  type = map(string)
  default = {
    Project     = "coalfire-sre-challenge"
    Environment = "dev"
    Owner       = "sre-team"
    ManagedBy   = "terraform"
    Purpose     = "technical-challenge"
  }
}
