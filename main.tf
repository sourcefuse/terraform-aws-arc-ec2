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
  iam_instance_profile        = var.instance_profile_data.create ? aws_iam_instance_profile.this.name : var.instance_profile_data.name

  key_name               = aws_key_pair.generated_key[each.key].key_name
  monitoring             = var.enable_detailed_monitoring
  subnet_id              = var.subnet_id
  user_data              = var.user_data
  vpc_security_group_ids = var.security_group_data.create ? [aws_security_group.this.id] : var.security_group_data.security_group_ids
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
}

#########################
# Additional EBS Volumes
#########################

resource "aws_ebs_volume" "this" {
  for_each = var.additional_ebs_volumes

  availability_zone = aws_instance.this.availability_zone
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id
  iops              = each.value.iops
  throughput        = each.value.throughput
  size              = each.value.size
  type              = each.value.type

  tags = var.tags
}

######################
# AWS Volume Attachment
######################

resource "aws_volume_attachment" "this" {
  for_each = var.additional_ebs_volumes

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.this[each.key].id
  instance_id = aws_instance.this.id
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
##################
# AWS Key Pair TODO:
#################
resource "aws_key_pair" "generated_key" {
  key_name   = var.name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

data "aws_iam_policy_document" "ec2_ebs_kms" {
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_kms_key" "this" {
  for_each                = var.instances
  description             = "KMS key for EC2 EBS encryption."
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.ec2_ebs_kms.json
}

####################
# AWS Security Group
#####################

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

########################
# AWS IAM Instance Profile TODO:
#########################
resource "aws_iam_instance_profile" "this" {
  for_each = var.instances
  name     = "${var.name}-profile"
}

resource "aws_iam_role" "this" {
  for_each = var.instances
  name     = "${var.name}-role"
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
}

########################
# AWS IAM Policy Document
#########################
resource "aws_iam_role_policy" "ssm_params_and_secrets" {
  for_each = var.instances
  name     = "${var.name}-policy"
  role     = aws_iam_role.this[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "secretsmanager:GetSecretValue"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_eip" "lb" {
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = var.tags
}
