output "id" {
  description = "Instance ID"
  value       = aws_instance.this.id
}

output "arn" {
  description = "Instance ID"
  value       = aws_instance.this.arn
}

output "load_balancer_arn" {
  value = module.load_balancer[0].arn
}

output "listener_arn" {
  description = "Listener ARN"
  value       = module.load_balancer[0].listener_arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = module.load_balancer[0].target_group_arn
}
