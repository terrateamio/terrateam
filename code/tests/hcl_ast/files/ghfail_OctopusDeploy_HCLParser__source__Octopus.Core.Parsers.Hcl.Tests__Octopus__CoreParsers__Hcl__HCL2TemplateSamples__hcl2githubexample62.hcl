module "aws-vpn-docker-ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  ami                         = var.instance_ami
  instance_count              = 1
  name                        = "AWS VPN - Docker"
  instance_type               = var.ec2-instance-type
  key_name                    = var.key-name
  monitoring                  = false
  vpc_security_group_ids      = [module.aws-vpn-docker-security-group.this_security_group_id]
  subnet_id                   = module.aws-vpn-docker-vpc.private_subnets[0]
  disable_api_termination     = false
}