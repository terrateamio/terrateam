#
# Ingress VPC resources
#

provider "aws" {
  alias  = "ingress"

  # If create is false then set default
  # region as it is a required attribute
  region = "${var.ingress_region}"
}

data "aws_vpc" "ingress-vpc" {
  provider = "aws.ingress"

  id = "${var.ingress_vpc_id}"
}

# Retrieve ingress VPC's admin subnet and route table

data "aws_subnet_ids" "ingress-admin" {
  provider = "aws.ingress"

  vpc_id = "${data.aws_vpc.ingress-vpc.id}"

  filter {
    name   = "tag:Name"
    values = ["*admin subnet*"]
  }
}

data "aws_subnet" "ingress-admin" {
  provider = "aws.ingress"
  count    = "${length(data.aws_subnet_ids.ingress-admin.ids)}"
  id       = "${element(flatten(data.aws_subnet_ids.ingress-admin.ids), count.index)}"
}

data "aws_route_tables" "ingress-admin" {
  provider = "aws.ingress"

  vpc_id = "${data.aws_vpc.ingress-vpc.id}"

  filter {
    name   = "tag:Name"
    values = [ "*admin route table*" ]
  }
}

# Retrieve ingress VPC's bastion instance's admin NIC

data "aws_network_interface" "ingress-bastion-nic" {
  provider = "aws.ingress"
  count    = "${length(data.aws_subnet_ids.ingress-admin.ids)}"

  filter {
    name   = "attachment.instance-id"
    values = [ "${var.ingress_bastion_id}" ]
  }
  filter {
    name   = "subnet-id"
    values = [ "${element(flatten(data.aws_subnet_ids.ingress-admin.ids), count.index)}" ]
  }
}