# Generate a random password

# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password
resource "random_password" "this" {
  count = anytrue([for _, v in var.test_infrastructure : v.authentication.password == null]) ? 1 : 0


  length           = 16
  min_lower        = 16 - 4
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "_%@"
}

# Create or source a Resource Group

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = "${var.name_prefix}${var.resource_group_name}"
  location = var.region

  tags = var.tags
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group
data "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.this[0] : data.azurerm_resource_group.this[0]
}

# Manage the network required for the topology

module "vnet" {
  source = "../../modules/vnet"

  for_each = var.vnets

  name                   = each.value.create_virtual_network ? "${var.name_prefix}${each.value.name}" : each.value.name
  create_virtual_network = each.value.create_virtual_network
  resource_group_name    = coalesce(each.value.resource_group_name, local.resource_group.name)
  region                 = var.region

  address_space           = each.value.address_space
  dns_servers             = each.value.dns_servers
  vnet_encryption         = each.value.vnet_encryption
  ddos_protection_plan_id = each.value.ddos_protection_plan_id

  subnets = each.value.subnets

  network_security_groups = {
    for k, v in each.value.network_security_groups : k => merge(v, { name = "${var.name_prefix}${v.name}" })
  }
  route_tables = {
    for k, v in each.value.route_tables : k => merge(v, { name = "${var.name_prefix}${v.name}" })
  }

  tags = var.tags
}

module "vnet_peering" {
  source = "../../modules/vnet_peering"

  for_each = var.vnet_peerings

  local_peer_config = {
    name                = "peer-${each.value.local_vnet_name}-to-${each.value.remote_vnet_name}"
    resource_group_name = coalesce(each.value.local_resource_group_name, local.resource_group.name)
    vnet_name           = each.value.local_vnet_name
  }
  remote_peer_config = {
    name                = "peer-${each.value.remote_vnet_name}-to-${each.value.local_vnet_name}"
    resource_group_name = coalesce(each.value.remote_resource_group_name, local.resource_group.name)
    vnet_name           = each.value.remote_vnet_name
  }
  depends_on = [module.vnet]
}

module "public_ip" {
  source = "../../modules/public_ip"

  region = var.region
  public_ip_addresses = {
    for k, v in var.public_ips.public_ip_addresses : k => merge(v, {
      name                = "${var.name_prefix}${v.name}"
      resource_group_name = coalesce(v.resource_group_name, local.resource_group.name)
    })
  }
  public_ip_prefixes = {
    for k, v in var.public_ips.public_ip_prefixes : k => merge(v, {
      name                = "${var.name_prefix}${v.name}"
      resource_group_name = coalesce(v.resource_group_name, local.resource_group.name)
    })
  }

  tags = var.tags
}

locals {
  remote_virtual_network_ids = merge({ for entry in flatten([
    for val in { for k, v in module.test_infrastructure : k => v.vnet_ids } : [
      for k, v in val : {
        key = k
        val = v
      }
    ]
    ]) : entry.key => entry.val
  }, { for k, v in module.vnet : k => v.virtual_network_id })
}

locals {
  route_tables = {
    for wan_key, wan in var.virtual_wans : wan_key => {
      for rt_item in flatten([
        for hub_key, hub in try(wan.virtual_hubs, {}) : [
          for rt_key, rt in try(hub.route_tables, {}) : {
            key     = rt_key
            hub_key = hub_key
            name    = rt.name
            labels  = try(rt.labels, [])
          }
        ]
        ]) : rt_item.key => {
        name    = rt_item.name
        labels  = rt_item.labels
        hub_key = rt_item.hub_key
      }
    }
  }

  connections = {
    for wan_key, wan in var.virtual_wans : wan_key => {
      for conn_item in flatten([
        for hub_key, hub in try(wan.virtual_hubs, {}) : [
          for conn_key, conn in try(hub.connections, {}) : {
            key             = conn_key
            hub_key         = hub_key
            name            = conn.name
            connection_type = conn.connection_type
            vpn_site_key    = conn.vpn_site_key
            routing         = conn.routing
            vpn_link        = conn.vpn_link
            remote_virtual_network_id = (conn.connection_type == "Vnet"
              ? lookup(local.remote_virtual_network_ids, conn.remote_virtual_network_key, null)
            : null)
          }
        ]
        ]) : conn_item.key => {
        hub_key                   = conn_item.hub_key
        name                      = conn_item.name
        connection_type           = conn_item.connection_type
        remote_virtual_network_id = conn_item.remote_virtual_network_id
        vpn_site_key              = conn_item.vpn_site_key
        routing                   = conn_item.routing
        vpn_link                  = conn_item.vpn_link
      }
    }
  }

  vpn_sites = {
    for wan_key, wan in var.virtual_wans : wan_key => {
      for site_item in flatten([
        for hub_key, hub in try(wan.virtual_hubs, {}) : [
          for site_key, site in try(hub.vpn_sites, {}) : {
            key                 = site_key
            name                = site.name
            region              = site.region
            resource_group_name = site.resource_group_name
            address_cidrs       = site.address_cidrs
            link                = site.link
          }
        ]
        ]) : site_item.key => {
        name                = site_item.name
        region              = site_item.region
        resource_group_name = site_item.resource_group_name
        address_cidrs       = site_item.address_cidrs
        link                = site_item.link
      }
    }
  }
}

