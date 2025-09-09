# Security Module Outputs

output "management_security_group_id" {
  description = "ID of the management security group"
  value       = aws_security_group.management.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "application_nacl_id" {
  description = "ID of the application network ACL"
  value       = aws_network_acl.application.id
}

output "management_nacl_id" {
  description = "ID of the management network ACL"
  value       = aws_network_acl.management.id
}
