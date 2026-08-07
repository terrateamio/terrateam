# The following block of locals are used to avoid using
# empty object types in the code.
locals {
  empty_list   = []
  empty_map    = {}
  empty_string = ""
}

# Convert the input vars to locals, applying any required
# logic needed before they are used in the module.
# No vars should be referenced elsewhere in the module.
# NOTE: Need to catch error for resource_suffix when
# no value for subscription_id is provided.
locals {
  enabled                                         = var.enabled
  root_id                                         = var.root_id
  subscription_id                                 = coalesce(var.subscription_id, "00000000-0000-0000-0000-000000000000")
  settings                                        = var.settings
  location                                        = lower(var.location)
  tags                                            = var.tags
  resource_prefix                                 = coalesce(var.resource_prefix, local.root_id)
  resource_suffix                                 = var.resource_suffix != local.empty_string ? "-${var.resource_suffix}" : local.empty_string
  existing_ddos_protection_plan_resource_id       = var.existing_ddos_protection_plan_resource_id
  existing_virtual_wan_resource_id                = var.existing_virtual_wan_resource_id != null ? var.existing_virtual_wan_resource_id : local.empty_string
  existing_virtual_wan_resource_group_name        = var.existing_virtual_wan_resource_group_name != null ? var.existing_virtual_wan_resource_group_name : local.empty_string
  resource_group_per_virtual_hub_location         = var.resource_group_per_virtual_hub_location
  custom_azure_backup_geo_codes                   = var.custom_azure_backup_geo_codes
  custom_privatelink_azurestaticapps_partitionids = var.custom_privatelink_azurestaticapps_partitionids
  custom_settings                                 = var.custom_settings_by_resource_type
}

# Logic to help keep code DRY
locals {
  hub_networks = local.settings.hub_networks
  # We generate the hub_networks_by_location as a map
  # to ensure the user has provided unique values for
  # each hub location. If duplicates are found,
  # terraform will throw an error at this point.
  hub_networks_by_location = {
    for hub_network in local.hub_networks :
    coalesce(lower(hub_network.config.location), local.location) => hub_network
  }
  hub_network_locations = keys(local.hub_networks_by_location)
  virtual_hubs          = local.settings.vwan_hub_networks
  # We generate the virtual_hubs_by_location as a map
  # to ensure the user has provided unique values for
  # each hub location. If duplicates are found,
  # terraform will throw an error at this point.
  # By default we recommend creating all Virtual WAN
  # resources in a single Resource Group as per:
  # https://learn.microsoft.com/en-us/azure/virtual-wan/virtual-wan-faq#can-hubs-be-created-in-different-resource-group-in-virtual-wan
  # As this is only an issue for customers using the
  # Portal to manage Virtual WAN resources, the following
  # logic is used to allow a customer to use dedicated Resource
  # Groups per location if preferred.
  virtual_hubs_by_location = {
    for virtual_hub in local.virtual_hubs :
    coalesce(lower(virtual_hub.config.location), local.location) => virtual_hub
  }
  virtual_hubs_by_location_for_resource_group_per_location = {
    for virtual_hub in local.virtual_hubs :
    coalesce(lower(virtual_hub.config.location), local.location) => virtual_hub
    if local.resource_group_per_virtual_hub_location
  }
  virtual_hubs_by_location_for_shared_resource_group = {
    for virtual_hub in local.virtual_hubs :
    coalesce(lower(virtual_hub.config.location), local.location) => virtual_hub
    if !local.resource_group_per_virtual_hub_location
  }
  # The following objects are used to identify azurerm_virtual_hub
  # resources which need to be associated with a new or existing
  # azurerm_virtual_wan resource
  virtual_hubs_by_location_for_managed_virtual_wan = {
    for virtual_hub in local.virtual_hubs :
    coalesce(lower(virtual_hub.config.location), local.location) => virtual_hub
    if local.existing_virtual_wan_resource_id == local.empty_string
  }
  virtual_hubs_by_location_for_existing_virtual_wan = {
    for virtual_hub in local.virtual_hubs :
    coalesce(lower(virtual_hub.config.location), local.location) => virtual_hub
    if local.existing_virtual_wan_resource_id != local.empty_string
  }
  # Need to know the full list of virtual_hub_locations
  # for azurerm_virtual_hub resource deployments.
  virtual_hub_locations = keys(local.virtual_hubs_by_location)
  # The azurerm_virtual_wan resource will be created in the
  # default location of the connectivity module if a new.
  virtual_wan_locations = anytrue(
    [
      length(local.virtual_hubs_by_location_for_managed_virtual_wan) > 0,
      length(local.virtual_hubs_by_location_for_shared_resource_group) > 0,
    ]
  ) ? [local.location] : local.empty_list
  ddos_location = coalesce(lower(local.settings.ddos_protection_plan.config.location), local.location)
  dns_location  = coalesce(lower(local.settings.dns.config.location), local.location)
  connectivity_locations = distinct(concat(
    local.hub_network_locations,
    keys(local.virtual_hubs_by_location_for_resource_group_per_location),
  ))
  result_when_location_missing = {
    enabled = false
  }
  vpn_gen1_only_skus = [
    "Basic",
    "VpnGw1",
    "VpnGw1AZ",
  ]
  private_ip_address_allocation_values = [
    "Dynamic",
    "Static",
  ]
}

# Logic to determine whether specific resources
# should be created by this module
# - Resource Groups
locals {
  deploy_resource_groups = {
    connectivity = {
      for location in local.connectivity_locations :
      location =>
      local.enabled &&
      anytrue(
        [
          lookup(local.hub_networks_by_location, location, local.result_when_location_missing).enabled,
          lookup(local.virtual_hubs_by_location_for_resource_group_per_location, location, local.result_when_location_missing).enabled,
        ]
      )
    }
    virtual_wan = {
      for location in local.virtual_wan_locations :
      location =>
      local.enabled &&
      local.existing_virtual_wan_resource_group_name == local.empty_string &&
      anytrue(concat(
        values(local.virtual_hubs_by_location_for_managed_virtual_wan).*.enabled,
        values(local.virtual_hubs_by_location_for_shared_resource_group).*.enabled,
      ))
    }
    ddos = {
      (local.ddos_location) = local.deploy_ddos_protection_plan
    }
    dns = {
      (local.dns_location) = local.deploy_dns
    }
  }
}

# Logic to determine whether specific resources
# should be created by this module
# - DDoS Protection Plan
locals {
  deploy_ddos_protection_plan = local.enabled && local.settings.ddos_protection_plan.enabled
}

# Logic to determine whether specific resources
# should be created by this module
# - DNS
locals {
  deploy_dns                                             = local.enabled && local.settings.dns.enabled
  deploy_private_dns_zone_virtual_network_link_on_hubs   = local.deploy_dns && local.settings.dns.config.enable_private_dns_zone_virtual_network_link_on_hubs
  deploy_private_dns_zone_virtual_network_link_on_spokes = local.deploy_dns && local.settings.dns.config.enable_private_dns_zone_virtual_network_link_on_spokes
}

# Logic to determine whether specific resources
# should be created by this module
# - Hub networks
locals {
  deploy_hub_network = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.enabled &&
    hub_network.enabled
  }
  deploy_virtual_network_gateway = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.deploy_hub_network[location] &&
    hub_network.config.virtual_network_gateway.enabled &&
    hub_network.config.virtual_network_gateway.config.address_prefix != local.empty_string
  }
  deploy_virtual_network_gateway_express_route = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.deploy_virtual_network_gateway[location] &&
    hub_network.config.virtual_network_gateway.config.gateway_sku_expressroute != local.empty_string
  }
  deploy_virtual_network_gateway_vpn = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.deploy_virtual_network_gateway[location] &&
    hub_network.config.virtual_network_gateway.config.gateway_sku_vpn != local.empty_string
  }
  deploy_azure_firewall_policy = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.deploy_hub_network[location] &&
    hub_network.config.azure_firewall.enabled &&
    length(try(local.custom_settings.azurerm_firewall["connectivity"][location].firewall_policy_id, local.empty_string)) == 0
  }
  deploy_azure_firewall = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.deploy_hub_network[location] &&
    hub_network.config.azure_firewall.enabled &&
    hub_network.config.azure_firewall.config.address_prefix != local.empty_string
  }
  deploy_outbound_virtual_network_peering = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.deploy_hub_network[location] &&
    hub_network.config.enable_outbound_virtual_network_peering
  }
  deploy_hub_virtual_network_mesh_peering = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    local.deploy_hub_network[location] &&
    hub_network.config.enable_hub_network_mesh_peering
  }
}

# Logic to determine whether specific resources
# should be created by this module
# - VWAN hub networks
locals {
  deploy_virtual_wan = {
    (local.location) = (
      local.enabled &&
      local.existing_virtual_wan_resource_id == local.empty_string &&
      anytrue(values(local.deploy_virtual_hub))
    )
  }
  deploy_virtual_hub = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    local.enabled &&
    virtual_hub.enabled
  }

  deploy_virtual_hub_routing_intent = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    local.deploy_virtual_hub[location] &&
    virtual_hub.config.routing_intent.enabled
  }

  deploy_virtual_hub_express_route_gateway = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    local.deploy_virtual_hub[location] &&
    virtual_hub.config.expressroute_gateway.enabled
  }
  deploy_virtual_hub_vpn_gateway = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    local.deploy_virtual_hub[location] &&
    virtual_hub.config.vpn_gateway.enabled
  }
  deploy_virtual_hub_azure_firewall_policy = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    local.deploy_virtual_hub[location] &&
    virtual_hub.config.azure_firewall.enabled &&
    length(try(local.custom_settings.azurerm_firewall["virtual_wan"][location].firewall_policy_id, local.empty_string)) == 0
  }
  deploy_virtual_hub_azure_firewall = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    local.deploy_virtual_hub[location] &&
    virtual_hub.config.azure_firewall.enabled
  }
  deploy_virtual_hub_connection = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    local.deploy_virtual_hub[location] &&
    virtual_hub.config.enable_virtual_hub_connections
  }
}

# Configuration settings for resource type:
#  - azurerm_resource_group
locals {
  # Determine the name of each Resource Group per scope and location
  resource_group_names_by_scope_and_location = {
    connectivity = {
      for location in local.connectivity_locations :
      location =>
      try(local.custom_settings.azurerm_resource_group["connectivity"][location].name,
      "${local.resource_prefix}-connectivity-${location}${local.resource_suffix}")
    }
    virtual_wan = {
      for location in local.virtual_wan_locations :
      location =>
      coalesce(
        try(local.custom_settings.azurerm_resource_group["virtual_wan"][location].name, null),
        local.existing_virtual_wan_resource_group_name,
        "${local.resource_prefix}-connectivity${local.resource_suffix}"
      )
    }
    ddos = {
      (local.ddos_location) = try(local.custom_settings.azurerm_resource_group["ddos"][local.ddos_location].name,
      "${local.resource_prefix}-ddos${local.resource_suffix}")
    }
    dns = {
      (local.dns_location) = try(local.custom_settings.azurerm_resource_group["dns"][local.dns_location].name,
      "${local.resource_prefix}-dns${local.resource_suffix}")
    }
  }
  # Generate a map of settings for each Resource Group per scope and location
  resource_group_config_by_scope_and_location = {
    for scope, resource_groups in local.resource_group_names_by_scope_and_location :
    scope => {
      for location, name in resource_groups :
      location => {
        # Resource logic attributes
        resource_id = "/subscriptions/${local.subscription_id}/resourceGroups/${name}"
        scope       = scope
        # Resource definition attributes
        name     = name
        location = location
        tags     = try(local.custom_settings.azurerm_resource_group[scope][location].tags, local.tags)
      }
    }
  }
  # Create a flattened list of resource group configuration blocks for deployment
  azurerm_resource_group = flatten([
    for scope in keys(local.resource_group_config_by_scope_and_location) :
    [
      for config in local.resource_group_config_by_scope_and_location[scope] :
      config
    ]
  ])
}

