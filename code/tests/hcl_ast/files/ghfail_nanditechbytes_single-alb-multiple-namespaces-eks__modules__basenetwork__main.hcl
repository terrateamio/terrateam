terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 4.0"
  }
}

locals {
  default_domain_name = data.aws_region.current.name == "us-east-1" ? "ec2.internal" : format("%s.compute.internal", data.aws_region.current.name)
  domain_name         = var.domain_name == "" ? local.default_domain_name : var.domain_name

  base_tags = {
    environment     = var.environment
  }

  single_nat_tag = {
    true = {
      HA = "disabled"
    }

    false = {}
  }

  nat_count = var.single_nat ? 1 : var.az_count

  tags = merge(
    var.tags,
    local.base_tags,
  )

  azs = slice(
    coalescelist(var.custom_azs, data.aws_availability_zones.available.names),
    0,
    var.az_count,
  )
}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

#############
# Basic VPC
#############

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_range
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.default_tenancy

  tags = merge(
    local.tags,
    local.single_nat_tag[var.single_nat],
    {
      Name = var.name
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name         = local.domain_name
  domain_name_servers = var.domain_name_servers

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-DHCPOptions"
    },
  )
}

resource "aws_vpc_dhcp_options_association" "dhcp_options_association" {
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "igw" {
  count = var.build_igw ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.tags,
    {
      Name = format("%s-IGW", var.name)
    },
  )
}

#############
# NAT Gateway
#############

resource "aws_eip" "nat_eip" {
  count = var.build_nat_gateways && var.build_igw ? local.nat_count : 0

  vpc = true

  tags = merge(
    local.tags,
    {
      Name = format("%s-NATEIP%d", var.name, count.index + 1)
    },
  )

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count = var.build_nat_gateways && var.build_igw ? local.nat_count : 0

  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  tags = merge(
    local.tags,
    local.single_nat_tag[var.single_nat],
    {
      Name = format("%s-NATGW%d", var.name, count.index + 1)
    },
  )

  depends_on = [aws_internet_gateway.igw]
}

#############
# Subnets
#############

resource "aws_subnet" "public_subnet" {
  count = var.build_igw ? var.az_count * var.public_subnets_per_az : 0

  availability_zone       = element(local.azs, count.index)
  cidr_block              = var.public_cidr_ranges[count.index]
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id

  tags = merge(
    var.public_subnet_tags[length(var.public_subnet_tags) == 1 ? 0 : floor(count.index / var.az_count)],
    local.tags,
    local.single_nat_tag[var.single_nat],
    {
      Name = format(
        "%s-%s%d",
        var.name,
        element(var.public_subnet_names, floor(count.index / var.az_count)),
        count.index % var.az_count + 1,
      )
    },
  )
}

resource "aws_subnet" "private_subnet" {
  count = var.az_count * var.private_subnets_per_az

  availability_zone       = element(local.azs, count.index)
  cidr_block              = var.private_cidr_ranges[count.index]
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.vpc.id

  tags = merge(
    var.private_subnet_tags[length(var.private_subnet_tags) == 1 ? 0 : floor(count.index / var.az_count)],
    local.tags,
    local.single_nat_tag[var.single_nat],
    {
      Name = format(
        "%s-%s%d",
        var.name,
        element(var.private_subnet_names, floor(count.index / var.az_count)),
        count.index % var.az_count + 1,
      )
    },
  )
}

#output "subnet_ids" {
#  value = aws_subnet.private_subnet.subnet_ids
#}
#########################
# Route Tables and Routes
#########################

resource "aws_route_table" "public_route_table" {
  count = var.build_igw ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.tags,
    {
      Name = format("%s-PublicRouteTable", var.name)
    },
  )
}

resource "aws_route_table" "private_route_table" {
  count = var.az_count

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.tags,
    local.single_nat_tag[var.single_nat],
    {
      Name = format("%s-PrivateRouteTable%d", var.name, count.index + 1)
    },
  )
}

resource "aws_route" "public_routes" {
  count = var.build_igw ? 1 : 0

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
  route_table_id         = aws_route_table.public_route_table[0].id
}

resource "aws_route" "private_routes" {
  count = var.build_nat_gateways && var.build_igw ? var.az_count : 0

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
  route_table_id         = element(aws_route_table.private_route_table.*.id, count.index)
}

resource "aws_route_table_association" "public_route_association" {
  count = var.build_igw ? var.az_count * var.public_subnets_per_az : 0

  route_table_id = aws_route_table.public_route_table[0].id
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
}

resource "aws_route_table_association" "private_route_association" {
  count = var.az_count * var.private_subnets_per_az

  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
}

#####
# VPN
#####

resource "aws_vpn_gateway" "vpn_gateway" {
  count = var.build_vpn ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.tags,
    {
      Name               = format("%s-VPNGateway", var.name)
      "transitvpc:spoke" = var.spoke_vpc
    },
  )
}

resource "aws_vpn_gateway_route_propagation" "vpn_routes_public" {
  count = var.build_vpn ? 1 : 0

  route_table_id = aws_route_table.public_route_table[0].id
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway[0].id
}

resource "aws_vpn_gateway_route_propagation" "vpn_routes_private" {
  count = var.build_vpn ? length(var.private_cidr_ranges) : 0

  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
  vpn_gateway_id = aws_vpn_gateway.vpn_gateway[0].id
}

###########
# Flow Logs
###########

resource "aws_flow_log" "s3_vpc_log" {
  count = var.build_s3_flow_logs ? 1 : 0

  log_destination      = aws_s3_bucket.vpc_log_bucket[0].arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
}

resource "aws_s3_bucket" "vpc_log_bucket" {
  count = var.build_s3_flow_logs ? 1 : 0

  bucket        = var.logging_bucket_name
  force_destroy = var.logging_bucket_force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_acl" "vpc_log_bucket_acl" {
  count  = var.build_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_log_bucket[0].id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_log_bucket_encryption" {
  count  = var.build_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_log_bucket[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.logging_bucket_encryption_kms_mster_key
      sse_algorithm     = var.logging_bucket_encryption
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_log_bucket_lifecycle" {
  count  = var.build_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.vpc_log_bucket[0].id

  rule {
    id = "rule-1"

    filter {
      prefix = var.logging_bucket_prefix
    }

    expiration {
      days = var.s3_flowlog_retention
    }

    status = "Enabled"
  }
}


resource "aws_flow_log" "cw_vpc_log" {
  count = var.build_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flowlog_role[0].arn
  log_destination = aws_cloudwatch_log_group.flowlog_group[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_cloudwatch_log_group" "flowlog_group" {
  count = var.build_flow_logs ? 1 : 0

  name              = "${var.name}-FlowLogs"
  retention_in_days = var.cloudwatch_flowlog_retention
}

resource "aws_iam_role" "flowlog_role" {
  count = var.build_flow_logs ? 1 : 0

  name = "${var.name}-FlowLogsRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "flowlog_policy" {
  count = var.build_flow_logs ? 1 : 0

  name = "${var.name}-FlowLogsPolicy"
  role = aws_iam_role.flowlog_role[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "${replace(aws_cloudwatch_log_group.flowlog_group[0].arn, ":*", "")}:*"
    }
  ]
}
EOF

}
