locals {
  internal_network_resource_ids = {
    for network_name, network in local.networks :
    network_name => {
      resource_id = module.networks[network_name].resource_id

      subnets = {
        for subnet_name, subnet in network.subnets :
        subnet_name => {
          resource_id = module.networks[network_name].subnets[subnet_name].resource_id
        }
      }
    } if network != null
  }

  external_network_resource_ids = {
    for network_name, network in var.external_networks :
    network_name => {
      resource_id = network.resource_id

      subnets = {
        for subnet_name, subnet in network.subnets :
        subnet_name => {
          resource_id = "${trimsuffix(network.resource_id, "/")}/subnets/${coalesce(subnet.name, subnet_name)}"
        }
      }
    } if try(network.resource_id, null) != null
  }

  network_resource_ids = merge(
    local.internal_network_resource_ids,
    local.external_network_resource_ids
  )

  registration_dns_zones = {
    for network_name, network in var.networks :
    network_name => {
      zone_name   = network.private_dns_zones.registration_zone_name
      zone_config = var.private_dns_zones[network.private_dns_zones.registration_zone_name]
      zone_id     = azurerm_private_dns_zone.private_dns_zones[network.private_dns_zones.registration_zone_name].id
    } if try(network.private_dns_zones.registration_zone_name, null) != null
  }

  resolution_dns_zones = {
    for network_resolution_zone in flatten([
      for network_name, network in var.networks : values({
        for zone_name in concat(
          compact([network.private_dns_zones.resolution_zone_name]),
          try(network.private_dns_zones.resolution_zone_names, [])
          ) : zone_name => {
          network_name = network_name
          zone_name    = zone_name
          zone_config  = var.private_dns_zones[zone_name]
          zone_id      = azurerm_private_dns_zone.private_dns_zones[zone_name].id
        }
      }) if(network.private_dns_zones != null)
    ]) : "${network_resolution_zone.network_name}_${network_resolution_zone.zone_name}" => network_resolution_zone
  }

  networks = {
    for network_ref, network in var.networks : network_ref => {
      address_spaces         = coalesce(network.address_spaces, compact([network.address_space]))
      dns_ips                = network.dns_ip_addresses
      enable_ddos_protection = network.enable_ddos_protection
      location_name          = network.location_name
      resource_group_name    = network.resource_group_name
      name                   = local.network_names[network_ref]
      tags                   = network.tags

      lock = (
        length([
          for group in network.lock_groups :
          # Apply a lock only if lock_groups specifies a locked group
          group if contains(keys(local.locked_groups), group)
        ]) > 0
        ? (
          anytrue([
            for group in network.lock_groups :
            # Apply a lock only if the group is locked
            # Read-only is the most restrictive lock. If any group is read-only, apply it.
            # Otherwise, apply a no-delete lock.
            contains(keys(local.locked_groups), group)
            && try(local.locked_groups[group].read_only, false)
          ])
          ? { kind = local.lock_modes.read_only }
          : { kind = local.lock_modes.no_delete }
        )
        : null
      )

      subnets = {
        for subnet_ref, subnet in network.subnets : subnet_ref => {
          address_space       = subnet.address_space
          name                = lower(coalesce(subnet.name, subnet_ref))
          security_group_name = subnet.security_group_name
          route_table_name    = subnet.route_table_name
          routes              = subnet.route_traffic
        }
      }
    } if network != null
  }

  network_address_spaces = {
    for network_name, network in merge(var.networks, var.external_networks)
    : network_name => {
      address_spaces = toset(coalesce(network.address_spaces, compact([network.address_space])))

      subnets = {
        for subnet_name, subnet in network.subnets
        : subnet_name => {
          address_space = tostring(subnet.address_space)
        }
      }
    } if network != null
  }
}