module "virtual_wan" {
  source = "../../modules/vwan"

  for_each = var.virtual_wans

  virtual_wan_name    = each.value.create ? "${var.name_prefix}${each.value.name}" : each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, local.resource_group.name)
  region              = coalesce(each.value.region, var.region)

  virtual_hubs = each.value.virtual_hubs
  route_tables = lookup(local.route_tables, each.key, {})
  connections  = lookup(local.connections, each.key, {})
  vpn_sites    = lookup(local.vpn_sites, each.key, {})

  tags = var.tags
}

locals {
  routing_intent = {
    for vwan_key, vwan in var.virtual_wans : vwan_key => {
      for hub_key, hub in try(vwan.virtual_hubs, {}) : hub_key => {
        virtual_hub_id = try(
          module.virtual_wan[vwan_key].virtual_hub_ids[hub_key],
          null
        )
        routing_intent = {
          routing_intent_name = hub.routing_intent.routing_intent_name
          routing_policy = [
            for policy in hub.routing_intent.routing_policy : merge(
              policy,
              {
                next_hop_id = try(
                  module.cloudngfw[policy.next_hop_key]
                  .palo_alto_virtual_network_appliance_id,
                  null
                )
              }
            )
          ]
        }
      }
      if hub.routing_intent != null
    }
  }

  routes = {
    for vwan_key, vwan in var.virtual_wans : vwan_key => {
      for route_item in flatten([
        for hub_key, hub in try(vwan.virtual_hubs, {}) : [
          for rt_key, rt in try(hub.route_tables, {}) : [
            for route_key, route in try(rt.routes, {}) : {
              route_key         = route_key
              name              = route.name
              destinations_type = route.destinations_type
              destinations      = route.destinations
              next_hop_type     = route.next_hop_type
              next_hop_key      = try(route.next_hop_key, null)
              route_table_key   = rt_key
              hub_key           = hub_key
            }
          ]
        ]
        ]) : route_item.route_key => {
        name              = route_item.name
        destinations_type = route_item.destinations_type
        destinations      = route_item.destinations
        next_hop_type     = route_item.next_hop_type
        next_hop_id = try(
          module.cloudngfw[route_item.next_hop_key].palo_alto_virtual_network_appliance_id,
          null
        )
        route_table_id = try(
          module.virtual_wan[vwan_key].route_table_ids[route_item.route_table_key],
          null
        )
      }
    }
  }
}

module "vwan_routes" {
  source = "../../modules/vwan_routes"

  for_each = var.virtual_wans

  routes         = lookup(local.routes, each.key, {})
  routing_intent = lookup(local.routing_intent, each.key, {})
}

# Create Cloud Next-Generation Firewalls

locals {
  vnets = merge(module.vnet, [for env in module.test_infrastructure : env.vnets]...)
}

module "cloudngfw" {
  source = "../../modules/cloudngfw"

  for_each = var.cloudngfws

  name                = "${var.name_prefix}${each.value.name}"
  resource_group_name = local.resource_group.name
  region              = var.region

