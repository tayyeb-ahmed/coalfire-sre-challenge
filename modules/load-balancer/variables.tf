# Load Balancer Module Variables

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "management_subnet_ids" {
  description = "IDs of the management subnets (public subnets for ALB)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Optional variable for SSL certificate (commented out for basic implementation)
# variable "ssl_certificate_arn" {
#   description = "ARN of the SSL certificate for HTTPS listener"
#   type        = string
#   default     = ""
# }
