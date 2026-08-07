locals {
  firewall_policy_id = {
    for vnet_name, policy in module.fw_policies : vnet_name => policy.resource_id
  }
}

locals {
  firewall_ip_configurations = { for vnet_key, vnet_value in local.firewall_merged_ip_configurations : vnet_key =>
    { for ip_config_key, ip_config_value in vnet_value : ip_config_key => {
      name                 = try(ip_config_value.name == null ? ip_config_key : ip_config_value.name, ip_config_key)
      public_ip_address_id = module.fw_default_ips[ip_config_value.public_ip_key].public_ip_id
      subnet_id            = ip_config_value.is_default ? module.hub_virtual_network_subnets[ip_config_value.subnet_key].resource_id : null
    } }
  }
  firewall_merged_ip_configurations = { for vnet_key, vnet_value in var.hub_virtual_networks : vnet_key =>
    length(vnet_value.firewall.ip_configurations) > 0 ?
    { for ip_config_key, ip_config_value in vnet_value.firewall.ip_configurations : ip_config_key => {
      public_ip_key    = ip_config_key == "default" ? vnet_key : "${vnet_key}-${ip_config_key}"
      subnet_key       = "${vnet_key}-${local.firewall_subnet_name}"
      is_default       = ip_config_value.is_default || (alltrue([for ip_config in values(vnet_value.firewall.ip_configurations) : !ip_config.is_default]) && (length(vnet_value.firewall.ip_configurations) == 1 || ip_config_key == "default"))
      name             = ip_config_value.name == null ? ip_config_key : ip_config_value.name
      public_ip_config = ip_config_value.public_ip_config
    } } :
    {
      default = {
        public_ip_key    = vnet_key
        subnet_key       = "${vnet_key}-${local.firewall_subnet_name}"
        is_default       = true
        name             = vnet_value.firewall.default_ip_configuration.name == null ? "default" : vnet_value.firewall.default_ip_configuration.name
        public_ip_config = vnet_value.firewall.default_ip_configuration.public_ip_config
      }
    }
  if vnet_value.firewall != null }
}


locals {
  firewalls = {
    for vnet_name, vnet in var.hub_virtual_networks : vnet_name => {
      name                  = coalesce(vnet.firewall.name, "fw-${vnet_name}")
      sku_name              = vnet.firewall.sku_name
      sku_tier              = vnet.firewall.sku_tier
      subnet_address_prefix = vnet.firewall.subnet_address_prefix
      firewall_policy_id    = try(local.firewall_policy_id[vnet_name], vnet.firewall.firewall_policy_id, null)
      resource_group_name   = local.resource_group_names[vnet_name]
      private_ip_ranges     = vnet.firewall.private_ip_ranges
      tags                  = vnet.firewall.tags
      management_ip_enabled = try(vnet.firewall.management_ip_enabled, true)
      management_ip_configuration = {
        name = try(coalesce(vnet.firewall.management_ip_configuration.name, "defaultMgmt"), "defaultMgmt")
      }
      zones                                      = vnet.firewall.zones
      legacy_list_based_ip_configuration_enabled = try(vnet.firewall.legacy_list_based_ip_configuration_enabled, false)
    } if vnet.firewall != null
  }
  fw_default_ip_configuration_pip = { for public_ip in flatten([
    for vnet_key, vnet_value in local.firewall_merged_ip_configurations : [
      for ip_config_key, ip_config_value in vnet_value : {
        composite_key       = ip_config_value.public_ip_key
        location            = var.hub_virtual_networks[vnet_key].location
        name                = coalesce(try(ip_config_value.public_ip_config.name, null), "pip-fw-${ip_config_value.public_ip_key}")
        resource_group_name = local.resource_group_names[vnet_key]
        ip_version          = try(ip_config_value.public_ip_config.ip_version, "IPv4")
        sku_tier            = try(ip_config_value.public_ip_config.sku_tier, "Regional")
        tags                = var.hub_virtual_networks[vnet_key].firewall.tags
        zones               = try(ip_config_value.public_ip_config.zones, null)
      }
    ]
  ]) : public_ip.composite_key => public_ip }
  fw_management_ip_configuration_pip = {
    for vnet_name, vnet in var.hub_virtual_networks : vnet_name => {
      location            = vnet.location
      name                = coalesce(try(vnet.firewall.management_ip_configuration.public_ip_config.name, null), "pip-fw-mgmt-${vnet_name}")
      resource_group_name = local.resource_group_names[vnet_name]
      ip_version          = try(vnet.firewall.management_ip_configuration.public_ip_config.ip_version, "IPv4")
      sku_tier            = try(vnet.firewall.management_ip_configuration.public_ip_config.sku_tier, "Regional")
      tags                = vnet.firewall.tags
      zones               = try(vnet.firewall.management_ip_configuration.public_ip_config.zones, null)
    } if vnet.firewall != null && try(vnet.firewall.management_ip_enabled, true)
  }
  fw_policies = {
    for vnet_name, vnet in var.hub_virtual_networks : vnet_name => {
      name                              = try(vnet.firewall.firewall_policy.name, "fwp-${vnet_name}")
      location                          = vnet.location
      resource_group_name               = local.resource_group_names[vnet_name]
      sku                               = try(vnet.firewall.firewall_policy.sku, "Standard")
      auto_learn_private_ranges_enabled = try(vnet.firewall.firewall_policy.auto_learn_private_ranges_enabled, null)
      base_policy_id                    = try(vnet.firewall.firewall_policy.base_policy_id, null)
      dns                               = try(vnet.firewall.firewall_policy.dns, null)
      threat_intelligence_allowlist     = try(vnet.firewall.firewall_policy.threat_intelligence_allowlist, null)
      explicit_proxy                    = try(vnet.firewall.firewall_policy.explicit_proxy, null)
      identity                          = try(vnet.firewall.firewall_policy.identity, null)
      insights                          = try(vnet.firewall.firewall_policy.insights, null)
      intrusion_detection               = try(vnet.firewall.firewall_policy.intrusion_detection, null)
      private_ip_ranges                 = try(vnet.firewall.firewall_policy.private_ip_ranges, null)
      sql_redirect_allowed              = try(vnet.firewall.firewall_policy.sql_redirect_allowed, null)
      threat_intelligence_mode          = try(vnet.firewall.firewall_policy.threat_intelligence_mode, null)
      timeouts                          = try(vnet.firewall.firewall_policy.timeouts, null)
      tls_certificate                   = try(vnet.firewall.firewall_policy.tls_certificate, null)
      tags                              = vnet.firewall.tags
    } if vnet.firewall != null && try(vnet.firewall.firewall_policy, null) != null && try(vnet.firewall.firewall_policy_id, null) == null
  }
}
