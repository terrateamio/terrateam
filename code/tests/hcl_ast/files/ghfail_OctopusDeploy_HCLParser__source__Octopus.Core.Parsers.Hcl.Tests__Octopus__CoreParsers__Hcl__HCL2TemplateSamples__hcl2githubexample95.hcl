######################
# Region's VPC & IG
######################

data "aws_availability_zones" "azs" {
}

locals {
  az_count      = min(length(data.aws_availability_zones.azs.names), var.az_limit)
  priv_az_count = var.create_private ? local.az_count : 0
  nat_az_count  = var.create_private && var.create_nat ? local.az_count : 0
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "${terraform.workspace}-${var.app_name}-vpc"
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name      = "${terraform.workspace}-${var.app_name}-scanning-cluster"
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}