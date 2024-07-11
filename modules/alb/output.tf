output "arn" {
  value = aws_lb.this.arn
}

output "listener_arn" {
  description = "Listener ARN"
  value       = module.target_groups.listener_arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = module.target_groups.target_group_arn
}
