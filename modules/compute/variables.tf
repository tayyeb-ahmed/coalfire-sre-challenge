# Compute Module Variables

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
}

variable "application_subnet_ids" {
  description = "IDs of the application subnets"
  type        = list(string)
}

variable "management_subnet_ids" {
  description = "IDs of the management subnets"
  type        = list(string)
}

variable "application_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

variable "management_security_group_id" {
  description = "ID of the management security group"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group for the load balancer"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
