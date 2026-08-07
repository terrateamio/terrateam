######################
# NAT Subnets
######################

resource "aws_eip" "nat_ip" {
  count = local.nat_az_count
  vpc   = true

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_nat_gateway" "nat" {
  count         = local.nat_az_count
  allocation_id = aws_eip.nat_ip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name      = "${terraform.workspace}-${var.app_name}-gw-${count.index}"
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}