provider "aws" {
  region = "us-east-1"
}


module "ec2_instances" {
  source = "../"

  region            = "us-east-1"
  ami_id            = data.aws_ami.this.id
  vpc_id            = data.aws_vpc.vpc.id
  subnet_ids        = data.aws_subnets.public.ids
  alb_name          = "my-alb"
  target_group_name = "my-target-group"
  listener_port     = 80

  instances   = local.instances
  ebs_volumes = local.ebs_volumes

}

module "alb" {
  source = "../module/alb"

  name                       = "elb-arc"
  enable                     = true
  internal                   = false
  load_balancer_type         = "application"
  instance_count             = 2
  subnets                    = data.aws_subnets.public.ids
  target_id                  = values(module.ec2_instances.instance_ids)
  vpc_id                     = data.aws_vpc.vpc.id
  allowed_ip                 = ["0.0.0.0/0"]
  allowed_ports              = [80, 443]
  listener_certificate_arn   = data.aws_acm_certificate.this.arn
  enable_deletion_protection = false
  with_target_group          = true
  https_enabled              = true
  http_enabled               = true
  https_port                 = 443
  listener_type              = "forward"
  target_group_port          = 80
  namespace                  = var.namespace
  tags = {
    name = "elb-arc"
  }

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    }
  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "TLS"
      target_group_index = 0
      certificate_arn    = data.aws_acm_certificate.this.arn
    }
  ]

  target_groups = [
    {
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 300
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 10
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  extra_ssl_certs = [
    {
      https_listener_index = 0
      certificate_arn      = data.aws_acm_certificate.this.arn
    }
  ]
}