# # Configuration settings for resource type:
# #  - azurerm_network_ddos_protection_plan
locals {
  ddos_resource_group_id = local.resource_group_config_by_scope_and_location["ddos"][local.ddos_location].resource_id
  ddos_protection_plan_name = try(local.custom_settings.azurerm_network_ddos_protection_plan["ddos"][local.ddos_location].name,
  "${local.resource_prefix}-ddos-${local.ddos_location}${local.resource_suffix}")
  ddos_protection_plan_resource_id = coalesce(
    local.existing_ddos_protection_plan_resource_id,
    "${local.ddos_resource_group_id}/providers/Microsoft.Network/ddosProtectionPlans/${local.ddos_protection_plan_name}"
  )
  azurerm_network_ddos_protection_plan = [
    {
      # Resource logic attributes
      resource_id       = local.ddos_protection_plan_resource_id
      managed_by_module = local.deploy_ddos_protection_plan
      # Resource definition attributes
      name                = local.ddos_protection_plan_name
      location            = local.ddos_location
      resource_group_name = local.resource_group_config_by_scope_and_location["ddos"][local.ddos_location].name
      tags                = try(local.custom_settings.azurerm_network_ddos_protection_plan["ddos"][local.ddos_location].tags, local.tags)
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_virtual_network
locals {
  virtual_network_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_virtual_network["connectivity"][location].name,
    "${local.resource_prefix}-hub-${location}${local.resource_suffix}")
  }
  virtual_network_resource_group_id = {
    for location in local.hub_network_locations :
    location =>
    local.resource_group_config_by_scope_and_location["connectivity"][location].resource_id
  }
  virtual_network_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/virtualNetworks"
  }
  virtual_network_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_id_prefix[location]}/${local.virtual_network_name[location]}"
  }
  azurerm_virtual_network = [
    for location, hub_config in local.hub_networks_by_location :
    {
      # Resource logic attributes
      resource_id = local.virtual_network_resource_id[location]
      # Resource definition attributes
      name                = local.virtual_network_name[location]
      resource_group_name = local.resource_group_names_by_scope_and_location["connectivity"][location]
      address_space       = hub_config.config.address_space
      location            = location
      bgp_community       = hub_config.config.bgp_community != local.empty_string ? hub_config.config.bgp_community : null
      dns_servers         = hub_config.config.dns_servers
      tags                = try(local.custom_settings.azurerm_virtual_network["connectivity"][location].tags, local.tags)
      ddos_protection_plan = hub_config.config.link_to_ddos_protection_plan ? [
        {
          id     = local.ddos_protection_plan_resource_id
          enable = true
        }
      ] : local.empty_list
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_subnet
locals {
  subnets_by_virtual_network = {
    for location, hub_network in local.hub_networks_by_location :
    local.virtual_network_resource_id[location] => concat(
      # Get customer specified subnets and add additional required attributes
      [
        for subnet in hub_network.config.subnets : merge(
          subnet,
          {
            # Resource logic attributes
            resource_id = "${local.virtual_network_resource_id[location]}/subnets/${subnet.name}"
            location    = location
            # Resource definition attributes
            resource_group_name                           = local.resource_group_names_by_scope_and_location["connectivity"][location]
            virtual_network_name                          = local.virtual_network_name[location]
            private_link_service_network_policies_enabled = try(local.custom_settings.azurerm_subnet["connectivity"][location][subnet.name].private_link_service_network_policies_enabled, null)
            service_endpoints                             = try(local.custom_settings.azurerm_subnet["connectivity"][location][subnet.name].service_endpoints, null)
            service_endpoint_policy_ids                   = try(local.custom_settings.azurerm_subnet["connectivity"][location][subnet.name].service_endpoint_policy_ids, null)
            delegation                                    = try(local.custom_settings.azurerm_subnet["connectivity"][location][subnet.name].delegation, local.empty_list)
          }
        )
      ],
      # Conditionally add Virtual Network Gateway subnet
      local.deploy_virtual_network_gateway[location] ? [
        {
          # Resource logic attributes
          resource_id               = "${local.virtual_network_resource_id[location]}/subnets/GatewaySubnet"
          location                  = location
          network_security_group_id = null
          route_table_id            = null
          # Resource definition attributes
          name                                          = "GatewaySubnet"
          address_prefixes                              = [hub_network.config.virtual_network_gateway.config.address_prefix, ]
          resource_group_name                           = local.resource_group_names_by_scope_and_location["connectivity"][location]
          virtual_network_name                          = local.virtual_network_name[location]
          private_link_service_network_policies_enabled = try(local.custom_settings.azurerm_subnet["connectivity"][location]["GatewaySubnet"].private_link_service_network_policies_enabled, null)
          service_endpoints                             = try(local.custom_settings.azurerm_subnet["connectivity"][location]["GatewaySubnet"].service_endpoints, null)
          service_endpoint_policy_ids                   = try(local.custom_settings.azurerm_subnet["connectivity"][location]["GatewaySubnet"].service_endpoint_policy_ids, null)
          delegation                                    = try(local.custom_settings.azurerm_subnet["connectivity"][location]["GatewaySubnet"].delegation, local.empty_list)
        }
      ] : local.empty_list,
      # Conditionally add Azure Firewall subnet
      local.deploy_azure_firewall[location] ? [
        {
          # Resource logic attributes
          resource_id               = "${local.virtual_network_resource_id[location]}/subnets/AzureFirewallSubnet"
          location                  = location
          network_security_group_id = null
          route_table_id            = null
          # Resource definition attributes
          name                                          = "AzureFirewallSubnet"
          address_prefixes                              = [hub_network.config.azure_firewall.config.address_prefix, ]
          resource_group_name                           = local.resource_group_names_by_scope_and_location["connectivity"][location]
          virtual_network_name                          = local.virtual_network_name[location]
          private_link_service_network_policies_enabled = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallSubnet"].private_link_service_network_policies_enabled, null)
          service_endpoints                             = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallSubnet"].service_endpoints, null)
          service_endpoint_policy_ids                   = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallSubnet"].service_endpoint_policy_ids, null)
          delegation                                    = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallSubnet"].delegation, local.empty_list)
        }
      ] : local.empty_list,
      # Conditionally add Azure Firewall Management Subnet
      local.deploy_azure_firewall[location] && local.hub_networks_by_location[location].config.azure_firewall.config.address_management_prefix != "" ? [
        {
          # Resource logic attributes
          resource_id               = "${local.virtual_network_resource_id[location]}/subnets/AzureFirewallManagementSubnet"
          location                  = location
          network_security_group_id = null
          route_table_id            = null
          # Resource definition attributes
          name                                          = "AzureFirewallManagementSubnet"
          address_prefixes                              = [hub_network.config.azure_firewall.config.address_management_prefix, ]
          resource_group_name                           = local.resource_group_names_by_scope_and_location["connectivity"][location]
          virtual_network_name                          = local.virtual_network_name[location]
          private_link_service_network_policies_enabled = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallManagementSubnet"].private_link_service_network_policies_enabled, null)
          service_endpoints                             = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallManagementSubnet"].service_endpoints, null)
          service_endpoint_policy_ids                   = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallManagementSubnet"].service_endpoint_policy_ids, null)
          delegation                                    = try(local.custom_settings.azurerm_subnet["connectivity"][location]["AzureFirewallManagementSubnet"].delegation, local.empty_list)
        }
      ] : local.empty_list,

    )
  }
  azurerm_subnet = flatten([
    for subnets in local.subnets_by_virtual_network :
    subnets
  ])
}

# Configuration settings for resource type:
#  - azurerm_virtual_network_gateway (ExpressRoute)
locals {
  er_gateway_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_expressroute"][location].name,
    "${local.resource_prefix}-ergw-${location}${local.resource_suffix}")
  }
  er_gateway_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/virtualNetworkGateways"
  }
  er_gateway_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.er_gateway_resource_id_prefix[location]}/${local.er_gateway_name[location]}"
  }
  er_gateway_pip_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].name,
    "${local.er_gateway_name[location]}-pip")
  }
  er_gateway_pip_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/publicIPAddresses"
  }
  er_gateway_pip_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.er_gateway_pip_resource_id_prefix[location]}/${local.er_gateway_pip_name[location]}"
  }
  azurerm_virtual_network_gateway_express_route = [
    for location, hub_network in local.hub_networks_by_location :
    {
      # Resource logic attributes
      resource_id       = local.er_gateway_resource_id[location]
      managed_by_module = local.deploy_virtual_network_gateway_express_route[location]
      # Resource definition attributes
      name                        = local.er_gateway_name[location]
      resource_group_name         = local.resource_group_names_by_scope_and_location["connectivity"][location]
      location                    = location
      type                        = "ExpressRoute"
      sku                         = hub_network.config.virtual_network_gateway.config.gateway_sku_expressroute
      remote_vnet_traffic_enabled = hub_network.config.virtual_network_gateway.config.remote_vnet_traffic_enabled
      virtual_wan_traffic_enabled = hub_network.config.virtual_network_gateway.config.virtual_wan_traffic_enabled
      ip_configuration = try(
        # To support `active_active = true` must currently specify a custom ip_configuration
        local.custom_settings.azurerm_virtual_network_gateway["connectivity_expressroute"][location].ip_configuration,
        [
          {
            name                          = local.er_gateway_pip_name[location]
            private_ip_address_allocation = null # Not applicable to ExpressRoute SKUs
            subnet_id                     = "${local.virtual_network_resource_id[location]}/subnets/GatewaySubnet"
            public_ip_address_id          = local.er_gateway_pip_resource_id[location]
          }
        ]
      )
      vpn_type                         = try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_expressroute"][location].vpn_type, "RouteBased")
      enable_bgp                       = null             # Not applicable to ExpressRoute SKUs
      active_active                    = null             # Not applicable to ExpressRoute SKUs
      private_ip_address_enabled       = null             # Not applicable to ExpressRoute SKUs
      default_local_network_gateway_id = null             # Not applicable to ExpressRoute SKUs
      generation                       = null             # Not applicable to ExpressRoute SKUs
      vpn_client_configuration         = local.empty_list # Not applicable to ExpressRoute SKUs
      bgp_settings                     = local.empty_list # Not applicable to ExpressRoute SKUs
      custom_route                     = local.empty_list # Not applicable to ExpressRoute SKUs
      tags                             = try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_expressroute"][location].tags, local.tags)
      # Child resource definition attributes
      azurerm_public_ip = (
        # The following logic ensures that no `azurerm_public_ip` is created by the module if a custom `ip_configuration` is provided
        length(try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_expressroute"][location].ip_configuration, local.empty_map)) > 0
        ? local.empty_list
        : [{
          # Resource logic attributes
          resource_id       = local.er_gateway_pip_resource_id[location]
          managed_by_module = local.deploy_virtual_network_gateway_express_route[location]
          # Resource definition attributes
          name                    = local.er_gateway_pip_name[location]
          resource_group_name     = local.resource_group_names_by_scope_and_location["connectivity"][location]
          location                = location
          sku                     = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].sku, "Standard")
          ip_version              = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].ip_version, null)
          idle_timeout_in_minutes = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].idle_timeout_in_minutes, null)
          domain_name_label       = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].domain_name_label, null)
          reverse_fqdn            = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].reverse_fqdn, null)
          public_ip_prefix_id     = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].public_ip_prefix_id, null)
          ip_tags                 = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].ip_tags, null)
          tags                    = try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].tags, local.tags)
          allocation_method = try(
            local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].allocation_method,
            try(local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].sku, "Standard") == "Standard" ? "Static" : "Dynamic"
          )
          zones = try(
            local.custom_settings.azurerm_public_ip["connectivity_expressroute"][location].zones,
            length(regexall("AZ$", hub_network.config.virtual_network_gateway.config.gateway_sku_expressroute)) > 0 ? ["1", "2", "3"] : local.empty_list
          )
        }]
      )
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_virtual_network_gateway (VPN)
locals {
  vpn_gateway_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_vpn"][location].name,
    "${local.resource_prefix}-vpngw-${location}${local.resource_suffix}")
  }
  vpn_gateway_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/virtualNetworkGateways"
  }
  vpn_gateway_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.vpn_gateway_resource_id_prefix[location]}/${local.vpn_gateway_name[location]}"
  }
  vpn_gateway_pip_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].name,
    "${local.vpn_gateway_name[location]}-pip")
  }
  vpn_gateway_pip_2_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].name,
    "${local.vpn_gateway_name[location]}-pip2")
  }
  vpn_gateway_pip_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/publicIPAddresses"
  }
  vpn_gateway_pip_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.vpn_gateway_pip_resource_id_prefix[location]}/${local.vpn_gateway_pip_name[location]}"
  }
  vpn_gateway_pip_2_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.vpn_gateway_pip_resource_id_prefix[location]}/${local.vpn_gateway_pip_2_name[location]}"
  }
  azurerm_virtual_network_gateway_vpn = [
    for location, hub_network in local.hub_networks_by_location :
    {
      # Resource logic attributes
      resource_id       = local.vpn_gateway_resource_id[location]
      managed_by_module = local.deploy_virtual_network_gateway_vpn[location]
      # Resource definition attributes
      name                        = local.vpn_gateway_name[location]
      resource_group_name         = local.resource_group_names_by_scope_and_location["connectivity"][location]
      location                    = location
      type                        = "Vpn"
      sku                         = hub_network.config.virtual_network_gateway.config.gateway_sku_vpn
      remote_vnet_traffic_enabled = null
      virtual_wan_traffic_enabled = null
      ip_configuration = try(
        local.custom_settings.azurerm_virtual_network_gateway["connectivity_vpn"][location].ip_configuration,
        concat(
          [
            {
              name = local.vpn_gateway_pip_name[location]
              private_ip_address_allocation = (
                contains(
                  local.private_ip_address_allocation_values,
                  hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.private_ip_address_allocation
                )
                ? hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.private_ip_address_allocation
                : null
              )
              subnet_id            = "${local.virtual_network_resource_id[location]}/subnets/GatewaySubnet"
              public_ip_address_id = local.vpn_gateway_pip_resource_id[location]
            }
          ],
          (
            coalesce(hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.active_active, false)
            ? [
              {
                name = local.vpn_gateway_pip_2_name[location]
                private_ip_address_allocation = (
                  contains(
                    local.private_ip_address_allocation_values,
                    hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.private_ip_address_allocation
                  )
                  ? hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.private_ip_address_allocation
                  : null
                )
                subnet_id            = "${local.virtual_network_resource_id[location]}/subnets/GatewaySubnet"
                public_ip_address_id = local.vpn_gateway_pip_2_resource_id[location]
              }
            ]
            : local.empty_list
          )
        )
      )
      vpn_type      = try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_vpn"][location].vpn_type, "RouteBased")
      enable_bgp    = lower(hub_network.config.virtual_network_gateway.config.gateway_sku_vpn) == "basic" ? null : coalesce(hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.enable_bgp, false)
      active_active = coalesce(hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.active_active, false)
      private_ip_address_enabled = (
        contains(
          local.private_ip_address_allocation_values,
          hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.private_ip_address_allocation
        )
        ? true
        : null
      )
      default_local_network_gateway_id = (
        hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.default_local_network_gateway_id != local.empty_string
        ? hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.default_local_network_gateway_id
        : null
      )
      generation = try(
        local.custom_settings.azurerm_virtual_network_gateway["connectivity_vpn"][location].generation,
        contains(local.vpn_gen1_only_skus, hub_network.config.virtual_network_gateway.config.gateway_sku_vpn) ? "Generation1" : "Generation2"
      )
      vpn_client_configuration = hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.vpn_client_configuration
      bgp_settings             = hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.bgp_settings
      custom_route             = hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.custom_route
      tags                     = try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_vpn"][location].tags, local.tags)
      # Child resource definition attributes
      azurerm_public_ip = (
        # The following logic ensures that no `azurerm_public_ip` is created by the module if a custom `ip_configuration` is provided
        length(try(local.custom_settings.azurerm_virtual_network_gateway["connectivity_vpn"][location].ip_configuration, local.empty_map)) > 0
        ? local.empty_list
        : concat(
          [
            {
              # Resource logic attributes
              resource_id       = local.vpn_gateway_pip_resource_id[location]
              managed_by_module = local.deploy_virtual_network_gateway_vpn[location]
              # Resource definition attributes
              name                    = local.vpn_gateway_pip_name[location]
              resource_group_name     = local.resource_group_names_by_scope_and_location["connectivity"][location]
              location                = location
              ip_version              = try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].ip_version, null)
              idle_timeout_in_minutes = try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].idle_timeout_in_minutes, null)
              domain_name_label       = try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].domain_name_label, null)
              reverse_fqdn            = try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].reverse_fqdn, null)
              public_ip_prefix_id     = try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].public_ip_prefix_id, null)
              ip_tags                 = try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].ip_tags, null)
              tags                    = try(local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].tags, local.tags)
              sku = try(
                local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].sku,
                length(regexall("AZ$", hub_network.config.virtual_network_gateway.config.gateway_sku_vpn)) > 0 ? "Standard" : "Basic"
              )
              allocation_method = try(
                local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].allocation_method,
                length(regexall("AZ$", hub_network.config.virtual_network_gateway.config.gateway_sku_vpn)) > 0 ? "Static" : "Dynamic"
              )
              zones = try(
                local.custom_settings.azurerm_public_ip["connectivity_vpn"][location].zones,
                length(regexall("AZ$", hub_network.config.virtual_network_gateway.config.gateway_sku_vpn)) > 0 ? ["1", "2", "3"] : local.empty_list
              )
            }
          ],
          (
            coalesce(hub_network.config.virtual_network_gateway.config.advanced_vpn_settings.active_active, false)
            ? [
              {
                # Resource logic attributes
                resource_id       = local.vpn_gateway_pip_2_resource_id[location]
                managed_by_module = local.deploy_virtual_network_gateway_vpn[location]
                # Resource definition attributes
                name                    = local.vpn_gateway_pip_2_name[location]
                resource_group_name     = local.resource_group_names_by_scope_and_location["connectivity"][location]
                location                = location
                ip_version              = try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].ip_version, null)
                idle_timeout_in_minutes = try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].idle_timeout_in_minutes, null)
                domain_name_label       = try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].domain_name_label, null)
                reverse_fqdn            = try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].reverse_fqdn, null)
                public_ip_prefix_id     = try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].public_ip_prefix_id, null)
                ip_tags                 = try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].ip_tags, null)
                tags                    = try(local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].tags, local.tags)
                sku = try(
                  local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].sku,
                  length(regexall("AZ$", hub_network.config.virtual_network_gateway.config.gateway_sku_vpn)) > 0 ? "Standard" : "Basic"
                )
                allocation_method = try(
                  local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].allocation_method,
                  length(regexall("AZ$", hub_network.config.virtual_network_gateway.config.gateway_sku_vpn)) > 0 ? "Static" : "Dynamic"
                )
                zones = try(
                  local.custom_settings.azurerm_public_ip["connectivity_vpn_2"][location].zones,
                  length(regexall("AZ$", hub_network.config.virtual_network_gateway.config.gateway_sku_vpn)) > 0 ? ["1", "2", "3"] : local.empty_list
                )
            }]
            : local.empty_list
          )
        )
      )
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_virtual_network_gateway
locals {
  azurerm_virtual_network_gateway = concat(
    local.azurerm_virtual_network_gateway_express_route,
    local.azurerm_virtual_network_gateway_vpn,
  )
}

