#################################################
# VPC
#################################################

module "aws-vpn-docker-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.5.0"

  name = var.vpc-name
  cidr = "10.0.0.0/16"

  default_vpc_enable_dns_hostnames = true
  enable_dns_hostnames             = true
  map_public_ip_on_launch          = false

  azs            = ["us-east-1a"]
  private_subnets = ["10.0.0.0/18"]

  tags = {
    Name = "aws-vpn-docker-vpc"
  }
}

module "aws-vpn-docker-security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.0.1"

  name   = var.security-group-name
  vpc_id = module.aws-vpn-docker-vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH Port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP Port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name = "aws-vpn-docker-sg"
  }
}