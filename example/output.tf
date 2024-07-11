output "instance_id" {
  description = "Instance ID"
  value       = module.ec2_instances.id
}

output "instance_arn" {
  description = "Instance ARN"
  value       = module.ec2_instances.arn
}

output "load_balancer_arn" {
  value = module.ec2_instances.load_balancer_arn
}

output "listener_arn" {
  description = "Listener ARN"
  value       = module.ec2_instances.listener_arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = module.ec2_instances.target_group_arn
}
