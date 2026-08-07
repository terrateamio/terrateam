resource "aws_route" "vpc_peering_connection_id" {


  route_table_id              = var.route_table_id
  destination_cidr_block      = var.vpc_peering_dest_cidr_block
  #destination_ipv6_cidr_block = ""
  vpc_peering_connection_id   = var.vpc_peering_connection_id
}