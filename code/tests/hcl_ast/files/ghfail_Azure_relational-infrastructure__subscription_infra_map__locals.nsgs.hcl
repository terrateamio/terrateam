locals {
  allow_in_security_rules = {
    for rule_name, rule in var.network_security_rules :
    rule_name => {
      access                 = "Allow"
      direction              = "Inbound"
      protocol               = rule.protocol
      from                   = rule.allow.in.from
      to                     = rule.allow.in.to
      destination_port_names = rule.port_names
      source_port_names      = try(rule.allow.in.from.port_names, null)
    } if try(rule.allow.in != null, false)
  }

  allow_out_security_rules = {
    for rule_name, rule in var.network_security_rules : rule_name => {
      access                 = "Allow"
      direction              = "Outbound"
      protocol               = rule.protocol
      from                   = rule.allow.out.from
      to                     = rule.allow.out.to
      destination_port_names = rule.port_names
      source_port_names      = try(rule.allow.out.from.port_names, null)
    } if try(rule.allow.out != null, false)
  }

  deny_in_security_rules = {
    for rule_name, rule in var.network_security_rules : rule_name => {
      access                 = "Deny"
      direction              = "Inbound"
      protocol               = rule.protocol
      from                   = rule.deny.in.from
      to                     = rule.deny.in.to
      destination_port_names = rule.port_names
      source_port_names      = try(rule.deny.in.from.port_names, null)
    } if try(rule.deny.in != null, false)
  }

  deny_out_security_rules = {
    for rule_name, rule in var.network_security_rules : rule_name => {
      access                 = "Deny"
      direction              = "Outbound"
      protocol               = rule.protocol
      from                   = rule.deny.out.from
      to                     = rule.deny.out.to
      destination_port_names = rule.port_names
      source_port_names      = try(rule.deny.out.from.port_names, null)
    } if try(rule.deny.out != null, false)
  }

  security_rule_port_ranges = {
    for rule_name, rule in local.base_security_rules
    : rule_name => {
      destination_port_range = (rule.destination_port_names == null ? "*" : tostring(null))
      source_port_range      = (rule.source_port_names == null ? "*" : tostring(null))

      destination_port_ranges = (
        rule.destination_port_names == null ? [] :
        [for port_name in rule.destination_port_names : var.network_ports[port_name]]
      )

      source_port_ranges = (
        rule.source_port_names == null ? [] :
        [for port_name in rule.source_port_names : var.network_ports[port_name]]
      )
    }
  }

  base_security_rules = merge(
    local.allow_in_security_rules,
    local.allow_out_security_rules,
    local.deny_in_security_rules,
    local.deny_out_security_rules
  )

  is_source_default = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(rule.from == null)
  }

  is_source_address_space = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.from.address_space, null) != null)
  }

  is_source_network = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.from.network, null) != null)
  }

  is_source_subnet = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.from.subnet, null) != null)
  }

  is_source_vm_set = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.from.vm_set, null) != null)
  }

  is_destination_default = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(rule.to == null)
  }

  is_destination_address_space = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.to.address_space, null) != null)
  }

  is_destination_network = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.to.network, null) != null)
  }

  is_destination_subnet = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.to.subnet, null) != null)
  }

  is_destination_vm_set = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tobool(try(rule.to.vm_set, null) != null)
  }

  destination_address_spaces_to_address_spaces = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tostring(local.network_address_spaces[rule.to.address_space].address_space)
    if local.is_destination_address_space[rule_name]
  }

  destination_address_space_sets = {
    for rule_name, rule in local.base_security_rules :
    rule_name => toset(local.network_address_spaces[rule.to.network.name].address_spaces)
    if local.is_destination_network[rule_name]
  }

  destination_subnets_to_address_spaces = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tostring(local.network_address_spaces[rule.to.subnet.network_name].subnets[rule.to.subnet.subnet_name].address_space)
    if local.is_destination_subnet[rule_name]
  }

  destination_app_security_group_ids = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tostring(azurerm_application_security_group.application_security_group[rule.to.vm_set.name].id)
    if local.is_destination_vm_set[rule_name]
  }

  destination_address_spaces = merge(
    local.destination_address_spaces_to_address_spaces,
    local.destination_subnets_to_address_spaces
  )

  source_address_spaces_to_address_spaces = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tostring(local.network_address_spaces[rule.from.address_space].address_space)
    if local.is_source_address_space[rule_name]
  }

  source_address_space_sets = {
    for rule_name, rule in local.base_security_rules :
    rule_name => toset(local.network_address_spaces[rule.from.network.name].address_spaces)
    if local.is_source_network[rule_name]
  }

  source_subnets_to_address_spaces = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tostring(local.network_address_spaces[rule.from.subnet.network_name].subnets[rule.from.subnet.subnet_name].address_space)
    if local.is_source_subnet[rule_name]
  }

  source_app_security_group_ids = {
    for rule_name, rule in local.base_security_rules :
    rule_name => tostring(azurerm_application_security_group.application_security_group[rule.from.vm_set.name].id)
    if local.is_source_vm_set[rule_name]
  }

  source_address_spaces = merge(
    local.source_address_spaces_to_address_spaces,
    local.source_subnets_to_address_spaces
  )

  destination_network_tuples = {
    for rule_name, rule in local.base_security_rules :
    rule_name => (
      local.is_destination_default[rule_name] ?
      local.default_network_tuple :
      {
        address_space          = tostring(lookup(local.destination_address_spaces, rule_name, null))
        address_spaces         = lookup(local.destination_address_space_sets, rule_name, [])
        app_security_group_ids = compact([lookup(local.destination_app_security_group_ids, rule_name, null)])
      }
    )
  }

  source_network_tuples = {
    for rule_name, rule in local.base_security_rules :
    rule_name => (
      local.is_source_default[rule_name] ?
      local.default_network_tuple :
      {
        address_space          = tostring(lookup(local.source_address_spaces, rule_name, null))
        address_spaces         = lookup(local.source_address_space_sets, rule_name, [])
        app_security_group_ids = compact([lookup(local.source_app_security_group_ids, rule_name, null)])
      }
    )
  }

  security_rules = {
    for rule_name, rule in local.base_security_rules :
    rule_name => {
      access                                     = rule.access
      direction                                  = rule.direction
      protocol                                   = rule.protocol
      destination_address_prefix                 = local.destination_network_tuples[rule_name].address_space
      destination_address_prefixes               = local.destination_network_tuples[rule_name].address_spaces
      destination_application_security_group_ids = local.destination_network_tuples[rule_name].app_security_group_ids
      destination_port_range                     = local.security_rule_port_ranges[rule_name].destination_port_range
      destination_port_ranges                    = local.security_rule_port_ranges[rule_name].destination_port_ranges
      source_address_prefix                      = local.source_network_tuples[rule_name].address_space
      source_address_prefixes                    = local.source_network_tuples[rule_name].address_spaces
      source_application_security_group_ids      = local.source_network_tuples[rule_name].app_security_group_ids
      source_port_range                          = local.security_rule_port_ranges[rule_name].source_port_range
      source_port_ranges                         = local.security_rule_port_ranges[rule_name].source_port_ranges
    }
  }

  default_network_tuple = {
    address_space          = "*"
    address_spaces         = []
    app_security_group_ids = []
  }

  # default_network_tuple = {
  #   address_space         = tostring("*")
  #   address_spaces        = toset([])
  #   app_security_group_id = tostring(null)
  #   port_range            = tostring("*")
  #   port_ranges           = toset([])
  # }

  network_security_groups_to_provision = tomap({
    for nsg_name, nsg in var.network_security_groups :
    nsg_name => {
      location_name       = nsg.location_name
      resource_group_name = nsg.resource_group_name
      name                = local.network_security_group_names[nsg_name]
      tags                = nsg.tags

      security_rules = {
        for rule_index, rule_name in nsg.security_rules : rule_name => {
          priority = (100 + rule_index)
          config   = local.security_rules[rule_name]
        }
      }
    }
  })
}
