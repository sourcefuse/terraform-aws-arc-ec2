data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.namespace}-${var.environment}-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name = "tag:Name"
    values = [
      "${var.namespace}-${var.environment}-vpc-public-1",
      "${var.namespace}-${var.environment}-vpc-public-2"
    ]
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_ami" "this" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "tag:Name"
    values = ["arc-test"] # Replace with your actual AMI name
  }
}

data "aws_acm_certificate" "this" {
  domain   = var.domain_name
  statuses = ["ISSUED"] # Optional: Filter by certificate status, e.g., ISSUED, PENDING_VALIDATION, etc.
}

data "aws_availability_zones" "available" {}