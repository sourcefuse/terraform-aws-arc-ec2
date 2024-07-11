output "listener_arn" {
  description = "Listener ARN"
  value       = values(aws_lb_listener.this)[*].arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = values(aws_lb_target_group.this)[*].arn
}