# Configuration settings for resource type:
#  - azurerm_firewall
# For VWAN, VPN gateway is required for Security Partner Provider integration
# For zonal deployments, the public IP must be either single-zone, or all-zones (see #447 for more information)
locals {
  azfw_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_firewall["connectivity"][location].name,
    "${local.resource_prefix}-fw-${location}${local.resource_suffix}")
  }
  azfw_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/azureFirewalls"
  }
  azfw_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.azfw_resource_id_prefix[location]}/${local.azfw_name[location]}"
  }
  azfw_zones = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    flatten(
      [
        hub_network.config.azure_firewall.config.availability_zones.zone_1 ? ["1"] : local.empty_list,
        hub_network.config.azure_firewall.config.availability_zones.zone_2 ? ["2"] : local.empty_list,
        hub_network.config.azure_firewall.config.availability_zones.zone_3 ? ["3"] : local.empty_list,
      ]
    )
  }
  azfw_zones_enabled = {
    for location, hub_network in local.hub_networks_by_location :
    location =>
    length(local.azfw_zones[location]) > 0
  }
  azfw_policy_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_firewall_policy["connectivity"][location].name,
    "${local.azfw_name[location]}-policy")
  }
  azfw_policy_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/firewallPolicies"
  }
  azfw_policy_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.azfw_policy_resource_id_prefix[location]}/${local.azfw_policy_name[location]}"
  }
  azfw_pip_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].name,
    "${local.azfw_name[location]}-pip")
  }
  azfw_mgmt_pip_name = {
    for location in local.hub_network_locations :
    location =>
    try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_name,
    "${local.azfw_name[location]}-mgmt-pip")
  }
  azfw_pip_resource_id_prefix = {
    for location in local.hub_network_locations :
    location =>
    "${local.virtual_network_resource_group_id[location]}/providers/Microsoft.Network/publicIPAddresses"
  }
  azfw_pip_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.azfw_pip_resource_id_prefix[location]}/${local.azfw_pip_name[location]}"
  }
  azfw_mgmt_pip_resource_id = {
    for location in local.hub_network_locations :
    location =>
    "${local.azfw_pip_resource_id_prefix[location]}/${local.azfw_mgmt_pip_name[location]}"
  }
  azfw_pip_zones = {
    for location in local.hub_network_locations :
    location =>
    try(
      local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].zones,
      length(local.azfw_zones[location]) == 1 ?
      local.azfw_zones[location] :
      length(local.azfw_zones[location]) >= 2 ?
      ["1", "2", "3"] :
      null
    )
  }
  azfw_mgmt_pip_zones = {
    for location in local.hub_network_locations :
    location =>
    try(
      local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_zones,
      length(local.azfw_zones[location]) == 1 ?
      local.azfw_zones[location] :
      length(local.azfw_zones[location]) >= 2 ?
      ["1", "2", "3"] :
      null
    )
  }
  virtual_hub_azfw_name = {
    for location in local.virtual_hub_locations :
    location =>
    try(local.custom_settings.azurerm_firewall["virtual_wan"][location].name,
    "${local.resource_prefix}-fw-hub-${location}${local.resource_suffix}")
  }
  virtual_hub_azfw_resource_id_prefix = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_resource_group_id[location]}/providers/Microsoft.Network/azureFirewalls"
  }
  virtual_hub_azfw_resource_id = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_azfw_resource_id_prefix[location]}/${local.virtual_hub_azfw_name[location]}"
  }
  virtual_hub_azfw_policy_name = {
    for location in local.virtual_hub_locations :
    location =>
    try(local.custom_settings.azurerm_firewall_policy["virtual_wan"][location].name,
    "${local.virtual_hub_azfw_name[location]}-policy")
  }
  virtual_hub_azfw_policy_resource_id_prefix = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_resource_group_id[location]}/providers/Microsoft.Network/firewallPolicies"
  }
  virtual_hub_azfw_policy_resource_id = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_azfw_policy_resource_id_prefix[location]}/${local.virtual_hub_azfw_policy_name[location]}"
  }
  virtual_hub_azfw_zones = {
    for location, virtual_hub in local.virtual_hubs_by_location :
    location =>
    flatten(
      [
        virtual_hub.config.azure_firewall.config.availability_zones.zone_1 ? ["1"] : local.empty_list,
        virtual_hub.config.azure_firewall.config.availability_zones.zone_2 ? ["2"] : local.empty_list,
        virtual_hub.config.azure_firewall.config.availability_zones.zone_3 ? ["3"] : local.empty_list,
      ]
    )
  }
  azurerm_firewall = concat(
    [
      for location, hub_network in local.hub_networks_by_location :
      {
        # Resource logic attributes
        resource_id       = local.azfw_resource_id[location]
        managed_by_module = local.deploy_azure_firewall[location]
        scope             = "connectivity"
        # Resource definition attributes
        name                = local.azfw_name[location]
        resource_group_name = local.resource_group_names_by_scope_and_location["connectivity"][location]
        location            = location
        ip_configuration = try(
          local.custom_settings.azurerm_firewall["connectivity"][location].ip_configuration,
          [
            {
              name                 = local.azfw_pip_name[location]
              public_ip_address_id = local.azfw_pip_resource_id[location]
              subnet_id            = "${local.virtual_network_resource_id[location]}/subnets/AzureFirewallSubnet"
            }
          ]
        )
        sku_name = "AZFW_VNet"
        sku_tier = coalesce(
          # The following `try()` is needed to avoid breaking changes for anyone
          # already setting this value via the advanced configuration block.
          try(local.custom_settings.azurerm_firewall["connectivity"][location].sku_tier, null),
          hub_network.config.azure_firewall.config.sku_tier,
          "Standard"
        )
        firewall_policy_id = try(local.custom_settings.azurerm_firewall["connectivity"][location].firewall_policy_id, local.azfw_policy_resource_id[location])
        dns_servers        = try(local.custom_settings.azurerm_firewall["connectivity"][location].dns_servers, null)
        private_ip_ranges  = try(local.custom_settings.azurerm_firewall["connectivity"][location].private_ip_ranges, null)
        management_ip_configuration = try(local.custom_settings.azurerm_firewall["connectivity"][location].management_ip_configuration,
          hub_network.config.azure_firewall.config.address_management_prefix != "" ?
          [
            {
              name                 = local.azfw_mgmt_pip_name[location]
              public_ip_address_id = local.azfw_mgmt_pip_resource_id[location]
              subnet_id            = "${local.virtual_network_resource_id[location]}/subnets/AzureFirewallManagementSubnet"
            }
          ] : local.empty_list
        )
        threat_intel_mode = try(local.custom_settings.azurerm_firewall["connectivity"][location].threat_intel_mode, coalesce(hub_network.config.azure_firewall.config.threat_intelligence_mode, "Alert"))
        virtual_hub       = local.empty_list
        zones             = try(local.custom_settings.azurerm_firewall["connectivity"][location].zones, local.azfw_zones[location])
        tags              = try(local.custom_settings.azurerm_firewall["connectivity"][location].tags, local.tags)
        # Associated resource definition attributes
        azurerm_firewall_policy = {
          # Resource logic attributes
          resource_id       = local.azfw_policy_resource_id[location]
          managed_by_module = local.deploy_azure_firewall_policy[location]
          scope             = "connectivity"
          # Resource definition attributes
          name                = local.azfw_policy_name[location]
          resource_group_name = local.resource_group_names_by_scope_and_location["connectivity"][location]
          location            = location
          # Optional definition attributes
          base_policy_id                = length(hub_network.config.azure_firewall.config.base_policy_id) > 0 ? hub_network.config.azure_firewall.config.base_policy_id : null
          private_ip_ranges             = length(hub_network.config.azure_firewall.config.private_ip_ranges) > 0 ? hub_network.config.azure_firewall.config.private_ip_ranges : null
          sku                           = coalesce(hub_network.config.azure_firewall.config.sku_tier, "Standard")
          threat_intelligence_mode      = coalesce(hub_network.config.azure_firewall.config.threat_intelligence_mode, "Alert")
          threat_intelligence_allowlist = hub_network.config.azure_firewall.config.threat_intelligence_allowlist
          dns = try(
            local.custom_settings.azurerm_firewall_policy["connectivity"][location].dns,
            (
              hub_network.config.azure_firewall.config.sku_tier == "Basic" ? local.empty_list :
              [
                {
                  proxy_enabled = hub_network.config.azure_firewall.config.enable_dns_proxy
                  servers       = length(hub_network.config.azure_firewall.config.dns_servers) > 0 ? hub_network.config.azure_firewall.config.dns_servers : null
                }
              ]
            )
          )
          identity             = try(local.custom_settings.azurerm_firewall_policy["connectivity"][location].identity, local.empty_list)
          insights             = try(local.custom_settings.azurerm_firewall_policy["connectivity"][location].insights, local.empty_list)
          intrusion_detection  = try(local.custom_settings.azurerm_firewall_policy["connectivity"][location].intrusion_detection, local.empty_list)
          tls_certificate      = try(local.custom_settings.azurerm_firewall_policy["connectivity"][location].tls_certificate, local.empty_list)
          sql_redirect_allowed = try(local.custom_settings.azurerm_firewall_policy["connectivity"][location].sql_redirect_allowed, null)
          tags                 = try(local.custom_settings.azurerm_firewall_policy["connectivity"][location].tags, local.tags)
        }
        # Child resource definition attributes
        azurerm_public_ip = (
          # The following logic ensures that no `azurerm_public_ip` is created by the module if a custom `ip_configuration` or `management_ip_configuration` is provided.
          concat(
            length(try(local.custom_settings.azurerm_firewall["connectivity"][location].ip_configuration, local.empty_map)) > 0
            ? local.empty_list
            : [{
              # Resource logic attributes
              resource_id       = local.azfw_pip_resource_id[location]
              managed_by_module = local.deploy_azure_firewall[location]
              # Resource definition attributes
              name                    = local.azfw_pip_name[location]
              resource_group_name     = local.resource_group_names_by_scope_and_location["connectivity"][location]
              location                = location
              zones                   = local.azfw_pip_zones[location]
              sku                     = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].sku, "Standard")
              allocation_method       = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].allocation_method, "Static")
              ip_version              = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].ip_version, null)
              idle_timeout_in_minutes = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].idle_timeout_in_minutes, null)
              domain_name_label       = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].domain_name_label, null)
              reverse_fqdn            = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].reverse_fqdn, null)
              public_ip_prefix_id     = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].public_ip_prefix_id, null)
              ip_tags                 = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].ip_tags, null)
              tags                    = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].tags, local.tags)
            }],
            (
              length(try(local.custom_settings.azurerm_firewall["connectivity"][location].management_ip_configuration, local.empty_map)) > 0
              ? local.empty_list
              : [{
                # Resource logic attributes
                resource_id       = local.azfw_mgmt_pip_resource_id[location]
                managed_by_module = local.deploy_azure_firewall[location] && local.hub_networks_by_location[location].config.azure_firewall.config.address_management_prefix != ""
                # Resource definition attributes
                name                    = local.azfw_mgmt_pip_name[location]
                resource_group_name     = local.resource_group_names_by_scope_and_location["connectivity"][location]
                location                = location
                zones                   = local.azfw_mgmt_pip_zones[location]
                sku                     = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_sku, "Standard")
                allocation_method       = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_allocation_method, "Static")
                ip_version              = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_ip_version, null)
                idle_timeout_in_minutes = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_idle_timeout_in_minutes, null)
                domain_name_label       = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_domain_name_label, null)
                reverse_fqdn            = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_reverse_fqdn, null)
                public_ip_prefix_id     = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_public_ip_prefix_id, null)
                ip_tags                 = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_ip_tags, null)
                tags                    = try(local.custom_settings.azurerm_public_ip["connectivity_firewall"][location].mgmt_tags, local.tags)
              }]
            )
          )
        )
      }
    ],
    [
      for location, virtual_hub in local.virtual_hubs_by_location :
      {
        # Resource logic attributes
        resource_id       = local.virtual_hub_azfw_resource_id[location]
        managed_by_module = local.deploy_virtual_hub_azure_firewall[location]
        scope             = "virtual_wan"
        # Resource definition attributes
        name                = local.virtual_hub_azfw_name[location]
        resource_group_name = local.virtual_hub_resource_group_name[location]
        location            = location
        ip_configuration    = local.empty_list # Not applicable to AZFW_Hub SKU
        sku_name            = "AZFW_Hub"
        sku_tier = coalesce(
          virtual_hub.config.azure_firewall.config.sku_tier,
          "Standard"
        )
        firewall_policy_id          = try(local.custom_settings.azurerm_firewall["virtual_wan"][location].firewall_policy_id, local.virtual_hub_azfw_policy_resource_id[location])
        dns_servers                 = try(local.custom_settings.azurerm_firewall["virtual_wan"][location].dns_servers, null)
        private_ip_ranges           = try(local.custom_settings.azurerm_firewall["virtual_wan"][location].private_ip_ranges, null)
        management_ip_configuration = try(local.custom_settings.azurerm_firewall["virtual_wan"][location].management_ip_configuration, local.empty_list)
        threat_intel_mode           = null # Not applicable to AZFW_Hub SKU
        virtual_hub = [
          {
            virtual_hub_id  = local.virtual_hub_resource_id[location]
            public_ip_count = try(local.custom_settings.azurerm_firewall["virtual_wan"][location].virtual_hub[0].public_ip_count, 1)
          }
        ]
        zones = try(local.custom_settings.azurerm_firewall["virtual_wan"][location].zones, local.virtual_hub_azfw_zones[location])
        tags  = try(local.custom_settings.azurerm_firewall["virtual_wan"][location].tags, local.tags)
        # Associated resource definition attributes
        azurerm_firewall_policy = {
          # Resource logic attributes
          resource_id       = local.virtual_hub_azfw_policy_resource_id[location]
          managed_by_module = local.deploy_virtual_hub_azure_firewall_policy[location]
          scope             = "virtual_wan"
          # Resource definition attributes
          name                = local.virtual_hub_azfw_policy_name[location]
          resource_group_name = local.virtual_hub_resource_group_name[location]
          location            = location
          # Optional definition attributes
          base_policy_id                = length(virtual_hub.config.azure_firewall.config.base_policy_id) > 0 ? virtual_hub.config.azure_firewall.config.base_policy_id : null
          private_ip_ranges             = length(virtual_hub.config.azure_firewall.config.private_ip_ranges) > 0 ? virtual_hub.config.azure_firewall.config.private_ip_ranges : null
          sku                           = coalesce(virtual_hub.config.azure_firewall.config.sku_tier, "Standard")
          threat_intelligence_mode      = coalesce(virtual_hub.config.azure_firewall.config.threat_intelligence_mode, "Alert")
          threat_intelligence_allowlist = virtual_hub.config.azure_firewall.config.threat_intelligence_allowlist
          dns = try(
            local.custom_settings.azurerm_firewall_policy["virtual_wan"][location].dns,
            (
              virtual_hub.config.azure_firewall.config.sku_tier == "Basic" ? local.empty_list :
              [
                {
                  proxy_enabled = virtual_hub.config.azure_firewall.config.enable_dns_proxy
                  servers       = length(virtual_hub.config.azure_firewall.config.dns_servers) > 0 ? virtual_hub.config.azure_firewall.config.dns_servers : null
                }
              ]
            )
          )
          identity            = try(local.custom_settings.azurerm_firewall_policy["virtual_wan"][location].identity, local.empty_list)
          insights            = try(local.custom_settings.azurerm_firewall_policy["virtual_wan"][location].insights, local.empty_list)
          intrusion_detection = try(local.custom_settings.azurerm_firewall_policy["virtual_wan"][location].intrusion_detection, local.empty_list)
          tags                = try(local.custom_settings.azurerm_firewall_policy["virtual_wan"][location].tags, local.tags)
        }
        # Child resource definition attributes
        azurerm_public_ip = local.empty_list
      }
    ]
  )
}

