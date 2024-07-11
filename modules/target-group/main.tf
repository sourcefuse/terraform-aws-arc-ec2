

# Create a target group
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name     = each.key
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = each.value.health_check.enabled
    path                = each.value.health_check.path
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    matcher             = each.value.health_check.matcher
  }

  tags = var.tags
}

resource "aws_lb_listener" "this" {
  for_each = local.listerner_map

  load_balancer_arn = var.load_balancer_arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.protocol == "HTTP" ? null : each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn

  default_action {
    type             = each.value.default_action.type
    target_group_arn = each.value.default_action.type == "forward" ? aws_lb_target_group.this[each.value.group_key].arn : null

    dynamic "redirect" {
      for_each = each.value.default_action.type == "redirect" ? [1] : []
      content {
        port        = each.value.default_action.redirect.port
        protocol    = each.value.default_action.redirect.protocol
        status_code = each.value.default_action.redirect.status_code
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.default_action.type == "fixed_response" ? [1] : []
      content {
        content_type = each.value.default_action.fixed_response.content_type
        message_body = each.value.default_action.fixed_response.message_body
        status_code  = each.value.default_action.fixed_response.status_code
      }
    }

  }

  depends_on = [aws_lb_target_group.this]
}


# Attach EC2 instance to the target group
resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_groups

  target_group_arn = aws_lb_target_group.this[each.key].arn
  target_id        = var.target_id
  port             = each.value.target.port
}
