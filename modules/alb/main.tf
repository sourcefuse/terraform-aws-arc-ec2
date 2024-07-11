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

# Create an Load Balancer
resource "aws_lb" "this" {
  name                                        = var.name
  internal                                    = var.internal
  load_balancer_type                          = var.load_balancer_type
  security_groups                             = var.security_group_data.create ? [aws_security_group.this[0].id] : var.security_group_data.security_group_ids
  subnets                                     = var.subnets
  enable_deletion_protection                  = var.enable_deletion_protection
  idle_timeout                                = var.idle_timeout
  enable_cross_zone_load_balancing            = var.enable_cross_zone_load_balancing
  enable_http2                                = var.enable_http2
  enable_tls_version_and_cipher_suite_headers = var.enable_tls_version_and_cipher_suite_headers
  enable_xff_client_port                      = var.enable_xff_client_port
  preserve_host_header                        = var.preserve_host_header
  enable_waf_fail_open                        = var.enable_waf_fail_open
  desync_mitigation_mode                      = var.desync_mitigation_mode
  xff_header_processing_mode                  = var.xff_header_processing_mode
  ip_address_type                             = var.ip_address_type
  drop_invalid_header_fields                  = var.drop_invalid_header_fields

  # sonarlint-disable-next-line terraform:S6258
  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []
    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  timeouts {
    create = var.load_balancer_create_timeout
    delete = var.load_balancer_delete_timeout
    update = var.load_balancer_update_timeout
  }

  tags = var.tags
}

module "target_groups" {
  source = "../target-group"

  vpc_id            = var.vpc_id
  load_balancer_arn = aws_lb.this.arn
  target_groups     = var.target_groups
  target_id         = var.target_id

  tags = var.tags

  depends_on = [aws_lb.this]
}


resource "aws_wafv2_web_acl_association" "this" {
  count = var.web_acl_arn == null ? 0 : 1

  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.web_acl_arn
}