# Configuration settings for resource type:
#  - azurerm_firewall_policy
locals {
  azurerm_firewall_policy = local.azurerm_firewall.*.azurerm_firewall_policy
}

# Configuration settings for resource type:
#  - azurerm_virtual_wan
# We only support creation of a single azurerm_virtual_wan resource
# per module deployment. This uses the default location set at the
# scope of the connectivity child module.
locals {
  virtual_wan_name = {
    for location in local.virtual_wan_locations :
    location =>
    try(local.custom_settings.azurerm_virtual_wan["virtual_wan"][location].name,
    "${local.resource_prefix}-vwan-${location}${local.resource_suffix}")
  }
  virtual_wan_resource_group_id = {
    for location in local.virtual_wan_locations :
    location =>
    local.resource_group_config_by_scope_and_location["virtual_wan"][location].resource_id
  }
  virtual_wan_resource_id_prefix = {
    for location in local.virtual_wan_locations :
    location =>
    "${local.virtual_wan_resource_group_id[location]}/providers/Microsoft.Network/virtualWans"
  }
  virtual_wan_resource_id = {
    for location in local.virtual_wan_locations :
    location =>
    "${local.virtual_wan_resource_id_prefix[location]}/${local.virtual_wan_name[location]}"
  }
  azurerm_virtual_wan = [
    for location in local.virtual_wan_locations :
    {
      # Resource logic attributes
      resource_id       = local.virtual_wan_resource_id[location]
      managed_by_module = local.deploy_virtual_wan[location]
      # Resource definition attributes
      name                = local.virtual_wan_name[location]
      resource_group_name = local.resource_group_names_by_scope_and_location["virtual_wan"][location]
      location            = location
      # Optional definition attributes
      disable_vpn_encryption            = try(local.custom_settings.azurerm_virtual_wan["virtual_wan"][location].disable_vpn_encryption, false)
      allow_branch_to_branch_traffic    = try(local.custom_settings.azurerm_virtual_wan["virtual_wan"][location].allow_branch_to_branch_traffic, true)
      office365_local_breakout_category = try(local.custom_settings.azurerm_virtual_wan["virtual_wan"][location].office365_local_breakout_category, "None")
      type                              = try(local.custom_settings.azurerm_virtual_wan["virtual_wan"][location].type, "Standard")
      tags                              = try(local.custom_settings.azurerm_virtual_wan["virtual_wan"][location].tags, local.tags)
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_virtual_hub
locals {
  virtual_hub_name = {
    for location in local.virtual_hub_locations :
    location =>
    try(local.custom_settings.azurerm_virtual_hub["virtual_wan"][location].name,
    "${local.resource_prefix}-hub-${location}${local.resource_suffix}")
  }
  virtual_hub_resource_group_name = {
    for location in local.virtual_hub_locations :
    location => (
      contains(keys(local.virtual_hubs_by_location_for_resource_group_per_location), location) ?
      local.resource_group_names_by_scope_and_location["connectivity"][location] :
      local.resource_group_names_by_scope_and_location["virtual_wan"][local.virtual_wan_locations[0]]
    )
  }
  virtual_hub_resource_group_id = {
    for location in local.virtual_hub_locations :
    location => (
      contains(keys(local.virtual_hubs_by_location_for_resource_group_per_location), location) ?
      local.resource_group_config_by_scope_and_location["connectivity"][location].resource_id :
      local.resource_group_config_by_scope_and_location["virtual_wan"][local.virtual_wan_locations[0]].resource_id
    )
  }
  virtual_hub_resource_id_prefix = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_resource_group_id[location]}/providers/Microsoft.Network/virtualHubs"
  }
  virtual_hub_resource_id = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_resource_id_prefix[location]}/${local.virtual_hub_name[location]}"
  }
  azurerm_virtual_hub = [
    for location, virtual_hub in local.virtual_hubs_by_location :
    {
      # Resource logic attributes
      resource_id       = local.virtual_hub_resource_id[location]
      managed_by_module = local.deploy_virtual_hub[location]
      # Resource definition attributes
      name                = local.virtual_hub_name[location]
      resource_group_name = local.virtual_hub_resource_group_name[location]
      location            = location
      # Optional definition attributes
      sku                    = coalesce(virtual_hub.config.sku, "Standard")
      address_prefix         = virtual_hub.config.address_prefix
      hub_routing_preference = try(local.custom_settings.azurerm_virtual_hub["virtual_wan"][location].hub_routing_preference, "ExpressRoute")
      virtual_wan_id = length(local.existing_virtual_wan_resource_id) > 0 ? local.existing_virtual_wan_resource_id : (
        length(local.virtual_wan_locations) > 0 ?
        lookup(local.virtual_wan_resource_id, local.virtual_wan_locations[0], null) :
        null
      )
      tags = try(local.custom_settings.azurerm_virtual_hub["virtual_wan"][location].tags, local.tags)
      route = [
        for route in virtual_hub.config.routes :
        {
          address_prefixes    = route.address_prefixes
          next_hop_ip_address = route.next_hop_ip_address
        }
      ]
    }
  ]
}

