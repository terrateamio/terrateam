resource "aws_subnet" "this" {
  for_each = var.cidr_blocks

  assign_ipv6_address_on_creation = var.enable_ipv6
  availability_zone               = each.key
  cidr_block                      = each.value
  ipv6_cidr_block                 = local.ipv6_cidrs[each.key]
  map_public_ip_on_launch         = var.enable_public_ip_on_launch
  vpc_id                          = var.vpc.id

  tags = merge(
    var.tags,
    {
      AvailabilityZone         = each.key
      Name                     = join("-", concat(var.namespace, [var.name, "public", each.key]))
      "kubernetes.io/role/elb" = "1"
    }
  )
}

locals {
  azs = sort(keys(var.cidr_blocks))
  cidrs = [
    for az in sort(keys(var.cidr_blocks)) :
    var.enable_ipv6 ?
    cidrsubnet(
      cidrsubnet(var.vpc.ipv6_cidr_block, 1, 0),
      7,
      index(local.azs, az)
    ) :
    null
  ]
  ipv6_cidrs = zipmap(local.azs, local.cidrs)
}
