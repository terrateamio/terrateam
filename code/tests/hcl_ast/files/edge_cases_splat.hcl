splat_complex {
  # Basic splat
  ids = aws_instance.example[*].id

  # Splat with attribute access
  names = aws_instance.example[*].tags.Name

  # Splat with index
  first_ips = aws_instance.example[*].network_interface[0].ip_address

  # Chained splat
  all_addrs = var.resources[*].interfaces[*].addresses

  # Attribute splat
  attr_splat = var.items.*.name

  # Splat in function call
  joined = join(",", aws_instance.example[*].id)

  # Splat with conditional
  selected = var.enabled ? aws_instance.example[*].id : []

  # Splat in for expression
  mapped = [for id in aws_instance.example[*].id : upper(id)]
}
