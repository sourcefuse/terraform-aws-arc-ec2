##############################################
#  EC2 resource
##############################################
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  associate_public_ip_address = var.associate_public_ip_address
  disable_api_termination     = var.enable_termination_protection
  disable_api_stop            = var.enable_stop_protection
  ebs_optimized               = var.ebs_optimized
  iam_instance_profile        = var.instance_profile_data.create ? aws_iam_instance_profile.this[0].name : var.instance_profile_data.name

  key_name               = var.ssh_key_pair
  monitoring             = var.enable_detailed_monitoring
  subnet_id              = var.subnet_id
  user_data              = var.user_data
  user_data_base64       = var.user_data_base64
  vpc_security_group_ids = var.security_group_data.create ? [aws_security_group.this[0].id] : var.security_group_data.security_group_ids
  private_ip             = var.private_ip

  metadata_options {
    http_endpoint               = var.instance_metadata_options.http_endpoint
    http_protocol_ipv6          = var.instance_metadata_options.http_protocol_ipv6
    http_put_response_hop_limit = var.instance_metadata_options.http_put_response_hop_limit
    http_tokens                 = var.instance_metadata_options.http_tokens
    instance_metadata_tags      = var.instance_metadata_options.instance_metadata_tags
  }

  root_block_device {
    delete_on_termination = var.root_block_device_data.delete_on_termination
    encrypted             = var.root_block_device_data.encrypted
    iops                  = var.root_block_device_data.iops
    kms_key_id            = var.root_block_device_data.kms_key_id
    throughput            = var.root_block_device_data.throughput
    volume_size           = var.root_block_device_data.volume_size
    volume_type           = var.root_block_device_data.volume_type
  }

  lifecycle {
    ignore_changes = [
      user_data,
      associate_public_ip_address
    ]
  }

  tags = merge({
    Name = var.name
  }, var.tags)

  volume_tags = var.tags
}

#############################
# Additional EBS Volumes
#############################

resource "aws_ebs_volume" "this" {
  for_each = var.additional_ebs_volumes

  availability_zone = aws_instance.this.availability_zone
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id
  iops              = each.value.iops
  throughput        = each.value.throughput
  size              = each.value.size
  type              = each.value.type

  tags = each.value.name == null ? var.tags : merge({ Name : each.value.name }, var.tags)
}

resource "aws_volume_attachment" "this" {
  for_each = var.additional_ebs_volumes

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.this[each.key].id
  instance_id = aws_instance.this.id
}

###########################
# AWS Security Group
###########################

resource "aws_security_group" "this" {
  count = var.security_group_data.create ? 1 : 0

  name        = var.security_group_data.name
  vpc_id      = var.vpc_id
  description = var.security_group_data.description

  dynamic "ingress" {
    for_each = var.security_group_data.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      security_groups  = ingress.value.security_groups
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.security_group_data.egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      security_groups  = egress.value.security_groups
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

########################################
# AWS IAM Instance Profile
########################################
resource "aws_iam_instance_profile" "this" {
  count = var.instance_profile_data.create ? 1 : 0
  name  = "${var.name}-profile"
  role  = aws_iam_role.this[0].name
}

resource "aws_iam_role" "this" {
  count = var.instance_profile_data.create ? 1 : 0

  name = "${var.name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = var.instance_profile_data.managed_policy_arns
}


resource "aws_iam_role_policy" "inline" {
  for_each = var.instance_profile_data.create ? {
  for idx, policy in var.instance_profile_data.policy_documents : "${var.name}-${idx}" => policy } : {}

  name   = each.value.name
  role   = aws_iam_role.this[0].name
  policy = each.value.policy
}


resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.instance_profile_data.create ? toset(var.instance_profile_data.managed_policy_arns) : []

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}




resource "aws_eip" "this" {
  count = var.associate_public_ip_address && var.assign_eip ? 1 : 0

  instance = aws_instance.this.id
  domain   = "vpc"
  tags     = var.tags
}

## Create Load Balancer
module "load_balancer" {
  source = "./modules/alb"
  count  = var.load_balancer_data.create ? 1 : 0

  name                                        = var.load_balancer_data.name
  vpc_id                                      = var.vpc_id
  internal                                    = var.load_balancer_data.internal
  load_balancer_type                          = var.load_balancer_data.load_balancer_type
  security_group_data                         = var.load_balancer_security_group_data
  subnets                                     = var.load_balancer_data.subnets
  enable_deletion_protection                  = var.load_balancer_data.enable_deletion_protection
  idle_timeout                                = var.load_balancer_data.idle_timeout
  enable_cross_zone_load_balancing            = var.load_balancer_data.enable_cross_zone_load_balancing
  enable_http2                                = var.load_balancer_data.enable_http2
  enable_tls_version_and_cipher_suite_headers = var.load_balancer_data.enable_tls_version_and_cipher_suite_headers
  enable_xff_client_port                      = var.load_balancer_data.enable_xff_client_port
  preserve_host_header                        = var.load_balancer_data.preserve_host_header
  enable_waf_fail_open                        = var.load_balancer_data.enable_waf_fail_open
  desync_mitigation_mode                      = var.load_balancer_data.desync_mitigation_mode
  xff_header_processing_mode                  = var.load_balancer_data.xff_header_processing_mode
  ip_address_type                             = var.load_balancer_data.ip_address_type
  drop_invalid_header_fields                  = var.load_balancer_data.drop_invalid_header_fields

  target_groups = var.target_groups
  target_id     = aws_instance.this.id

  load_balancer_create_timeout = var.load_balancer_create_timeout
  load_balancer_delete_timeout = var.load_balancer_delete_timeout
  load_balancer_update_timeout = var.load_balancer_update_timeout

  tags = var.tags
}
