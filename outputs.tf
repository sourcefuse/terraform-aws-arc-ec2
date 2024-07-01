# outputs.tf in the ec2_instances module directory
output "instance_ids" {
  value = { for instance_name, instance in aws_instance.this : instance_name => instance.id }
}