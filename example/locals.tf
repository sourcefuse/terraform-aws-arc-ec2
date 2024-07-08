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
      # iops                  = optional(string, null)
      # kms_key_id            = optional(string, null)
      # throughput            = optional(string, null)
      volume_size = 20
      volume_type = "gp3"

  } }


}
