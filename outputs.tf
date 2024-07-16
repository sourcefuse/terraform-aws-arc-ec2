output "id" {
  description = "Instance ID"
  value       = aws_instance.this.id
}

output "arn" {
  description = "Instance ID"
  value       = aws_instance.this.arn
}

output "load_balancer_arn" {
  value = var.load_balancer_data.create ? module.load_balancer[0].arn : null
}

output "listener_arn" {
  description = "Listener ARN"
  value       = var.load_balancer_data.create ? module.load_balancer[0].listener_arn : null
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = var.load_balancer_data.create ? module.load_balancer[0].target_group_arn : null
}
