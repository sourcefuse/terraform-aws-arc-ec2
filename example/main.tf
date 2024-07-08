provider "aws" {
  region = "us-east-1"
}


module "ec2_instances" {
  source = "../"

  name                  = "${var.namespace}-${var.environment}-test"
  instance_type         = "t3.small"
  ami_id                = data.aws_ami.amazon_linux.id
  vpc_id                = data.aws_vpc.this.id
  subnet_id             = "subnet-066d0c78479b72e77"
  private_ip            = "10.12.134.2"
  instance_profile_data = local.instance_profile_data
  security_group_data   = local.security_group_data

  root_block_device_data = {
    volume_size = 10
    volume_type = "gp3"
  }
  additional_ebs_volumes = local.additional_ebs_volumes

}
