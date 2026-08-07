locals {
  # Transform Key Vault private endpoints configuration
  key_vault_private_endpoints = {
    for pe_name, pe in try(var.private_endpoints.key_vaults, {}) : pe_name => {

      name                            = coalesce(pe.name, "${var.deployment_prefix}-${pe.key_vault_name}-kv-pe")
      resource_group_name             = pe.resource_group_name
      location                        = var.locations[var.key_vaults[pe.key_vault_name].location_name]
      subnet_resource_id              = local.network_resource_ids[pe.network_name].subnets[pe.subnet_name].resource_id
      private_connection_resource_id  = module.key_vaults[pe.key_vault_name].resource_id
      private_service_connection_name = "${local.key_vault_private_endpoint_names[pe_name]}-psc"
      subresource_names               = ["vault"]
      network_interface_name          = "${var.deployment_prefix}-${pe.key_vault_name}-kv-nic"
      lock                            = local.private_endpoint_locks[pe_name]

      lock = (
        length([
          for group in pe.lock_groups :
          # Apply a lock only if lock_groups specifies a locked group
          group if contains(keys(local.locked_groups), group)
        ]) > 0
        ? (
          anytrue([
            for group in pe.lock_groups :
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

      # IP configurations if a specific IP is required
      ip_configurations = pe.private_ip != null ? {
        primary = {
          name               = "primary"
          private_ip_address = pe.private_ip
          subresource_name   = "vault"
          member_name        = "default"
        }
      } : {}

      # DNS zone configuration
      private_dns_zone_group_name = try(pe.dns_zone_group.name, "default")

      private_dns_zone_names = concat(
        compact([pe.dns_zone_group.private_dns_zone_name]),
        try(pe.dns_zone_group.private_dns_zone_names, [])
      )

      # Tags
      tags = merge(var.tags, (var.include_label_tags ? { keyvault_label = pe.key_vault_name } : {}))
    }
  }

  key_vault_private_endpoints_with_dns = {
    for pe_name, pe in try(var.private_endpoints.key_vaults, {}) : pe_name => merge(
      local.key_vault_private_endpoints[pe_name],
      {
        private_dns_zone_resource_ids = concat(
          compact([pe.dns_zone_group.private_dns_zone_id]),
          tolist(try(pe.dns_zone_group.private_dns_zone_ids, [])),
          tolist([
            for zone_name in concat(
              compact([pe.dns_zone_group.private_dns_zone_name]),
              try(pe.dns_zone_group.private_dns_zone_names, [])
            ) :
            azurerm_private_dns_zone.private_dns_zones[zone_name].id
        ]))
      }
    ) if(pe.dns_zone_group != null)
  }

  blob_container_private_endpoints = {
    for pe_name, pe in try(var.private_endpoints.blob_containers, {})
    : pe_name => {
      name                            = local.blob_container_private_endpoint_names[pe_name]
      resource_group_name             = pe.resource_group_name
      location                        = var.locations[var.storage_accounts[var.blob_containers[pe.container_name].storage_account_name].location_name]
      subnet_resource_id              = local.network_resource_ids[pe.network_name].subnets[pe.subnet_name].resource_id
      private_connection_resource_id  = module.storage_accounts[var.blob_containers[pe.container_name].storage_account_name].resource_id
      private_service_connection_name = "${local.blob_container_private_endpoint_names[pe_name]}-psc"
      network_interface_name          = "${local.blob_container_private_endpoint_names[pe_name]}-nic"
      subresource_names               = ["blob"]
      lock                            = local.private_endpoint_locks[pe_name]

      # IP configurations if a specific IP is required
      ip_configurations = try(pe.private_ip, null) != null ? {
        primary = {
          name               = "primary"
          private_ip_address = pe.private_ip
          subresource_name   = "blob"
          member_name        = "default"
        }
      } : {}

      # DNS zone configuration
      private_dns_zone_group_name = try(pe.dns_zone_group.name, "default")

      private_dns_zone_names = concat(
        compact([pe.dns_zone_group.private_dns_zone_name]),
        try(pe.dns_zone_group.private_dns_zone_names, [])
      )

      # Tags
      tags = local.blob_container_private_endpoint_tags[pe_name]
    }
  }

  blob_container_private_endpoints_with_dns = {
    for pe_name, pe in try(var.private_endpoints.blob_containers, {}) : pe_name => merge(
      local.blob_container_private_endpoints[pe_name],
      {
        private_dns_zone_resource_ids = concat(
          compact([pe.dns_zone_group.private_dns_zone_id]),
          tolist(try(pe.dns_zone_group.private_dns_zone_ids, [])),
          tolist([
            for zone_name in concat(
              compact([pe.dns_zone_group.private_dns_zone_name]),
              try(pe.dns_zone_group.private_dns_zone_names, [])
            ) :
            azurerm_private_dns_zone.private_dns_zones[zone_name].id
        ]))
      }
    ) if(pe.dns_zone_group != null)
  }

  file_share_private_endpoints = {
    for pe_name, pe in try(var.private_endpoints.file_shares, {})
    : pe_name => {
      name                            = local.file_share_private_endpoint_names[pe_name]
      resource_group_name             = pe.resource_group_name
      location                        = var.locations[var.storage_accounts[var.file_shares[pe.share_name].storage_account_name].location_name]
      subnet_resource_id              = local.network_resource_ids[pe.network_name].subnets[pe.subnet_name].resource_id
      private_connection_resource_id  = module.storage_accounts[var.file_shares[pe.share_name].storage_account_name].resource_id
      private_service_connection_name = "${local.file_share_private_endpoint_names[pe_name]}-psc"
      network_interface_name          = "${local.file_share_private_endpoint_names[pe_name]}-nic"
      subresource_names               = ["file"]
      lock                            = local.private_endpoint_locks[pe_name]

      # IP configurations if a specific IP is required
      ip_configurations = try(pe.private_ip, null) != null ? {
        primary = {
          name               = "primary"
          private_ip_address = pe.private_ip
          subresource_name   = "file"
          member_name        = "default"
        }
      } : {}

      # DNS zone configuration
      private_dns_zone_group_name = try(pe.dns_zone_group.name, "default")

      private_dns_zone_names = concat(
        compact([pe.dns_zone_group.private_dns_zone_name]),
        try(pe.dns_zone_group.private_dns_zone_names, [])
      )

      # Tags
      tags = local.file_share_private_endpoint_tags[pe_name]
    }
  }

  file_share_private_endpoints_with_dns = {
    for pe_name, pe in try(var.private_endpoints.file_shares, {}) : pe_name => merge(
      local.file_share_private_endpoints[pe_name],
      {
        private_dns_zone_resource_ids = concat(
          compact([pe.dns_zone_group.private_dns_zone_id]),
          tolist(try(pe.dns_zone_group.private_dns_zone_ids, [])),
          tolist([
            for zone_name in concat(
              compact([pe.dns_zone_group.private_dns_zone_name]),
              try(pe.dns_zone_group.private_dns_zone_names, [])
            ) :
            azurerm_private_dns_zone.private_dns_zones[zone_name].id
        ]))
      }
    ) if(pe.dns_zone_group != null)
  }

  all_private_endpoints = merge(
    local.key_vault_private_endpoints_with_dns,
    local.blob_container_private_endpoints_with_dns,
    local.file_share_private_endpoints_with_dns
  )
}
