######################
# Private Subnets
######################

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  count             = local.priv_az_count
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + local.az_count)
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = {
    Name      = "${terraform.workspace}-${var.app_name}-priv-${count.index}"
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_route_table" "private" {
  count  = local.priv_az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name      = "${terraform.workspace}-${var.app_name}-priv-${count.index}"
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_route_table_association" "private" {
  count          = local.priv_az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}