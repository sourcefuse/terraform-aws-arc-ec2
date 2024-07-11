variable "name" {
  type        = string
  description = "Name of the Loadbalancer"
}

variable "internal" {
  type        = bool
  default     = false
  description = "If true, the LB will be internal."
}

variable "load_balancer_type" {
  type        = string
  default     = "application"
  description = "The type of load balancer to create. Possible values are application or network. The default value is application."
}

variable "subnets" {
  type        = list(any)
  description = "A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type network. Changing this value will for load balancers of type network will force a recreation of the resource."
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false."
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle."
}

variable "enable_cross_zone_load_balancing" {
  type        = bool
  default     = true
  description = "Indicates whether cross zone load balancing should be enabled in application load balancers."
}

variable "enable_http2" {
  type        = bool
  default     = true
  description = "Indicates whether HTTP/2 is enabled in application load balancers."
}

variable "enable_tls_version_and_cipher_suite_headers" {
  type        = bool
  default     = false
  description = "Indicates whether the two headers (x-amzn-tls-version and x-amzn-tls-cipher-suite), which contain information about the negotiated TLS version and cipher suite, are added to the client request before sending it to the target."
}

variable "enable_xff_client_port" {
  type        = bool
  default     = false
  description = "Indicates whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in application load balancers."
}

variable "preserve_host_header" {
  type        = bool
  default     = false
  description = "Indicates whether Host header should be preserve and forward to targets without any change. Defaults to false."
}

variable "enable_waf_fail_open" {
  type        = bool
  default     = false
  description = "Indicates whether to route requests to targets if lb fails to forward the request to AWS WAF"
}

variable "desync_mitigation_mode" {
  type        = string
  default     = "defensive"
  description = "Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync."
}

variable "xff_header_processing_mode" {
  type        = string
  default     = "append"
  description = "Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target."
}

variable "ip_address_type" {
  type        = string
  default     = "ipv4"
  description = "(Optional) Type of IP addresses used by the subnets for your load balancer. The possible values depend upon the load balancer type: ipv4 (all load balancer types), dualstack (all load balancer types), and dualstack-without-public-ipv4 (type application only)."
}

variable "drop_invalid_header_fields" {
  type        = bool
  default     = false
  description = "Whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false). The default is false. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type application."
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
  description = "(optional) Security Group data for Loadbalancer"
  default = {
    create = true
    ingress_rules = [
      {
        description = "Allow http port"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "Allow https port"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    egress_rules = [{
      description = "Allow All outbound calls"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }]
  }
}

variable "vpc_id" {
  type        = string
  description = "The identifier of the VPC in which to create the target group."
}

variable "load_balancer_create_timeout" {
  type        = string
  default     = "10m"
  description = "Timeout value when creating the ALB."
}

variable "load_balancer_delete_timeout" {
  type        = string
  default     = "10m"
  description = "Timeout value when deleting the ALB."
}

variable "load_balancer_update_timeout" {
  type        = string
  default     = "10m"
  description = "Timeout value when updating the ALB."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resource"
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
      timeout             = optional(number, 30)
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

variable "web_acl_arn" {
  type        = string
  description = "(optional) WAF Web ACL ARN"
  default     = null
}
