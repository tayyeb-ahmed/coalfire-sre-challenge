# Load Balancer Module Outputs

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.application.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.application.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.application.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.application.zone_id
}

output "target_group_id" {
  description = "ID of the target group"
  value       = aws_lb_target_group.application.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.application.arn
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.application.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for ALB logs"
  value       = aws_cloudwatch_log_group.alb_logs.name
}
