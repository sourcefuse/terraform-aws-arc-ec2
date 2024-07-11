locals {

  security_group_data = {
    create             = true
    name               = "${var.namespace}-${var.environment}-sg"
    security_group_ids = []
    ingress_rules = [{
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.this.cidr_block]
    }]
    egress_rules = [{
      description = "Allow All outbound calls"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }]
  }

  instance_profile_data = {
    name   = "${var.namespace}-${var.environment}-test-profile"
    create = true
    policy_documents = [
      {
        name   = "s3-read"
        policy = data.aws_iam_policy_document.s3_read_list.json
      }
    ]
  }

  additional_ebs_volumes = {
    "vol-1" = {
      name        = "vol-1"
      device_name = "/dev/sdb"
      encrypted   = true
      size        = 20
      type        = "gp3"
  } }

  target_groups = {
    "group-1" = {
      port     = 80
      protocol = "HTTP"

      health_check = {
        path     = "/"
        timeout  = 20
        interval = 30
      }
      listeners = [
        {
          port       = "80"
          protocol   = "HTTP"
          ssl_policy = null

          default_action = {
            type = "redirect"
            redirect = {
              port        = 443
              protocol    = "HTTPS"
              status_code = "HTTP_301"
            }
          }

        },
        {
          port            = "443"
          protocol        = "HTTPS"
          ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
          certificate_arn = "arn:aws:acm:us-east-1:xxxx:certificate/xx-xx-xx-xx-xx"

          default_action = {
            type = "forward"
          }
        }
      ]
      target = {
        port = 80
      }
    }
  }

  load_balancer_data = {
    create  = true
    name    = "${var.namespace}-${var.environment}-alb"
    subnets = data.aws_subnets.public.ids
  }

}
