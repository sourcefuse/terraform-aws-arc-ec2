data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.namespace}-poc-vpc"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "aws_iam_policy_document" "s3_read_list" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::your-bucket-name",
      "arn:aws:s3:::your-bucket-name/*",
    ]
  }
}