  attachment_type = each.value.attachment_type
  virtual_network_id = each.value.attachment_type == "vnet" ? (
    local.vnets[each.value.virtual_network_key].virtual_network_id
  ) : null
  untrusted_subnet_id = each.value.attachment_type == "vnet" ? (
    local.vnets[each.value.virtual_network_key].subnet_ids[each.value.untrusted_subnet_key]
  ) : null
  trusted_subnet_id = each.value.attachment_type == "vnet" ? (
    local.vnets[each.value.virtual_network_key].subnet_ids[each.value.trusted_subnet_key]
  ) : null
  virtual_hub_id  = each.value.attachment_type == "vwan" ? module.virtual_wan[each.value.virtual_wan_key].virtual_hub_ids[each.value.virtual_hub_key] : null
  management_mode = each.value.management_mode
  cloudngfw_config = merge(each.value.cloudngfw_config, {
    public_ip_name = each.value.cloudngfw_config.public_ip_keys == null ? (each.value.cloudngfw_config.create_public_ip ? "${
      var.name_prefix}${coalesce(each.value.cloudngfw_config.public_ip_name, "${each.value.name}-pip")
    }" : each.value.cloudngfw_config.public_ip_name) : null
    public_ip_ids = try({ for k, v in module.public_ip.pip_ids : k => v
    if contains(each.value.cloudngfw_config.public_ip_keys, k) }, null)
    egress_nat_ip_ids = try({ for k, v in module.public_ip.pip_ids : k => v
    if contains(each.value.cloudngfw_config.egress_nat_ip_keys, k) }, null)
    destination_nats = {
      for k, v in each.value.cloudngfw_config.destination_nats : k => merge(v, {
        frontend_public_ip_address_id = v.frontend_public_ip_key != null ? lookup(module.public_ip.pip_ids, v.frontend_public_ip_key, null) : null
      })
    }
  })

  tags = var.tags
}

# Create test infrastructure

locals {
  test_vm_authentication = {
    for k, v in var.test_infrastructure : k =>
    merge(
      v.authentication,
      {
        password = coalesce(v.authentication.password, try(random_password.this[0].result, null))
      }
    )
  }
}

module "test_infrastructure" {
  source = "../../modules/test_infrastructure"

  for_each = var.test_infrastructure

  resource_group_name = try(
    "${var.name_prefix}${each.value.resource_group_name}", "${local.resource_group.name}-testenv"
  )
  region = var.region
  vnets = { for k, v in each.value.vnets : k => merge(v, {
    name = "${var.name_prefix}${v.name}"
    hub_vnet_name = try(var.vnets[v.hub_vnet_key].create_virtual_network ?
    "${var.name_prefix}${var.vnets[v.hub_vnet_key].name}" : var.vnets[v.hub_vnet_key].name, null)
    hub_resource_group_name = try(
      coalesce(module.vnet[v.hub_vnet_key].virtual_network_resource_group, local.resource_group.name), null
    )
    network_security_groups = { for kv, vv in v.network_security_groups : kv => merge(vv, {
      name = "${var.name_prefix}${vv.name}" })
    }
    route_tables = { for kv, vv in v.route_tables : kv => merge(vv, {
      name = "${var.name_prefix}${vv.name}" })
    }
    local_peer_config  = try(v.local_peer_config, {})
    remote_peer_config = try(v.remote_peer_config, {})
  }) }
  load_balancers = { for k, v in each.value.load_balancers : k => merge(v, {
    name         = "${var.name_prefix}${v.name}"
    backend_name = coalesce(v.backend_name, "${v.name}-backend")
    public_ip_name = v.frontend_ips.create_public_ip ? (
      "${var.name_prefix}${v.frontend_ips.public_ip_name}"
    ) : v.frontend_ips.public_ip_name
    public_ip_id             = try(module.public_ip.pip_ids[v.frontend_ips.public_ip_key], null)
    public_ip_address        = try(module.public_ip.pip_ip_addresses[v.frontend_ips.public_ip_key], null)
    public_ip_prefix_id      = try(module.public_ip.ippre_ids[v.frontend_ips.public_ip_prefix_key], null)
    public_ip_prefix_address = try(module.public_ip.ippre_ip_prefixes[v.frontend_ips.public_ip_prefix_key], null)
  }) }
  authentication = local.test_vm_authentication[each.key]
  spoke_vms = { for k, v in each.value.spoke_vms : k => merge(v, {
    name           = "${var.name_prefix}${v.name}"
    interface_name = "${var.name_prefix}${coalesce(v.interface_name, "${v.name}-nic")}"
    disk_name      = "${var.name_prefix}${coalesce(v.disk_name, "${v.name}-osdisk")}"
  }) }
  bastions = { for k, v in each.value.bastions : k => merge(v, {
    name           = "${var.name_prefix}${v.name}"
    public_ip_name = v.public_ip_key != null ? null : "${var.name_prefix}${coalesce(v.public_ip_name, "${v.name}-pip")}"
    public_ip_id   = try(module.public_ip.pip_ids[v.public_ip_key], null)
  }) }

  tags       = var.tags
  depends_on = [module.vnet]
}
