

variable "vpc_id" {
  type        = string
  description = "VCP ID on which loadbalancer has to be created"
}

variable "load_balancer_arn" {
  type        = string
  description = "Load balancer's ARN"
}


variable "target_groups" {
  type = map(object({
    port     = number
    protocol = string

    health_check = object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      path                = optional(string, "/")
      timeout             = optional(number, 20)
      interval            = optional(number, 30)
      matcher             = optional(string, "200")
    })

    listeners = list(object({
      port            = string
      protocol        = string
      ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
      certificate_arn = optional(string, null)

      default_action = object({
        type = string // valid values : redirect,fixed-response,forward if forward , then target_group_arn = aws_lb_target_group.this.arn
        redirect = optional(object({
          port        = number
          protocol    = string
          status_code = string
        }), null)

        fixed_response = optional(object({
          content_type = string
          message_body = string
          status_code  = optional(string, "200")
        }), null)

    }) }))

    target = object({
      port = number
    })

  }))
  description = "Target Group details "
}

variable "target_id" {
  type        = string
  description = "Target id for Target Group"
}

variable "tags" {
  type        = map(string)
  description = "(optional) Tags for AWS resources"
}
