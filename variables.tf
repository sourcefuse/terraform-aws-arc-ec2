variable "ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
}

variable "name" {
  description = "Name of the instance"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed."
  type        = string
}

variable "private_ip" {
  type        = string
  description = "(optional) Private IP for the instance"
  default     = null
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Associate a public IP address with the instance."
}

variable "tags" {
  type        = map(string)
  description = "(optional) Tags for EC2 instance"
  default     = {}
}

variable "enable_detailed_monitoring" {
  type        = bool
  description = "(optional) Whether to enable detailed monitoring"
  default     = false
}

variable "instance_type" {
  type        = string
  description = "Instance type for EC2 instance"
}


variable "enable_termination_protection" {
  type        = bool
  description = "(optional) If true, enables EC2 Instance Termination Protection."
  default     = false
}

variable "enable_stop_protection" {
  type        = bool
  description = "(optional)  If true, enables EC2 Instance Stop Protection."
  default     = false
}

variable "ebs_optimized" {
  type        = bool
  description = "(optional) (Optional) If true, the launched EC2 instance will be EBS-optimized. Note that if this is not set on an instance type that is optimized by default then this will show as disabled but if the instance type is optimized by default then there is no need to set this and there is no effect to disabling it."
  default     = false
}

variable "instance_profile_data" {
  type = object({
    name   = optional(string, null)
    create = optional(bool, false)
    policy_documents = optional(list(object({
      name   = string
      policy = string
    })), [])
    managed_policy_arns = optional(list(string), [])
  })
  description = "(optional) IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile. "
  default = {
    name                = null
    create              = false
    policy_documents    = []
    managed_policy_arns = []
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID on which EC2 instance has to be created"
}

variable "user_data" {
  type        = string
  description = "(optional) User data to provide when launching the instance. Do not pass gzip-compressed data via this argument; see user_data_base64 instead. Updates to this field will trigger a stop/start of the EC2 instance by default. "
  default     = null
}

variable "instance_metadata_options" {
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_protocol_ipv6          = optional(string, "disabled")
    http_put_response_hop_limit = optional(number, 1)
    http_tokens                 = optional(string, "required")
    instance_metadata_tags      = optional(string, "disabled")
  })
  description = <<-EOT
  The metadata_options block supports the following:

  http_endpoint - (Optional) Whether the metadata service is available. Valid values include enabled or disabled. Defaults to enabled.
  http_protocol_ipv6 - (Optional) Whether the IPv6 endpoint for the instance metadata service is enabled. Defaults to disabled.
  http_put_response_hop_limit - (Optional) Desired HTTP PUT response hop limit for instance metadata requests. The larger the number, the further instance metadata requests can travel. Valid values are integer from 1 to 64. Defaults to 1.
  http_tokens - (Optional) Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Valid values include optional or required. Defaults to optional.
  instance_metadata_tags - (Optional) Enables or disables access to instance tags from the instance metadata service. Valid values include enabled or disabled. Defaults to disabled.
  EOT
  default = {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
}

variable "root_block_device_data" {
  type = object({
    delete_on_termination = optional(bool, true)
    encrypted             = optional(bool, true)
    iops                  = optional(string, null)
    kms_key_id            = optional(string, null)
    throughput            = optional(number, null)
    volume_size           = string
    volume_type           = string
  })
  description = <<-EOT
  The root_block_device block supports the following:

  delete_on_termination - (Optional) Whether the volume should be destroyed on instance termination. Defaults to true.
  encrypted - (Optional) Whether to enable volume encryption. Defaults to false. Must be configured to perform drift detection.
  iops - (Optional) Amount of provisioned IOPS. Only valid for volume_type of io1, io2 or gp3.
  kms_key_id - (Optional) Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume. Must be configured to perform drift detection.
  tags - (Optional) Map of tags to assign to the device.
  throughput - (Optional) Throughput to provision for a volume in mebibytes per second (MiB/s). This is only valid for volume_type of gp3.
  volume_size - (Optional) Size of the volume in gibibytes (GiB).
  volume_type - (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to the volume type that the AMI uses.
  EOT

}

variable "additional_ebs_volumes" {
  type = map(object({
    name                  = optional(string, null)
    delete_on_termination = optional(bool, true)
    device_name           = string
    encrypted             = optional(bool, false)
    iops                  = optional(string, null)
    kms_key_id            = optional(string, null)
    throughput            = optional(string, null)
    volume_size           = number
    volume_type           = optional(string, "gp2")

  }))
  description = <<-EOT
  (optional) `ebs_block_device` block supports the following:
    name - (Optional) Name of the volume
    delete_on_termination - (Optional) Whether the volume should be destroyed on instance termination. Defaults to true.
    device_name - (Required) Name of the device to mount.
    encrypted - (Optional) Enables EBS encryption on the volume. Defaults to false. Cannot be used with snapshot_id. Must be configured to perform drift detection.
    iops - (Optional) Amount of provisioned IOPS. Only valid for volume_type of io1, io2 or gp3.
    kms_key_id - (Optional) Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume. Must be configured to perform drift detection.
    snapshot_id - (Optional) Snapshot ID to mount.
    tags - (Optional) Map of tags to assign to the device.
    throughput - (Optional) Throughput to provision for a volume in mebibytes per second (MiB/s). This is only valid for volume_type of gp3.
    volume_size - (Optional) Size of the volume in gibibytes (GiB).
    volume_type - (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp2.

    Device name : https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
  EOT
  default     = {}
}

variable "security_group_data" {
  type = object({
    create             = optional(bool, false)
    name               = optional(string, null)
    description        = optional(string, null)
    security_group_ids = optional(list(string))
    ingress_rules = optional(list(object({
      description      = optional(string, null)
      from_port        = string
      to_port          = string
      protocol         = string
      cidr_blocks      = list(string)
      security_groups  = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
    })))
    egress_rules = optional(list(object({
      description      = optional(string, null)
      from_port        = string
      to_port          = string
      protocol         = string
      cidr_blocks      = list(string)
      security_groups  = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
    })))
  })
  description = "(optional) Security Group data"
}

variable "ssh_key_pair" {
  type        = string
  description = "(optional) SSH Key Pair for EC2 instance"
  default     = null
}

variable "assign_eip" {
  type        = bool
  description = "(optional) Whether to assign Elastic IP address, note `associate_public_ip_address` has to be enabled"
  default     = false
}
