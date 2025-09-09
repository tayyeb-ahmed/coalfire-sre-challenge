# Security Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "management_allowed_cidr" {
  description = "CIDR block allowed to SSH to management instance"
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

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
