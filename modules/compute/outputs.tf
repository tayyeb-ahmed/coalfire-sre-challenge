# Outputs from the compute module

output "autoscaling_group_id" {
  description = "ASG ID"
  value       = aws_autoscaling_group.web_servers.id
}

output "autoscaling_group_arn" {
  description = "ASG ARN"
  value       = aws_autoscaling_group.web_servers.arn
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.web_servers.id
}

output "management_instance_id" {
  description = "Management box instance ID"
  value       = aws_instance.mgmt_box.id
}

output "management_instance_private_ip" {
  description = "Management box private IP"
  value       = aws_instance.mgmt_box.private_ip
}

output "management_instance_public_ip" {
  description = "Management box public IP"
  value       = aws_instance.mgmt_box.public_ip
}

output "iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "scale_up_policy_arn" {
  description = "Scale up policy ARN"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "Scale down policy ARN"
  value       = aws_autoscaling_policy.scale_down.arn
}
