######################
# Public Subnets
######################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = local.az_count
  map_public_ip_on_launch = true

  # offset by count because the private subnets came first
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = {
    Name      = "${terraform.workspace}-${var.app_name}-pub-${count.index}"
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_route_table" "public" {
  count  = local.az_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name      = "${terraform.workspace}-${var.app_name}-pub-${count.index}"
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}