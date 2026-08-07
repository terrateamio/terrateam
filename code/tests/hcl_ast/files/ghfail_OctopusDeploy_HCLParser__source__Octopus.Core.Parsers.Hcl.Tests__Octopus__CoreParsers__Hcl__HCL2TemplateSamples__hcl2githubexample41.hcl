#
# Egress VPC resources
#

provider "aws" {
  alias  = "egress"

  region = "${var.egress_region}"
}

data "aws_vpc" "egress-vpc" {
  provider = "aws.egress"

  id = "${var.egress_vpc_id}"
}

# Retrieve egress VPC's admin subnets

data "aws_subnet_ids" "egress-admin" {
  provider = "aws.egress"

  vpc_id = "${data.aws_vpc.egress-vpc.id}"

  filter {
    name   = "tag:Name"
    values = ["*admin subnet*"]
  }
}

data "aws_subnet" "egress-admin" {
  provider = "aws.egress"
  count    = "${length(data.aws_subnet_ids.egress-admin.ids)}"
  id       = "${element(flatten(data.aws_subnet_ids.egress-admin.ids), count.index)}"
}

data "aws_route_tables" "egress-admin" {
  provider = "aws.egress"

  vpc_id = "${data.aws_vpc.egress-vpc.id}"

  filter {
    name   = "tag:Name"
    values = [ "*admin route table*" ]
  }
}

# Retrieve egress VPC's bastion instance's admin NIC

data "aws_network_interface" "egress-bastion-nic" {
  provider = "aws.egress"
  count    = "${length(data.aws_subnet_ids.egress-admin.ids)}"

  filter {
    name   = "attachment.instance-id"
    values = [ "${var.egress_bastion_id}" ]
  }
  filter {
    name   = "subnet-id"
    values = [ "${element(flatten(data.aws_subnet_ids.egress-admin.ids), count.index)}" ]
  }
}