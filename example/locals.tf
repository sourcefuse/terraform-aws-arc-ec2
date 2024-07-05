locals {

  instances = {
    instance1 = {
      name                         = "example-instance-1"
      instance_type                = "t3.micro"
      associate_public_ip_address  = true
      disable_api_termination      = false
      disable_api_stop             = false
      ebs_optimized                = false
      monitoring                   = false
      subnet_id                    = data.aws_subnets.public.ids[0]
      user_data_raw                = "echo hello"
      metadata_endpoint_enabled    = "enabled"
      metadata_options_http_tokens = "required"

      ebs_volume_root = {
        iops       = 3000
        kms_key_id = null
        throughput = 125
        size       = 30
        type       = "gp3"
      }

      description   = "Security group for example-instance-1"
      ingress_rules = local.ingress_rules
      egress_rules  = local.egress_rules
      tags          = {}
    },

    instance2 = {
      name                         = "example-instance-2"
      instance_type                = "t3.micro"
      associate_public_ip_address  = true
      disable_api_termination      = false
      disable_api_stop             = false
      ebs_optimized                = false
      monitoring                   = false
      subnet_id                    = data.aws_subnets.public.ids[1]
      user_data_raw                = "echo hello"
      metadata_endpoint_enabled    = "enabled"
      metadata_options_http_tokens = "required"

      ebs_volume_root = {
        iops       = 3000
        kms_key_id = null
        throughput = 125
        size       = 30
        type       = "gp3"
      }
      description   = "Security group for example-instance-2"
      ingress_rules = local.ingress_rules
      egress_rules  = local.egress_rules
      tags          = {}
    }
  }

  ebs_volumes = {
    volume1 = {
      name              = "example-volume-1"
      availability_zone = "us-east-1a"
      size              = 10
      type              = "gp3"
      iops              = 3000
      throughput        = 125
      kms_key_id        = null
      snapshot_id       = null
      instance_key      = "instance1"
      device_name       = "/dev/sdf"
    },
    volume2 = {
      name              = "example-volume-2"
      availability_zone = "us-east-1b"
      size              = 10
      type              = "gp3"
      iops              = 3000
      throughput        = 125
      kms_key_id        = null
      snapshot_id       = null
      instance_key      = "instance2"
      device_name       = "/dev/sdg"
    }
  }

  ingress_rules = [
    {
      description      = "Allow SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      self             = false
    },
    {
      description      = "Allow HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      self             = false
    }
  ]

  egress_rules = [
    {
      description      = "Allow all outbound traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
    }
  ]
}
