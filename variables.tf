variable "region" {
  description = "The AWS region to deploy resources."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances."
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

variable "subnet_ids" {
  description = "List of subnet IDs where resources will be deployed."
  type        = list(string)
}

variable "alb_name" {
  description = "Name of the Application Load Balancer (ALB)."
  type        = string
}

variable "target_group_name" {
  description = "Name of the target group for ALB."
  type        = string
}

variable "listener_port" {
  description = "Port for the ALB listener."
  type        = number
}


variable "associate_public_ip_address" {
  type        = bool
  default     = true
  description = "Associate a public IP address with the instance."
}

variable "instances" {
  description = "Map of instances with configurations."
  type = map(object({
    name                         = string
    instance_type                = string
    associate_public_ip_address  = bool
    disable_api_termination      = bool
    disable_api_stop             = bool
    ebs_optimized                = bool
    monitoring                   = bool
    subnet_id                    = string
    user_data_raw                = string
    metadata_endpoint_enabled    = string
    metadata_options_http_tokens = string


    ebs_volume_root = object({
      iops       = number
      kms_key_id = string
      throughput = number
      size       = number
      type       = string
    })
    description = string
    ingress_rules = list(object({
      description       = string
      from_port         = number
      to_port           = number
      protocol          = string
      cidr_blocks       = list(string)
      security_group_id = optional(string, "")
      ipv6_cidr_blocks  = list(string)
      self              = bool
    }))
    egress_rules = list(object({
      description       = string
      from_port         = number
      to_port           = number
      protocol          = string
      cidr_blocks       = list(string)
      security_group_id = optional(string, "")
      ipv6_cidr_blocks  = list(string)
    }))
    tags = map(string)
  }))
}

variable "ebs_volumes" {
  description = "Map of EBS volumes to attach to instances"
  type = map(object({
    availability_zone = string
    name              = string
    size              = number
    type              = string
    iops              = number
    throughput        = number
    kms_key_id        = string
    snapshot_id       = string
    instance_key      = string
    device_name       = string
  }))
  default = {}
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
}

variable "ebs_optimized" {
  type        = bool
  description = "(optional) (Optional) If true, the launched EC2 instance will be EBS-optimized. Note that if this is not set on an instance type that is optimized by default then this will show as disabled but if the instance type is optimized by default then there is no need to set this and there is no effect to disabling it."
  default     = false
}

variable "instance_profile_data" {
  type = object({
    name             = optional(string, null)
    create           = optional(bool, false)
    policy_documents = optional(map(string), {})
  })
  description = "(optional) IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile. "
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
    http_endpoint               = optional(bool, true)
    http_protocol_ipv6          = optional(bool, false)
    http_put_response_hop_limit = optional(number, 1)
    http_tokens                 = optional(string, "required")
    instance_metadata_tags      = optional(bool, false)
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
    http_endpoint               = true
    http_protocol_ipv6          = false
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = false
  }
}

variable "root_block_device_data" {
  type = object({
    delete_on_termination = optional(bool, true)
    encrypted             = optional(bool, true)
    iops                  = optional(string, null)
    kms_key_id            = optional(string, null)
    throughput            = string
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
  (optional) ebs_block_device block supports the following:

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
  EOT
}

variable "security_group_data" {
  type = object({
    id                 = optional(string, null)
    create             = optional(bool, false)
    description        = optional(string, null)
    security_group_ids = optional(list(string), [])
    name               = optional(string, null)
    ingress_rules = optional(list(object({
      description      = optional(string, null)
      from_port        = string
      to_port          = string
      protocol         = string
      cidr_blocks      = list(string)
      security_groups  = list(string)
      ipv6_cidr_blocks = list(string)
    })))
    egress_rules = optional(list(object({
      description      = optional(string, null)
      from_port        = string
      to_port          = string
      protocol         = string
      cidr_blocks      = list(string)
      security_groups  = list(string)
      ipv6_cidr_blocks = list(string)
    })))
  })
  description = "(optional) Security Group data"
}