locals {
  virtual_hub_routing_intent_name = {
    for location in local.virtual_hub_locations :
    location =>
    try(local.custom_settings.azurerm_routing_intent["virtual_wan"][location].name,
    "${local.resource_prefix}-routingintent-${location}${local.resource_suffix}")
  }
  virtual_hub_routing_intent_resource_id_prefix = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_resource_group_id[location]}/providers/Microsoft.Network/virtualHubs/${local.virtual_hub_name[location]}"
  }
  virtual_hub_routing_intent_resource_id = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_routing_intent_resource_id_prefix[location]}/${local.virtual_hub_routing_intent_name[location]}"
  }
  azurerm_virtual_hub_routing_intent = [
    for location, virtual_hub in local.virtual_hubs_by_location :
    {
      resource_id       = local.virtual_hub_routing_intent_resource_id[location]
      managed_by_module = local.deploy_virtual_hub_routing_intent[location]
      name              = local.virtual_hub_routing_intent_name[location]
      virtual_hub_id    = local.virtual_hub_resource_id[location]
      routing_policy = try(local.custom_settings.azurerm_virtual_hub_routing_intent["virtual_wan"][location].routing_policy,
        [
          for routing_policy in virtual_hub.config.routing_intent.config.routing_policies :
          {
            name         = routing_policy.name
            destinations = routing_policy.destinations
            next_hop     = local.virtual_hub_azfw_resource_id[location]
          }
        ]
      )
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_express_route_gateway
locals {
  virtual_hub_express_route_gateway_name = {
    for location in local.virtual_hub_locations :
    location =>
    try(local.custom_settings.azurerm_express_route_gateway["virtual_wan"][location].name,
    "${local.resource_prefix}-ergw-${location}${local.resource_suffix}")
  }
  virtual_hub_express_route_gateway_resource_id_prefix = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_resource_group_id[location]}/providers/Microsoft.Network/expressRouteGateways"
  }
  virtual_hub_express_route_gateway_resource_id = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_express_route_gateway_resource_id_prefix[location]}/${local.virtual_hub_express_route_gateway_name[location]}"
  }
  azurerm_express_route_gateway = [
    for location, virtual_hub in local.virtual_hubs_by_location :
    {
      # Resource logic attributes
      resource_id       = local.virtual_hub_express_route_gateway_resource_id[location]
      managed_by_module = local.deploy_virtual_hub_express_route_gateway[location]
      # Resource definition attributes
      name                          = local.virtual_hub_express_route_gateway_name[location]
      resource_group_name           = local.virtual_hub_resource_group_name[location]
      location                      = location
      virtual_hub_id                = local.virtual_hub_resource_id[location]
      scale_units                   = virtual_hub.config.expressroute_gateway.config.scale_unit
      allow_non_virtual_wan_traffic = virtual_hub.config.expressroute_gateway.config.allow_non_virtual_wan_traffic
      # Optional definition attributes
      tags = try(local.custom_settings.azurerm_express_route_gateway["virtual_wan"][location].tags, local.tags)
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_vpn_gateway
locals {
  virtual_hub_vpn_gateway_name = {
    for location in local.virtual_hub_locations :
    location =>
    try(local.custom_settings.azurerm_vpn_gateway["virtual_wan"][location].name,
    "${local.resource_prefix}-vpngw-${location}${local.resource_suffix}")
  }
  virtual_hub_vpn_gateway_resource_id_prefix = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_resource_group_id[location]}/providers/Microsoft.Network/vpnGateways"
  }
  virtual_hub_vpn_gateway_resource_id = {
    for location in local.virtual_hub_locations :
    location =>
    "${local.virtual_hub_vpn_gateway_resource_id_prefix[location]}/${local.virtual_hub_vpn_gateway_name[location]}"
  }
  azurerm_vpn_gateway = [
    for location, virtual_hub in local.virtual_hubs_by_location :
    {
      # Resource logic attributes
      resource_id       = local.virtual_hub_vpn_gateway_resource_id[location]
      managed_by_module = local.deploy_virtual_hub_vpn_gateway[location]
      # Resource definition attributes
      name                = local.virtual_hub_vpn_gateway_name[location]
      resource_group_name = local.virtual_hub_resource_group_name[location]
      location            = location
      virtual_hub_id      = local.virtual_hub_resource_id[location]
      # Optional definition attributes
      routing_preference = coalesce(virtual_hub.config.vpn_gateway.config.routing_preference, "Microsoft Network")
      scale_unit         = virtual_hub.config.vpn_gateway.config.scale_unit
      tags               = try(local.custom_settings.azurerm_vpn_gateway["virtual_wan"][location].tags, local.tags)
      bgp_settings = [
        for bgp_setting in virtual_hub.config.vpn_gateway.config.bgp_settings :
        {
          asn         = bgp_setting.asn
          peer_weight = bgp_setting.peer_weight
          instance_0_bgp_peering_address = [
            for instance_bgp_peering_address in bgp_setting.instance_0_bgp_peering_address :
            {
              custom_ips = instance_bgp_peering_address.custom_ips
            }
          ]
          instance_1_bgp_peering_address = [
            for instance_bgp_peering_address in bgp_setting.instance_1_bgp_peering_address :
            {
              custom_ips = instance_bgp_peering_address.custom_ips
            }
          ]
        }
      ]
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_public_ip
locals {
  azurerm_public_ip = flatten([
    for azurerm_public_ip in concat(
      local.azurerm_virtual_network_gateway.*.azurerm_public_ip,
      local.azurerm_firewall.*.azurerm_public_ip,
    ) :
    azurerm_public_ip
    if length(azurerm_public_ip) > 0
  ])
}

# Configuration settings for resource type:
#  - azurerm_private_dns_zone
locals {
  enable_private_link_by_service = local.settings.dns.config.enable_private_link_by_service
  lowered_private_link_locations = [for location in local.settings.dns.config.private_link_locations : lower(location)]
  private_link_locations         = coalescelist(local.lowered_private_link_locations, [local.location])
  private_dns_zone_prefix        = "${local.resource_group_config_by_scope_and_location["dns"][local.dns_location].resource_id}/providers/Microsoft.Network/privateDnsZones/"

  lowered_builtin_azure_backup_geo_codes = { for key, value in local.builtin_azure_backup_geo_codes : lower(key) => lower(value) }

  lookup_azure_backup_geo_codes = merge(
    local.lowered_builtin_azure_backup_geo_codes,
    local.custom_azure_backup_geo_codes,
  )
  lookup_private_link_dns_zone_by_service = {
    azure_api_management                 = ["privatelink.azure-api.net", "privatelink.developer.azure-api.net"]
    azure_app_configuration_stores       = ["privatelink.azconfig.io"]
    azure_arc                            = ["privatelink.his.arc.azure.com", "privatelink.guestconfiguration.azure.com", "privatelink.kubernetesconfiguration.azure.com"]
    azure_arc_guest_configuration        = ["privatelink.guestconfiguration.azure.com"]
    azure_arc_hybrid_resource_provider   = ["privatelink.his.arc.azure.com"]
    azure_arc_kubernetes                 = ["privatelink.dp.kubernetesconfiguration.azure.com"]
    azure_automation_dscandhybridworker  = ["privatelink.azure-automation.net"]
    azure_automation_webhook             = ["privatelink.azure-automation.net"]
    azure_batch_account                  = ["privatelink.batch.azure.com"]
    azure_bot_service_bot                = ["privatelink.directline.botframework.com"]
    azure_bot_service_token              = ["privatelink.token.botframework.com"]
    azure_cache_for_redis                = ["privatelink.redis.cache.windows.net"]
    azure_cache_for_redis_enterprise     = ["privatelink.redisenterprise.cache.azure.net"]
    azure_container_registry             = ["privatelink.azurecr.io"]
    azure_cosmos_db_cassandra            = ["privatelink.cassandra.cosmos.azure.com"]
    azure_cosmos_db_gremlin              = ["privatelink.gremlin.cosmos.azure.com"]
    azure_cosmos_db_mongodb              = ["privatelink.mongo.cosmos.azure.com"]
    azure_cosmos_db_sql                  = ["privatelink.documents.azure.com"]
    azure_cosmos_db_table                = ["privatelink.table.cosmos.azure.com"]
    azure_data_factory                   = ["privatelink.datafactory.azure.net"]
    azure_data_factory_portal            = ["privatelink.adf.azure.com"]
    azure_data_health_data_services      = ["privatelink.azurehealthcareapis.com", "privatelink.dicom.azurehealthcareapis.com"]
    azure_data_lake_file_system_gen2     = ["privatelink.dfs.core.windows.net"]
    azure_database_for_mariadb_server    = ["privatelink.mariadb.database.azure.com"]
    azure_database_for_mysql_server      = ["privatelink.mysql.database.azure.com"]
    azure_database_for_postgresql_server = ["privatelink.postgres.database.azure.com"]
    azure_databricks                     = ["privatelink.azuredatabricks.net"]
    azure_digital_twins                  = ["privatelink.digitaltwins.azure.net"]
    azure_event_grid_domain              = ["privatelink.eventgrid.azure.net"]
    azure_event_grid_topic               = ["privatelink.eventgrid.azure.net"]
    azure_event_hubs_namespace           = ["privatelink.servicebus.windows.net"]
    azure_file_sync                      = ["privatelink.afs.azure.net"]
    azure_hdinsights                     = ["privatelink.azurehdinsight.net"]
    azure_iot_dps                        = ["privatelink.azure-devices-provisioning.net"]
    azure_iot_hub                        = ["privatelink.azure-devices.net", "privatelink.servicebus.windows.net"]
    azure_key_vault                      = ["privatelink.vaultcore.azure.net"]
    azure_key_vault_managed_hsm          = ["privatelink.managedhsm.azure.net"]
    azure_machine_learning_workspace     = ["privatelink.api.azureml.ms", "privatelink.notebooks.azure.net"]
    azure_managed_disks                  = ["privatelink.blob.core.windows.net"]
    azure_managed_grafana                = ["privatelink.grafana.azure.com"]
    azure_media_services                 = ["privatelink.media.azure.net"]
    azure_migrate                        = ["privatelink.prod.migration.windowsazure.com"]
    azure_monitor                        = ["privatelink.monitor.azure.com", "privatelink.oms.opinsights.azure.com", "privatelink.ods.opinsights.azure.com", "privatelink.agentsvc.azure-automation.net", "privatelink.blob.core.windows.net"]
    azure_openai_service                 = ["privatelink.openai.azure.com"]
    azure_purview_account                = ["privatelink.purview.azure.com"]
    azure_purview_studio                 = ["privatelink.purviewstudio.azure.com"]
    azure_relay_namespace                = ["privatelink.servicebus.windows.net"]
    azure_search_service                 = ["privatelink.search.windows.net"]
    azure_service_bus_namespace          = ["privatelink.servicebus.windows.net"]
    azure_site_recovery                  = ["privatelink.siterecovery.windowsazure.com"]
    azure_sql_database_sqlserver         = ["privatelink.database.windows.net"]
    azure_synapse_analytics_dev          = ["privatelink.dev.azuresynapse.net"]
    azure_synapse_analytics_sql          = ["privatelink.sql.azuresynapse.net"]
    azure_synapse_studio                 = ["privatelink.azuresynapse.net"]
    azure_virtual_desktop                = ["privatelink.wvd.microsoft.com"]
    azure_web_apps_sites                 = ["privatelink.azurewebsites.net"]
    azure_web_apps_static_sites          = ["privatelink.azurestaticapps.net"]
    cognitive_services_account           = ["privatelink.cognitiveservices.azure.com"]
    microsoft_power_bi                   = ["privatelink.analysis.windows.net", "privatelink.pbidedicated.windows.net", "privatelink.tip1.powerquery.microsoft.com"]
    signalr                              = ["privatelink.service.signalr.net"]
    signalr_webpubsub                    = ["privatelink.webpubsub.azure.com"]
    storage_account_blob                 = ["privatelink.blob.core.windows.net"]
    storage_account_file                 = ["privatelink.file.core.windows.net"]
    storage_account_queue                = ["privatelink.queue.core.windows.net"]
    storage_account_table                = ["privatelink.table.core.windows.net"]
    storage_account_web                  = ["privatelink.web.core.windows.net"]
    azure_backup = [
      for location in local.private_link_locations :
      "privatelink.${local.lookup_azure_backup_geo_codes[location]}.backup.windowsazure.com"
    ]
    azure_data_explorer = [
      for location in local.private_link_locations :
      "privatelink.${location}.kusto.windows.net"
    ]
    azure_kubernetes_service_management = [
      for location in local.private_link_locations :
      "privatelink.${location}.azmk8s.io"
    ]
    azure_web_apps_static_sites = concat(["privatelink.azurestaticapps.net"], [
      for partitionid in local.custom_privatelink_azurestaticapps_partitionids :
      "privatelink.${partitionid}.azurestaticapps.net"
    ])
  }
  # The lookup_private_link_group_id_by_service local doesn't currently
  # do anything but is planned to control policy configuration for
  # private endpoint configuration by resource type
  lookup_private_link_group_id_by_service = {
    azure_api_management                 = local.empty_string
    azure_app_configuration_stores       = local.empty_string
    azure_arc                            = local.empty_string
    azure_automation_dscandhybridworker  = local.empty_string
    azure_automation_webhook             = local.empty_string
    azure_backup                         = local.empty_string
    azure_batch_account                  = local.empty_string
    azure_bot_service_bot                = local.empty_string
    azure_bot_service_token              = local.empty_string
    azure_cache_for_redis                = local.empty_string
    azure_cache_for_redis_enterprise     = local.empty_string
    azure_container_registry             = local.empty_string
    azure_cosmos_db_cassandra            = local.empty_string
    azure_cosmos_db_gremlin              = local.empty_string
    azure_cosmos_db_mongodb              = local.empty_string
    azure_cosmos_db_sql                  = local.empty_string
    azure_cosmos_db_table                = local.empty_string
    azure_data_explorer                  = local.empty_string
    azure_data_factory                   = local.empty_string
    azure_data_factory_portal            = local.empty_string
    azure_data_lake_file_system_gen2     = "dfs"
    azure_database_for_mariadb_server    = local.empty_string
    azure_database_for_mysql_server      = local.empty_string
    azure_database_for_postgresql_server = local.empty_string
    azure_digital_twins                  = local.empty_string
    azure_event_grid_domain              = local.empty_string
    azure_event_grid_topic               = local.empty_string
    azure_event_hubs_namespace           = local.empty_string
    azure_file_sync                      = local.empty_string
    azure_hdinsights                     = local.empty_string
    azure_iot_dps                        = local.empty_string
    azure_iot_hub                        = local.empty_string
    azure_key_vault                      = "vault"
    azure_key_vault_managed_hsm          = local.empty_string
    azure_kubernetes_service_management  = local.empty_string
    azure_machine_learning_workspace     = local.empty_string
    azure_managed_disks                  = "disks"
    azure_media_services                 = local.empty_string
    azure_migrate                        = local.empty_string
    azure_monitor                        = local.empty_string
    azure_purview_account                = local.empty_string
    azure_purview_studio                 = local.empty_string
    azure_relay_namespace                = local.empty_string
    azure_search_service                 = local.empty_string
    azure_service_bus_namespace          = local.empty_string
    azure_site_recovery                  = local.empty_string
    azure_sql_database_sqlserver         = "sqlServer"
    azure_synapse_analytics_dev          = local.empty_string
    azure_synapse_analytics_sql          = local.empty_string
    azure_synapse_studio                 = local.empty_string
    azure_web_apps_sites                 = local.empty_string
    azure_web_apps_static_sites          = local.empty_string
    cognitive_services_account           = local.empty_string
    microsoft_power_bi                   = local.empty_string
    signalr                              = local.empty_string
    signalr_webpubsub                    = local.empty_string
    storage_account_blob                 = "blob"
    storage_account_file                 = "file"
    storage_account_queue                = "queue"
    storage_account_table                = "table"
    storage_account_web                  = "web"
  }
  services_by_private_link_dns_zone = transpose(local.lookup_private_link_dns_zone_by_service)
  private_dns_zone_enabled = {
    for fqdn, services in local.services_by_private_link_dns_zone :
    fqdn => anytrue(
      [
        for service in services : local.enable_private_link_by_service[service]
      ]
    )
  }
  azurerm_private_dns_zone = concat(
    [
      for fqdn, services in local.services_by_private_link_dns_zone :
      {
        # Resource logic attributes
        resource_id       = "${local.resource_group_config_by_scope_and_location["dns"][local.dns_location].resource_id}/providers/Microsoft.Network/privateDnsZones/${fqdn}"
        managed_by_module = local.deploy_dns && local.private_dns_zone_enabled[fqdn]
        # Resource definition attributes
        name = fqdn
        resource_group_name = try(
          local.custom_settings.azurerm_private_dns_zone["connectivity"][fqdn]["global"].resource_group_name,
          local.resource_group_names_by_scope_and_location["dns"][local.dns_location]
        )
        # Optional definition attributes
        soa_record = try(local.custom_settings.azurerm_private_dns_zone["connectivity"][fqdn]["global"].soa_record, local.empty_list)
        tags       = try(local.custom_settings.azurerm_private_dns_zone["connectivity"][fqdn]["global"].tags, local.tags)
      }
    ],
    [
      for fqdn in toset(local.settings.dns.config.private_dns_zones) :
      {
        # Resource logic attributes
        resource_id       = "${local.resource_group_config_by_scope_and_location["dns"][local.dns_location].resource_id}/providers/Microsoft.Network/privateDnsZones/${fqdn}"
        managed_by_module = local.deploy_dns
        # Resource definition attributes
        name = fqdn
        resource_group_name = try(
          local.custom_settings.azurerm_private_dns_zone["connectivity"][fqdn]["global"].resource_group_name,
          local.resource_group_names_by_scope_and_location["dns"][local.dns_location]
        )
        # Optional definition attributes
        soa_record = try(local.custom_settings.azurerm_private_dns_zone["connectivity"][fqdn]["global"].soa_record, local.empty_list)
        tags       = try(local.custom_settings.azurerm_private_dns_zone["connectivity"][fqdn]["global"].tags, local.tags)
      }
      if !(contains(keys(local.services_by_private_link_dns_zone), fqdn))
    ],
  )
}

# Configuration settings for resource type:
#  - azurerm_dns_zone
locals {
  azurerm_dns_zone = [
    for fqdn in toset(local.settings.dns.config.public_dns_zones) :
    {
      # Resource logic attributes
      resource_id       = "${local.resource_group_config_by_scope_and_location["dns"][local.dns_location].resource_id}/providers/Microsoft.Network/dnsZones/${fqdn}"
      managed_by_module = local.deploy_dns
      # Resource definition attributes
      name = fqdn
      resource_group_name = try(
        local.custom_settings.azurerm_private_dns_zone["connectivity"][fqdn]["global"].resource_group_name,
        local.resource_group_names_by_scope_and_location["dns"][local.dns_location]
      )
      # Optional definition attributes
      soa_record = try(local.custom_settings.azurerm_dns_zone["connectivity"][fqdn]["global"].soa_record, local.empty_list)
      tags       = try(local.custom_settings.azurerm_dns_zone["connectivity"][fqdn]["global"].tags, local.tags)
    }
  ]
}

# Configuration settings for resource type:
#  - azurerm_private_dns_zone_virtual_network_link
locals {
  hub_virtual_networks_for_dns = [
    for hub_config in local.azurerm_virtual_network :
    {
      resource_id       = hub_config.resource_id
      name              = "${split("/", hub_config.resource_id)[2]}-${uuidv5("url", hub_config.resource_id)}"
      managed_by_module = local.deploy_private_dns_zone_virtual_network_link_on_hubs && local.deploy_hub_network[hub_config.location]
    }
  ]
  spoke_virtual_networks_for_dns = flatten([
    [
      for location, hub_config in local.hub_networks_by_location :
      [
        for spoke_resource_id in hub_config.config.spoke_virtual_network_resource_ids :
        {
          resource_id       = spoke_resource_id
          name              = "${split("/", spoke_resource_id)[2]}-${uuidv5("url", spoke_resource_id)}"
          managed_by_module = local.deploy_private_dns_zone_virtual_network_link_on_spokes && hub_config.enabled
        }
      ]
    ],
    [
      for location, virtual_hub_config in local.virtual_hubs_by_location :
      [
        for spoke_resource_id in concat(virtual_hub_config.config.spoke_virtual_network_resource_ids, virtual_hub_config.config.secure_spoke_virtual_network_resource_ids) :
        {
          resource_id       = spoke_resource_id
          name              = "${split("/", spoke_resource_id)[2]}-${uuidv5("url", spoke_resource_id)}"
          managed_by_module = local.deploy_private_dns_zone_virtual_network_link_on_spokes && virtual_hub_config.enabled
        }
      ]
    ]
  ])
  additional_virtual_networks_for_dns = [
    for spoke_resource_id in local.settings.dns.config.virtual_network_resource_ids_to_link :
    {
      resource_id       = spoke_resource_id
      name              = "${split("/", spoke_resource_id)[2]}-${uuidv5("url", spoke_resource_id)}"
      managed_by_module = local.deploy_dns
    }
  ]

  # Distinct is used to allow for situations where
  # the same spoke is associated with multiple hub
  # networks for peering.
  virtual_networks_for_dns = distinct(concat(
    local.hub_virtual_networks_for_dns,
    local.spoke_virtual_networks_for_dns,
    local.additional_virtual_networks_for_dns,
  ))
  azurerm_private_dns_zone_virtual_network_link = flatten(
    [
      for zone in local.azurerm_private_dns_zone :
      [
        for link_config in local.virtual_networks_for_dns :
        {
          # Resource logic attributes
          resource_id       = "${zone.resource_id}/virtualNetworkLinks/${link_config.name}"
          managed_by_module = zone.managed_by_module && link_config.managed_by_module
          # Resource definition attributes
          name                  = link_config.name
          resource_group_name   = zone.resource_group_name
          private_dns_zone_name = zone.name
          virtual_network_id    = link_config.resource_id
          # Optional definition attributes
          registration_enabled = try(local.custom_settings.azurerm_private_dns_zone_virtual_network_link["connectivity"][link_config.name][zone.name].registration_enabled, false)
          tags                 = try(local.custom_settings.azurerm_private_dns_zone_virtual_network_link["connectivity"][link_config.name]["global"].tags, local.tags)
        }
      ]
    ]
  )
}

# Configuration settings for resource type:
#  - azurerm_virtual_network_peering
locals {
  virtual_network_peering_name = {
    for location, hub_config in local.hub_networks_by_location :
    location => {
      for spoke_resource_id in hub_config.config.spoke_virtual_network_resource_ids :
      spoke_resource_id => try(
        local.custom_settings.azurerm_virtual_network_peering["connectivity"][location][spoke_resource_id].name,
        "peering-${uuidv5("url", spoke_resource_id)}"
      )
    }
  }
  virtual_network_hub_peering_name = {
    for location_src, hub_config_src in local.hub_networks_by_location :
    location_src => {
      for location_dst, hub_config_dst in local.hub_networks_by_location :
      location_dst => try(
        local.custom_settings.azurerm_virtual_network_peering["connectivity"][location_src][location_dst].name,
        "peering-${uuidv5("url", local.virtual_network_resource_id[location_dst])}"
      ) if location_src != location_dst && hub_config_dst.config.enable_hub_network_mesh_peering
    } if hub_config_src.config.enable_hub_network_mesh_peering
  }
  virtual_network_peering_resource_id_prefix = {
    for location, hub_config in local.hub_networks_by_location :
    location =>
    "${local.virtual_network_resource_id[location]}/virtualNetworkPeerings"
  }
  virtual_network_peering_resource_id = {
    for location, hub_config in local.hub_networks_by_location :
    location => {
      for spoke_resource_id, peering_name in local.virtual_network_peering_name[location] :
      spoke_resource_id =>
      "${local.virtual_network_peering_resource_id_prefix[location]}/${peering_name}"
    }
  }
  virtual_network_hub_peerings = {
    for location_src, hub_config_src in local.hub_networks_by_location :
    location_src => {
      for location_dst, hub_config_dst in local.hub_networks_by_location :
      location_dst => {
        remote_virtual_network_id           = local.virtual_network_resource_id[location_dst]
        virtual_network_peering_name        = local.virtual_network_hub_peering_name[location_src][location_dst]
        virtual_network_peering_resource_id = "${local.virtual_network_resource_id[location_src]}/virtualNetworkPeerings/${local.virtual_network_hub_peering_name[location_src][location_dst]}"
      } if location_src != location_dst && hub_config_dst.config.enable_hub_network_mesh_peering
    } if hub_config_src.config.enable_hub_network_mesh_peering
  }
  azurerm_virtual_network_peering_hubs = flatten(
    [
      for location_src, remote in local.virtual_network_hub_peerings :
      [
        for location_dst, peerconfig in remote :
        {
          # Resource logic attributes
          resource_id       = peerconfig.virtual_network_peering_resource_id
          managed_by_module = local.deploy_hub_virtual_network_mesh_peering[location_src] && local.deploy_hub_virtual_network_mesh_peering[location_dst]
          # Resource definition attributes
          name                      = peerconfig.virtual_network_peering_name
          resource_group_name       = local.resource_group_names_by_scope_and_location["connectivity"][location_src]
          virtual_network_name      = local.virtual_network_name[location_src]
          remote_virtual_network_id = peerconfig.remote_virtual_network_id
          # Optional definition attributes
          allow_virtual_network_access = true
          allow_forwarded_traffic      = true
          allow_gateway_transit        = true
          use_remote_gateways          = false
        }
      ]
    ]
  )
  azurerm_virtual_network_peering_spokes = flatten(
    [
      for location, hub_config in local.hub_networks_by_location :
      [
        for spoke_resource_id in hub_config.config.spoke_virtual_network_resource_ids :
        {
          # Resource logic attributes
          resource_id       = local.virtual_network_peering_resource_id[location][spoke_resource_id]
          managed_by_module = local.deploy_outbound_virtual_network_peering[location]
          # Resource definition attributes
          name                      = local.virtual_network_peering_name[location][spoke_resource_id]
          resource_group_name       = local.resource_group_names_by_scope_and_location["connectivity"][location]
          virtual_network_name      = local.virtual_network_name[location]
          remote_virtual_network_id = spoke_resource_id
          # Optional definition attributes
          allow_virtual_network_access = true
          allow_forwarded_traffic      = true
          allow_gateway_transit        = true
          use_remote_gateways          = false
        }
      ]
    ]
  )
  azurerm_virtual_network_peering = distinct(concat(
    local.azurerm_virtual_network_peering_hubs,
    local.azurerm_virtual_network_peering_spokes
  ))
}

# Configuration settings for resource type:
#  - azurerm_virtual_hub_connection
locals {
  azurerm_virtual_hub_connection = flatten(
    [
      for location, virtual_hub_config in local.virtual_hubs_by_location :
      [
        for spoke_resource_id in distinct(concat(virtual_hub_config.config.spoke_virtual_network_resource_ids, virtual_hub_config.config.secure_spoke_virtual_network_resource_ids)) :
        {
          # Resource logic attributes
          resource_id = try(
            "${local.virtual_hub_resource_id[location]}/hubVirtualNetworkConnections/${local.custom_settings.azurerm_virtual_hub_connection["virtual_wan"][location][spoke_resource_id].name}",
            "${local.virtual_hub_resource_id[location]}/hubVirtualNetworkConnections/peering-${uuidv5("url", spoke_resource_id)}"
          )
          managed_by_module = local.deploy_virtual_hub_connection[location]
          # Resource definition attributes
          name = try(
            local.custom_settings.azurerm_virtual_hub_connection["virtual_wan"][location][spoke_resource_id].name,
            "peering-${uuidv5("url", spoke_resource_id)}"
          )
          virtual_hub_id            = local.virtual_hub_resource_id[location]
          remote_virtual_network_id = spoke_resource_id
          # Optional definition attributes
          internet_security_enabled = contains(virtual_hub_config.config.secure_spoke_virtual_network_resource_ids, spoke_resource_id)
          routing                   = local.empty_list
        }
      ]
    ]
  )
}

# Archetype configuration overrides
locals {
  archetype_config_overrides = {
    "${local.root_id}-connectivity" = {
      parameters = {
        Enable-DDoS-VNET = {
          ddosPlan = local.ddos_protection_plan_resource_id
        }
      }
      enforcement_mode = {
        Enable-DDoS-VNET = local.deploy_ddos_protection_plan
      }
    }
    "${local.root_id}-corp" = {
      parameters = {
        Deploy-Private-DNS-Zones = {
          azureAcrPrivateDnsZoneId                        = "${local.private_dns_zone_prefix}privatelink.azurecr.io"
          azureManagedGrafanaWorkspacePrivateDnsZoneId    = "${local.private_dns_zone_prefix}privatelink.grafana.azure.com"
          azureArcKubernetesConfigurationPrivateDnsZoneId = "${local.private_dns_zone_prefix}privatelink.dp.kubernetesconfiguration.azure.com"
          azureArcHybridResourceProviderPrivateDnsZoneId  = "${local.private_dns_zone_prefix}privatelink.his.arc.azure.com"
          azureArcGuestconfigurationPrivateDnsZoneId      = "${local.private_dns_zone_prefix}privatelink.guestconfiguration.azure.com"
          azureAppPrivateDnsZoneId                        = "${local.private_dns_zone_prefix}privatelink.azconfig.io"
          azureAppServicesPrivateDnsZoneId                = "${local.private_dns_zone_prefix}privatelink.azurewebsites.net"
          azureAsrPrivateDnsZoneId                        = "${local.private_dns_zone_prefix}privatelink.siterecovery.windowsazure.com"
          azureAutomationDSCHybridPrivateDnsZoneId        = "${local.private_dns_zone_prefix}privatelink.azure-automation.net"
          azureAutomationWebhookPrivateDnsZoneId          = "${local.private_dns_zone_prefix}privatelink.azure-automation.net"
          azureBatchPrivateDnsZoneId                      = "${local.private_dns_zone_prefix}privatelink.batch.azure.com"
          azureCognitiveSearchPrivateDnsZoneId            = "${local.private_dns_zone_prefix}privatelink.search.windows.net"
          azureCognitiveServicesPrivateDnsZoneId          = "${local.private_dns_zone_prefix}privatelink.cognitiveservices.azure.com"
          azureCosmosCassandraPrivateDnsZoneId            = "${local.private_dns_zone_prefix}privatelink.cassandra.cosmos.azure.com"
          azureCosmosGremlinPrivateDnsZoneId              = "${local.private_dns_zone_prefix}privatelink.gremlin.cosmos.azure.com"
          azureCosmosMongoPrivateDnsZoneId                = "${local.private_dns_zone_prefix}privatelink.mongo.cosmos.azure.com"
          azureCosmosSQLPrivateDnsZoneId                  = "${local.private_dns_zone_prefix}privatelink.documents.azure.com"
          azureCosmosTablePrivateDnsZoneId                = "${local.private_dns_zone_prefix}privatelink.table.cosmos.azure.com"
          azureDataFactoryPortalPrivateDnsZoneId          = "${local.private_dns_zone_prefix}privatelink.adf.azure.com"
          azureDataFactoryPrivateDnsZoneId                = "${local.private_dns_zone_prefix}privatelink.datafactory.azure.net"
          azureDiskAccessPrivateDnsZoneId                 = "${local.private_dns_zone_prefix}privatelink.blob.core.windows.net"
          azureEventGridDomainsPrivateDnsZoneId           = "${local.private_dns_zone_prefix}privatelink.eventgrid.azure.net"
          azureEventGridTopicsPrivateDnsZoneId            = "${local.private_dns_zone_prefix}privatelink.eventgrid.azure.net"
          azureEventHubNamespacePrivateDnsZoneId          = "${local.private_dns_zone_prefix}privatelink.servicebus.windows.net"
          azureFilePrivateDnsZoneId                       = "${local.private_dns_zone_prefix}privatelink.afs.azure.net"
          azureHDInsightPrivateDnsZoneId                  = "${local.private_dns_zone_prefix}privatelink.azurehdinsight.net"
          azureIotHubsPrivateDnsZoneId                    = "${local.private_dns_zone_prefix}privatelink.azure-devices.net"
          azureIotPrivateDnsZoneId                        = "${local.private_dns_zone_prefix}privatelink.azure-devices-provisioning.net"
          azureKeyVaultPrivateDnsZoneId                   = "${local.private_dns_zone_prefix}privatelink.vaultcore.azure.net"
          azureMachineLearningWorkspacePrivateDnsZoneId   = "${local.private_dns_zone_prefix}privatelink.api.azureml.ms"
          azureMediaServicesKeyPrivateDnsZoneId           = "${local.private_dns_zone_prefix}privatelink.media.azure.net"
          azureMediaServicesLivePrivateDnsZoneId          = "${local.private_dns_zone_prefix}privatelink.media.azure.net"
          azureMediaServicesStreamPrivateDnsZoneId        = "${local.private_dns_zone_prefix}privatelink.media.azure.net"
          azureMigratePrivateDnsZoneId                    = "${local.private_dns_zone_prefix}privatelink.prod.migration.windowsazure.com"
          azureMonitorPrivateDnsZoneId1                   = "${local.private_dns_zone_prefix}privatelink.monitor.azure.com"             # Private DNS Zone for global endpoints used by Azure Monitor
          azureMonitorPrivateDnsZoneId2                   = "${local.private_dns_zone_prefix}privatelink.oms.opinsights.azure.com"      # Private DNS Zone for workspace-specific mapping to OMS agents endpoints
          azureMonitorPrivateDnsZoneId3                   = "${local.private_dns_zone_prefix}privatelink.ods.opinsights.azure.com"      # Private DNS Zone for workspace-specific mapping to ingestion endpoints
          azureMonitorPrivateDnsZoneId4                   = "${local.private_dns_zone_prefix}privatelink.agentsvc.azure-automation.net" # Private DNS Zone for workspace-specific mapping to the agent service automation endpoints
          azureMonitorPrivateDnsZoneId5                   = "${local.private_dns_zone_prefix}privatelink.blob.core.windows.net"         # Private DNS Zone for connectivity to the global agent's solution packs storage account
          azureRedisCachePrivateDnsZoneId                 = "${local.private_dns_zone_prefix}privatelink.redis.cache.windows.net"
          azureServiceBusNamespacePrivateDnsZoneId        = "${local.private_dns_zone_prefix}privatelink.servicebus.windows.net"
          azureSignalRPrivateDnsZoneId                    = "${local.private_dns_zone_prefix}privatelink.service.signalr.net"
          azureStorageBlobPrivateDnsZoneId                = "${local.private_dns_zone_prefix}privatelink.blob.core.windows.net"
          azureStorageBlobSecPrivateDnsZoneId             = "${local.private_dns_zone_prefix}privatelink.blob.core.windows.net"
          azureStorageDFSPrivateDnsZoneId                 = "${local.private_dns_zone_prefix}privatelink.dfs.core.windows.net"
          azureStorageDFSSecPrivateDnsZoneId              = "${local.private_dns_zone_prefix}privatelink.dfs.core.windows.net"
          azureStorageFilePrivateDnsZoneId                = "${local.private_dns_zone_prefix}privatelink.file.core.windows.net"
          azureStorageQueuePrivateDnsZoneId               = "${local.private_dns_zone_prefix}privatelink.queue.core.windows.net"
          azureStorageQueueSecPrivateDnsZoneId            = "${local.private_dns_zone_prefix}privatelink.queue.core.windows.net"
          azureStorageStaticWebPrivateDnsZoneId           = "${local.private_dns_zone_prefix}privatelink.web.core.windows.net"
          azureStorageStaticWebSecPrivateDnsZoneId        = "${local.private_dns_zone_prefix}privatelink.web.core.windows.net"
          azureSynapseDevPrivateDnsZoneId                 = "${local.private_dns_zone_prefix}privatelink.dev.azuresynapse.net"
          azureSynapseSQLODPrivateDnsZoneId               = "${local.private_dns_zone_prefix}privatelink.sql.azuresynapse.net"
          azureSynapseSQLPrivateDnsZoneId                 = "${local.private_dns_zone_prefix}privatelink.sql.azuresynapse.net"
          azureWebPrivateDnsZoneId                        = "${local.private_dns_zone_prefix}privatelink.webpubsub.azure.com"
          azureVirtualDesktopHostpoolPrivateDnsZoneId     = "${local.private_dns_zone_prefix}privatelink.wvd.microsoft.com"
          azureVirtualDesktopWorkspacePrivateDnsZoneId    = "${local.private_dns_zone_prefix}privatelink.wvd.microsoft.com"
          azureSiteRecoveryBlobPrivateDnsZoneId           = "${local.private_dns_zone_prefix}privatelink.blob.core.windows.net"
          azureSiteRecoveryQueuePrivateDnsZoneId          = "${local.private_dns_zone_prefix}privatelink.queue.core.windows.net"
        }
      }
      enforcement_mode = {
        Deploy-Private-DNS-Zones = local.deploy_dns
      }
    }
    "${local.root_id}-landing-zones" = {
      parameters = {
        Enable-DDoS-VNET = {
          ddosPlan = local.ddos_protection_plan_resource_id
        }
      }
      enforcement_mode = {
        Enable-DDoS-VNET = local.deploy_ddos_protection_plan
      }
    }
  }
}

# Template file variable outputs
locals {
  template_file_variables = {
    ddos_protection_plan_resource_id        = local.ddos_protection_plan_resource_id
    private_dns_zone_prefix                 = local.private_dns_zone_prefix
    connectivity_location                   = local.location
    connectivity_location_short             = local.lookup_azure_backup_geo_codes[local.location]
    virtual_network_resource_id_by_location = local.virtual_network_resource_id
    vpn_gateway_resource_id_by_location     = local.vpn_gateway_resource_id
    firewall_resource_id_by_location        = local.azfw_resource_id
  }
}

# Generate the configuration output object for the module
locals {
  module_output = {
    azurerm_resource_group = [
      for resource in local.azurerm_resource_group :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if local.deploy_resource_groups[resource.scope][resource.location] &&
          key != "resource_id" &&
          key != "managed_by_module" &&
          key != "scope"
        }
        scope             = resource.scope
        managed_by_module = local.deploy_resource_groups[resource.scope][resource.location]
      }
    ]
    azurerm_virtual_network = [
      for resource in local.azurerm_virtual_network :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if local.deploy_hub_network[resource.location] &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = local.deploy_hub_network[resource.location]
      }
    ]
    azurerm_subnet = [
      for resource in local.azurerm_subnet :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if local.deploy_hub_network[resource.location] &&
          key != "resource_id" &&
          key != "managed_by_module" &&
          key != "location" &&
          key != "network_security_group_id" &&
          key != "route_table_id"
        }
        managed_by_module = local.deploy_hub_network[resource.location]
      }
    ]
    azurerm_virtual_network_gateway = [
      for resource in local.azurerm_virtual_network_gateway :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module" &&
          key != "azurerm_public_ip"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_public_ip = [
      for resource in local.azurerm_public_ip :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_firewall = [
      for resource in local.azurerm_firewall :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module" &&
          key != "azurerm_firewall_policy" &&
          key != "azurerm_public_ip" &&
          key != "scope"
        }
        scope             = resource.scope
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_firewall_policy = [
      for resource in local.azurerm_firewall_policy :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module" &&
          key != "scope"
        }
        scope             = resource.scope
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_virtual_wan = [
      for resource in local.azurerm_virtual_wan :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_virtual_hub = [
      for resource in local.azurerm_virtual_hub :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_virtual_hub_routing_intent = [
      for resource in local.azurerm_virtual_hub_routing_intent :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_express_route_gateway = [
      for resource in local.azurerm_express_route_gateway :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_vpn_gateway = [
      for resource in local.azurerm_vpn_gateway :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_network_ddos_protection_plan = [
      for resource in local.azurerm_network_ddos_protection_plan :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_private_dns_zone = [
      for resource in local.azurerm_private_dns_zone :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_dns_zone = [
      for resource in local.azurerm_dns_zone :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_private_dns_zone_virtual_network_link = [
      for resource in local.azurerm_private_dns_zone_virtual_network_link :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_virtual_network_peering = [
      for resource in local.azurerm_virtual_network_peering :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    azurerm_virtual_hub_connection = [
      for resource in local.azurerm_virtual_hub_connection :
      {
        resource_id   = resource.resource_id
        resource_name = resource.name
        template = {
          for key, value in resource :
          key => value
          if resource.managed_by_module &&
          key != "resource_id" &&
          key != "managed_by_module"
        }
        managed_by_module = resource.managed_by_module
      }
    ]
    archetype_config_overrides = local.archetype_config_overrides
    template_file_variables    = local.template_file_variables
  }
}

locals {
  debug_output = {
    archetype_config_overrides                               = local.archetype_config_overrides
    azfw_name                                                = local.azfw_name
    azfw_pip_name                                            = local.azfw_pip_name
    azfw_pip_resource_id                                     = local.azfw_pip_resource_id
    azfw_pip_resource_id_prefix                              = local.azfw_pip_resource_id_prefix
    azfw_policy_name                                         = local.azfw_policy_name
    azfw_policy_resource_id                                  = local.azfw_policy_resource_id
    azfw_policy_resource_id_prefix                           = local.azfw_policy_resource_id_prefix
    azfw_resource_id                                         = local.azfw_resource_id
    azfw_resource_id_prefix                                  = local.azfw_resource_id_prefix
    azfw_zones                                               = local.azfw_zones
    azfw_zones_enabled                                       = local.azfw_zones_enabled
    azurerm_dns_zone                                         = local.azurerm_dns_zone
    azurerm_express_route_gateway                            = local.azurerm_express_route_gateway
    azurerm_firewall                                         = local.azurerm_firewall
    azurerm_firewall_policy                                  = local.azurerm_firewall_policy
    azurerm_network_ddos_protection_plan                     = local.azurerm_network_ddos_protection_plan
    azurerm_private_dns_zone                                 = local.azurerm_private_dns_zone
    azurerm_private_dns_zone_virtual_network_link            = local.azurerm_private_dns_zone_virtual_network_link
    azurerm_public_ip                                        = local.azurerm_public_ip
    azurerm_resource_group                                   = local.azurerm_resource_group
    azurerm_subnet                                           = local.azurerm_subnet
    azurerm_virtual_hub                                      = local.azurerm_virtual_hub
    azurerm_virtual_hub_connection                           = local.azurerm_virtual_hub_connection
    azurerm_virtual_network                                  = local.azurerm_virtual_network
    azurerm_virtual_network_gateway                          = local.azurerm_virtual_network_gateway
    azurerm_virtual_network_gateway_express_route            = local.azurerm_virtual_network_gateway_express_route
    azurerm_virtual_network_gateway_vpn                      = local.azurerm_virtual_network_gateway_vpn
    azurerm_virtual_network_peering                          = local.azurerm_virtual_network_peering
    azurerm_virtual_network_peering_hubs                     = local.azurerm_virtual_network_peering_hubs
    azurerm_virtual_network_peering_spokes                   = local.azurerm_virtual_network_peering_spokes
    azurerm_virtual_wan                                      = local.azurerm_virtual_wan
    azurerm_vpn_gateway                                      = local.azurerm_vpn_gateway
    connectivity_locations                                   = local.connectivity_locations
    ddos_location                                            = local.ddos_location
    ddos_protection_plan_name                                = local.ddos_protection_plan_name
    ddos_protection_plan_resource_id                         = local.ddos_protection_plan_resource_id
    ddos_resource_group_id                                   = local.ddos_resource_group_id
    deploy_azure_firewall                                    = local.deploy_azure_firewall
    deploy_azure_firewall_policy                             = local.deploy_azure_firewall_policy
    deploy_ddos_protection_plan                              = local.deploy_ddos_protection_plan
    deploy_dns                                               = local.deploy_dns
    deploy_hub_network                                       = local.deploy_hub_network
    deploy_outbound_virtual_network_peering                  = local.deploy_outbound_virtual_network_peering
    deploy_private_dns_zone_virtual_network_link_on_hubs     = local.deploy_private_dns_zone_virtual_network_link_on_hubs
    deploy_private_dns_zone_virtual_network_link_on_spokes   = local.deploy_private_dns_zone_virtual_network_link_on_spokes
    deploy_resource_groups                                   = local.deploy_resource_groups
    deploy_virtual_hub                                       = local.deploy_virtual_hub
    deploy_virtual_hub_azure_firewall                        = local.deploy_virtual_hub_azure_firewall
    deploy_virtual_hub_azure_firewall_policy                 = local.deploy_virtual_hub_azure_firewall_policy
    deploy_virtual_hub_connection                            = local.deploy_virtual_hub_connection
    deploy_virtual_hub_express_route_gateway                 = local.deploy_virtual_hub_express_route_gateway
    deploy_virtual_hub_vpn_gateway                           = local.deploy_virtual_hub_vpn_gateway
    deploy_virtual_network_gateway                           = local.deploy_virtual_network_gateway
    deploy_virtual_network_gateway_express_route             = local.deploy_virtual_network_gateway_express_route
    deploy_virtual_network_gateway_vpn                       = local.deploy_virtual_network_gateway_vpn
    deploy_virtual_wan                                       = local.deploy_virtual_wan
    dns_location                                             = local.dns_location
    enable_private_link_by_service                           = local.enable_private_link_by_service
    er_gateway_name                                          = local.er_gateway_name
    er_gateway_pip_name                                      = local.er_gateway_pip_name
    er_gateway_pip_resource_id                               = local.er_gateway_pip_resource_id
    er_gateway_pip_resource_id_prefix                        = local.er_gateway_pip_resource_id_prefix
    er_gateway_resource_id                                   = local.er_gateway_resource_id
    er_gateway_resource_id_prefix                            = local.er_gateway_resource_id_prefix
    hub_network_locations                                    = local.hub_network_locations
    hub_networks                                             = local.hub_networks
    hub_networks_by_location                                 = local.hub_networks_by_location
    hub_virtual_networks_for_dns                             = local.hub_virtual_networks_for_dns
    lookup_private_link_dns_zone_by_service                  = local.lookup_private_link_dns_zone_by_service
    lookup_private_link_group_id_by_service                  = local.lookup_private_link_group_id_by_service
    private_dns_zone_enabled                                 = local.private_dns_zone_enabled
    private_ip_address_allocation_values                     = local.private_ip_address_allocation_values
    private_link_locations                                   = local.private_link_locations
    resource_group_config_by_scope_and_location              = local.resource_group_config_by_scope_and_location
    resource_group_names_by_scope_and_location               = local.resource_group_names_by_scope_and_location
    result_when_location_missing                             = local.result_when_location_missing
    services_by_private_link_dns_zone                        = local.services_by_private_link_dns_zone
    spoke_virtual_networks_for_dns                           = local.spoke_virtual_networks_for_dns
    subnets_by_virtual_network                               = local.subnets_by_virtual_network
    template_file_variables                                  = local.template_file_variables
    virtual_hub_azfw_name                                    = local.virtual_hub_azfw_name
    virtual_hub_azfw_policy_name                             = local.virtual_hub_azfw_policy_name
    virtual_hub_azfw_policy_resource_id                      = local.virtual_hub_azfw_policy_resource_id
    virtual_hub_azfw_policy_resource_id_prefix               = local.virtual_hub_azfw_policy_resource_id_prefix
    virtual_hub_azfw_resource_id                             = local.virtual_hub_azfw_resource_id
    virtual_hub_azfw_resource_id_prefix                      = local.virtual_hub_azfw_resource_id_prefix
    virtual_hub_azfw_zones                                   = local.virtual_hub_azfw_zones
    virtual_hub_express_route_gateway_name                   = local.virtual_hub_express_route_gateway_name
    virtual_hub_express_route_gateway_resource_id            = local.virtual_hub_express_route_gateway_resource_id
    virtual_hub_express_route_gateway_resource_id_prefix     = local.virtual_hub_express_route_gateway_resource_id_prefix
    virtual_hub_locations                                    = local.virtual_hub_locations
    virtual_hub_name                                         = local.virtual_hub_name
    virtual_hub_resource_group_id                            = local.virtual_hub_resource_group_id
    virtual_hub_resource_group_name                          = local.virtual_hub_resource_group_name
    virtual_hub_resource_id                                  = local.virtual_hub_resource_id
    virtual_hub_resource_id_prefix                           = local.virtual_hub_resource_id_prefix
    virtual_hub_vpn_gateway_name                             = local.virtual_hub_vpn_gateway_name
    virtual_hub_vpn_gateway_resource_id                      = local.virtual_hub_vpn_gateway_resource_id
    virtual_hub_vpn_gateway_resource_id_prefix               = local.virtual_hub_vpn_gateway_resource_id_prefix
    virtual_hubs                                             = local.virtual_hubs
    virtual_hubs_by_location                                 = local.virtual_hubs_by_location
    virtual_hubs_by_location_for_existing_virtual_wan        = local.virtual_hubs_by_location_for_existing_virtual_wan
    virtual_hubs_by_location_for_managed_virtual_wan         = local.virtual_hubs_by_location_for_managed_virtual_wan
    virtual_hubs_by_location_for_resource_group_per_location = local.virtual_hubs_by_location_for_resource_group_per_location
    virtual_hubs_by_location_for_shared_resource_group       = local.virtual_hubs_by_location_for_shared_resource_group
    virtual_network_hub_peering_name                         = local.virtual_network_hub_peering_name
    virtual_network_hub_peerings                             = local.virtual_network_hub_peerings
    virtual_network_name                                     = local.virtual_network_name
    virtual_network_resource_group_id                        = local.virtual_network_resource_group_id
    virtual_network_resource_id                              = local.virtual_network_resource_id
    virtual_network_resource_id_prefix                       = local.virtual_network_resource_id_prefix
    virtual_networks_for_dns                                 = local.virtual_networks_for_dns
    virtual_wan_locations                                    = local.virtual_wan_locations
    virtual_wan_name                                         = local.virtual_wan_name
    virtual_wan_resource_group_id                            = local.virtual_wan_resource_group_id
    virtual_wan_resource_id                                  = local.virtual_wan_resource_id
    virtual_wan_resource_id_prefix                           = local.virtual_wan_resource_id_prefix
    vpn_gateway_name                                         = local.vpn_gateway_name
    vpn_gateway_pip_2_name                                   = local.vpn_gateway_pip_2_name
    vpn_gateway_pip_2_resource_id                            = local.vpn_gateway_pip_2_resource_id
    vpn_gateway_pip_name                                     = local.vpn_gateway_pip_name
    vpn_gateway_pip_resource_id                              = local.vpn_gateway_pip_resource_id
    vpn_gateway_pip_resource_id_prefix                       = local.vpn_gateway_pip_resource_id_prefix
    vpn_gateway_resource_id                                  = local.vpn_gateway_resource_id
    vpn_gateway_resource_id_prefix                           = local.vpn_gateway_resource_id_prefix
    vpn_gen1_only_skus                                       = local.vpn_gen1_only_skus
  }
}
