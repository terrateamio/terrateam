###
# AWS VPC
###

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "covidportal" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name                  = var.vpc_name
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# AWS VPC Privatelink Endpoints
###

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id              = aws_vpc.covidportal.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.privatelink.id}",
  ]
  subnet_ids = data.aws_subnet_ids.ecr_endpoint_available.ids
}

resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id              = aws_vpc.covidportal.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.privatelink.id}",
  ]
  subnet_ids = data.aws_subnet_ids.ecr_endpoint_available.ids
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.covidportal.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.kms"
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.privatelink.id}",
  ]
  subnet_ids = aws_subnet.covidportal_private.*.id
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.covidportal.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.privatelink.id}",
  ]
  subnet_ids = aws_subnet.covidportal_private.*.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.covidportal.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = [aws_vpc.covidportal.main_route_table_id]
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.covidportal.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.logs"
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.privatelink.id}",
  ]
  subnet_ids = aws_subnet.covidportal_private.*.id
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = aws_vpc.covidportal.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.monitoring"
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.privatelink.id}",
  ]
  subnet_ids = aws_subnet.covidportal_private.*.id
}

###
# AWS Internet Gateway
###

resource "aws_internet_gateway" "covidportal" {
  vpc_id = aws_vpc.covidportal.id

  tags = {
    Name                  = var.vpc_name
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# AWS Subnets
###

resource "aws_subnet" "covidportal_private" {
  count = 3

  vpc_id            = aws_vpc.covidportal.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name                  = "Private Subnet 0${count.index + 1}"
    (var.billing_tag_key) = var.billing_tag_value
    Access                = "private"
  }
}

resource "aws_subnet" "covidportal_public" {
  count = 3

  vpc_id            = aws_vpc.covidportal.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + 3)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name                  = "Public Subnet 0${count.index + 1}"
    (var.billing_tag_key) = var.billing_tag_value
    Access                = "public"
  }
}

data "aws_subnet_ids" "ecr_endpoint_available" {
  vpc_id = aws_vpc.covidportal.id
  filter {
    name   = "tag:Access"
    values = ["private"]
  }
  filter {
    name   = "availability-zone"
    values = ["ca-central-1a", "ca-central-1b"]
  }
  depends_on = [aws_subnet.covidportal_private]
}

###
# AWS NAT GW
###

resource "aws_eip" "covidportal_natgw" {
  count      = 3
  depends_on = [aws_internet_gateway.covidportal]

  vpc = true

  tags = {
    Name                  = "${var.vpc_name} NAT GW ${count.index}"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_nat_gateway" "covidportal" {
  count      = 3
  depends_on = [aws_internet_gateway.covidportal]

  allocation_id = aws_eip.covidportal_natgw.*.id[count.index]
  subnet_id     = aws_subnet.covidportal_public.*.id[count.index]

  tags = {
    Name                  = "${var.vpc_name} NAT GW"
    (var.billing_tag_key) = var.billing_tag_value
  }
}



###
# AWS Routes
###

resource "aws_route_table" "covidportal_public_subnet" {
  vpc_id = aws_vpc.covidportal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.covidportal.id
  }

  tags = {
    Name                  = "Public Subnet Route Table"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_route_table_association" "covidportal" {
  count = 3

  subnet_id      = aws_subnet.covidportal_public.*.id[count.index]
  route_table_id = aws_route_table.covidportal_public_subnet.id
}

resource "aws_route_table" "covidportal_private_subnet" {
  count = 3

  vpc_id = aws_vpc.covidportal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.covidportal.*.id[count.index]
  }

  tags = {
    Name                  = "Private Subnet Route Table ${count.index}"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_route_table_association" "covidportal_private_route" {
  count = 3

  subnet_id      = aws_subnet.covidportal_private.*.id[count.index]
  route_table_id = aws_route_table.covidportal_private_subnet.*.id[count.index]
}

###
# AWS Security Groups
###

resource "aws_security_group" "covidportal" {
  name        = "covidportal"
  description = "Ingress - Covid Portal"
  vpc_id      = aws_vpc.covidportal.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_security_group_rule" "covidportal_ingress_alb" {
  description              = "Security group rule for Portal Ingress ALB"
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.covidportal.id
  source_security_group_id = aws_security_group.covidportal_load_balancer.id
}

resource "aws_security_group_rule" "covidportal_egress_privatelink" {
  description              = "Security group rule for Portal egress through privatelink"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.covidportal.id
  source_security_group_id = aws_security_group.privatelink.id
}

resource "aws_security_group_rule" "covidportal_egress_s3_privatelink" {
  description       = "Security group rule for Retrieval S3 egress through privatelink"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.covidportal.id
  prefix_list_ids = [
    aws_vpc_endpoint.s3.prefix_list_id
  ]
}

resource "aws_security_group_rule" "covidportal_egress_database" {
  description              = "Security group rule for Portal DB egress through privatelink"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.covidportal.id
  source_security_group_id = aws_security_group.covidportal_database.id
}


resource "aws_security_group" "covidportal_load_balancer" {
  name        = "covidportal-load-balancer"
  description = "Ingress - covidportal Load Balancer"
  vpc_id      = aws_vpc.covidportal.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  egress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_security_group" "covidportal_database" {
  name        = "covidportal-database"
  description = "Ingress - covidportal Database"
  vpc_id      = aws_vpc.covidportal.id

  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432
    security_groups = [
      aws_security_group.covidportal.id,
    ]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_security_group" "covidportal_egress" {
  name        = "egress-anywhere"
  description = "Egress - CovidShield External Services"
  vpc_id      = aws_vpc.covidportal.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_security_group_rule" "covidportal_egress_email" {
  description       = "Security group rule for Portal email egress"
  type              = "egress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  security_group_id = aws_security_group.covidportal_egress.id
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
}

resource "aws_security_group_rule" "covidportal_egress_new_relic" {
  description       = "Security group rule for Portal New Relic egress"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.covidportal_egress.id
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
}

resource "aws_security_group" "privatelink" {
  name        = "privatelink"
  description = "privatelink endpoints"
  vpc_id      = aws_vpc.covidportal.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_security_group_rule" "privatelink_portal_ingress" {
  description              = "Security group rule for Portal ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.covidportal.id
}

###
# AWS Network ACL
###

resource "aws_default_network_acl" "covidportal" {
  default_network_acl_id = aws_vpc.covidportal.default_network_acl_id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }

  ingress {
    protocol   = -1
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  // See https://www.terraform.io/docs/providers/aws/r/default_network_acl.html#managing-subnets-in-the-default-network-acl
  lifecycle {
    ignore_changes = [subnet_ids]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}
