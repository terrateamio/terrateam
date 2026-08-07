resource "sdwan_cedge_aaa_feature_template" "cedge_aaa_feature_template" {
  for_each                      = { for t in try(local.edge_feature_templates.aaa_templates, {}) : t.name => t }
  name                          = each.value.name
  description                   = each.value.description
  device_types                  = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.aaa_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  dot1x_authentication          = try(each.value.dot1x_authentication, null)
  dot1x_authentication_variable = try(each.value.dot1x_authentication_variable, null)
  dot1x_accounting              = try(each.value.dot1x_accounting, null)
  dot1x_accounting_variable     = try(each.value.dot1x_accounting_variable, null)
  server_groups_priority_order  = join(",", try(each.value.authentication_and_authorization_order, local.defaults.sdwan.edge_feature_templates.aaa_templates.authentication_and_authorization_order))
  users = try(length(each.value.users) == 0, true) ? null : [for user in each.value.users : {
    name                     = user.name
    password                 = user.password
    secret                   = user.secret
    privilege_level          = try(user.privilege_level, null)
    privilege_level_variable = try(user.privilege_level_variable, null)
    optional                 = try(user.optional, null)
    ssh_pubkeys = try(length(user.ssh_rsa_keys) == 0, true) ? null : [for key in user.ssh_rsa_keys : {
      key_string = key
      key_type   = "rsa"
    }]
  }]
  radius_server_groups = try(length(each.value.radius_server_groups) == 0, true) ? null : [for group in each.value.radius_server_groups : {
    group_name                = group.name
    vpn_id                    = try(group.vpn_id, null)
    source_interface          = try(group.source_interface, null)
    source_interface_variable = try(group.source_interface_variable, null)
    servers = !can(group.servers) ? null : [for server in group.servers : {
      address                      = server.address
      authentication_port          = try(server.authentication_port, null)
      authentication_port_variable = try(server.authentication_port_variable, null)
      accounting_port              = try(server.accounting_port, null)
      accounting_port_variable     = try(server.accounting_port_variable, null)
      timeout                      = try(server.timeout, null)
      timeout_variable             = try(server.timeout_variable, null)
      retransmit                   = try(server.retransmit_count, null)
      retransmit_variable          = try(server.retransmit_count_variable, null)
      key_type                     = try(server.key_type, null)
      key_type_variable            = try(server.key_type_variable, null)
      key                          = server.key
      secret_key                   = server.secret_key
      encryption_type              = 6
    }]
  }]
  radius_clients = try(length(each.value.radius_dynamic_author.clients) == 0, true) ? null : [for client in each.value.radius_dynamic_author.clients : {
    client_ip          = try(client.ip, null)
    client_ip_variable = try(client.ip_variable, null)
    vpn_configurations = [{
      vpn_id          = try(client.vpn_id, null)
      vpn_id_variable = try(client.vpn_id_variable, null)
      server_key      = try(client.server_key, null)
    }]
  }]
  radius_dynamic_author_server_key                   = try(each.value.radius_dynamic_author.server_key, null)
  radius_dynamic_author_server_key_variable          = try(each.value.radius_dynamic_author.server_key_variable, null)
  radius_dynamic_author_domain_stripping             = try(each.value.radius_dynamic_author.domain_stripping, null)
  radius_dynamic_author_domain_stripping_variable    = try(each.value.radius_dynamic_author.domain_stripping_variable, null)
  radius_dynamic_author_authentication_type          = try(each.value.radius_dynamic_author.authentication_type, null)
  radius_dynamic_author_authentication_type_variable = try(each.value.radius_dynamic_author.authentication_type_variable, null)
  radius_dynamic_author_port                         = try(each.value.radius_dynamic_author.port, null)
  radius_dynamic_author_port_variable                = try(each.value.radius_dynamic_author.port_variable, null)
  radius_trustsec_cts_authorization_list             = try(each.value.radius_trustsec.cts_authorization_list, null)
  radius_trustsec_cts_authorization_list_variable    = try(each.value.radius_trustsec.cts_authorization_list_variable, null)
  radius_trustsec_group                              = try(each.value.radius_trustsec.server_group, null)
  tacacs_server_groups = try(length(each.value.tacacs_server_groups) == 0, true) ? null : [for group in each.value.tacacs_server_groups : {
    group_name                = group.name
    vpn_id                    = try(group.vpn_id, null)
    source_interface          = try(group.source_interface, null)
    source_interface_variable = try(group.source_interface_variable, null)
    servers = try(length(group.servers) == 0, true) ? null : [for server in group.servers : {
      address          = server.address
      key              = server.key
      secret_key       = server.secret_key
      encryption_type  = 6
      port             = try(server.port, null)
      port_variable    = try(server.port_variable, null)
      timeout          = try(server.timeout, null)
      timeout_variable = try(server.timeout_variable, null)
    }]
  }]
  accounting_rules = try(length(each.value.accounting_rules) == 0, true) ? null : [for rule in each.value.accounting_rules : {
    name                = index(each.value.accounting_rules, rule)
    method              = rule.method
    privilege_level     = try(rule.privilege_level, null)
    start_stop          = try(rule.start_stop, null)
    start_stop_variable = try(rule.start_stop_variable, null)
    groups              = join(",", rule.groups)
  }]
  authorization_console                  = try(each.value.authorization_console, null)
  authorization_console_variable         = try(each.value.authorization_console_variable, null)
  authorization_config_commands          = try(each.value.authorization_config_commands, null)
  authorization_config_commands_variable = try(each.value.authorization_config_commands_variable, null)
  authorization_rules = try(length(each.value.authorization_rules) == 0, true) ? null : [for rule in each.value.authorization_rules : {
    name            = index(each.value.authorization_rules, rule)
    method          = rule.method
    privilege_level = rule.privilege_level
    groups          = join(",", rule.groups)
    authenticated   = try(rule.authenticated, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cedge_global_feature_template" "cedge_global_feature_template" {
  for_each                      = { for t in try(local.edge_feature_templates.global_settings_templates, {}) : t.name => t }
  name                          = each.value.name
  description                   = each.value.description
  device_types                  = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.global_settings_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  arp_proxy                     = try(each.value.arp_proxy, null)
  arp_proxy_variable            = try(each.value.arp_proxy_variable, null)
  bootp                         = try(each.value.ignore_bootp, null)
  bootp_variable                = try(each.value.ignore_bootp_variable, null)
  cdp                           = try(each.value.cdp, null)
  cdp_variable                  = try(each.value.cdp_variable, null)
  console_logging               = try(each.value.console_logging, null)
  console_logging_variable      = try(each.value.console_logging_variable, null)
  domain_lookup                 = try(each.value.domain_lookup, null)
  domain_lookup_variable        = try(each.value.domain_lookup_variable, null)
  ftp_passive                   = try(each.value.ftp_passive, null)
  ftp_passive_variable          = try(each.value.ftp_passive_variable, null)
  http_authentication           = try(each.value.http_authentication, null)
  http_authentication_variable  = try(each.value.http_authentication_variable, null)
  http_server                   = try(each.value.http_server, null)
  http_server_variable          = try(each.value.http_server_variable, null)
  https_server                  = try(each.value.https_server, null)
  https_server_variable         = try(each.value.https_server_variable, null)
  ip_source_routing             = try(each.value.ip_source_routing, null)
  ip_source_routing_variable    = try(each.value.ip_source_routing_variable, null)
  line_vty                      = try(each.value.telnet_outbound, null)
  line_vty_variable             = try(each.value.telnet_outbound_variable, null)
  lldp                          = try(each.value.lldp, null)
  lldp_variable                 = try(each.value.lldp_variable, null)
  nat64_tcp_timeout             = try(each.value.nat64_tcp_timeout, null)
  nat64_tcp_timeout_variable    = try(each.value.nat64_tcp_timeout_variable, null)
  nat64_udp_timeout             = try(each.value.nat64_udp_timeout, null)
  nat64_udp_timeout_variable    = try(each.value.nat64_udp_timeout_variable, null)
  rsh_rcp                       = try(each.value.rsh_rcp, null)
  rsh_rcp_variable              = try(each.value.rsh_rcp_variable, null)
  snmp_ifindex_persist          = try(each.value.snmp_ifindex_persist, null)
  snmp_ifindex_persist_variable = try(each.value.snmp_ifindex_persist_variable, null)
  source_interface              = try(each.value.source_interface, null)
  source_interface_variable     = try(each.value.source_interface_variable, null)
  ssh_version                   = try(each.value.ssh_version, null)
  ssh_version_variable          = try(each.value.ssh_version_variable, null)
  tcp_keepalives_in             = try(each.value.tcp_keepalives_in, null)
  tcp_keepalives_in_variable    = try(each.value.tcp_keepalives_in_variable, null)
  tcp_keepalives_out            = try(each.value.tcp_keepalives_out, null)
  tcp_keepalives_out_variable   = try(each.value.tcp_keepalives_out_variable, null)
  tcp_small_servers             = try(each.value.tcp_small_servers, null)
  tcp_small_servers_variable    = try(each.value.tcp_small_servers_variable, null)
  udp_small_servers             = try(each.value.udp_small_servers, null)
  udp_small_servers_variable    = try(each.value.udp_small_servers_variable, null)
  vty_logging                   = try(each.value.vty_logging, null)
  vty_logging_variable          = try(each.value.vty_logging_variable, null)
  depends_on                    = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cedge_igmp_feature_template" "cedge_igmp_feature_template" {
  for_each     = { for t in try(local.edge_feature_templates.igmp_templates, {}) : t.name => t }
  name         = each.value.name
  description  = each.value.description
  device_types = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.igmp_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  interfaces = try(length(each.value.interfaces) == 0, true) ? null : [for interface in each.value.interfaces : {
    name          = try(interface.name, null)
    name_variable = try(interface.name_variable, null)
    optional      = try(interface.optional, null)
    join_groups = !can(interface.join_groups) ? null : [for group in interface.join_groups : {
      group_address          = try(group.group_address, null)
      group_address_variable = try(group.group_address_variable, null)
      source                 = try(group.source, null)
      source_variable        = try(group.source_variable, null)
    }]
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_banner_feature_template" "cisco_banner_feature_template" {
  for_each       = { for t in try(local.edge_feature_templates.banner_templates, {}) : t.name => t }
  name           = each.value.name
  description    = each.value.description
  device_types   = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.banner_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  login          = try(each.value.login, null)
  login_variable = try(each.value.login_variable, null)
  motd           = try(each.value.motd, null)
  motd_variable  = try(each.value.motd_variable, null)
  depends_on     = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_bfd_feature_template" "cisco_bfd_feature_template" {
  for_each               = { for t in try(local.edge_feature_templates.bfd_templates, {}) : t.name => t }
  name                   = each.value.name
  description            = each.value.description
  device_types           = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.bfd_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  multiplier             = try(each.value.multiplier, null)
  multiplier_variable    = try(each.value.multiplier_variable, null)
  poll_interval          = try(each.value.poll_interval, null)
  poll_interval_variable = try(each.value.poll_interval_variable, null)
  default_dscp           = try(each.value.default_dscp, null)
  default_dscp_variable  = try(each.value.default_dscp_variable, null)
  colors = try(length(each.value.colors) == 0, true) ? null : [for color in each.value.colors : {
    color                   = try(color.color, null)
    color_variable          = try(color.color_variable, null)
    hello_interval          = try(color.hello_interval, null)
    hello_interval_variable = try(color.hello_interval_variable, null)
    multiplier              = try(color.multiplier, null)
    multiplier_variable     = try(color.multiplier_variable, null)
    pmtu_discovery          = try(color.path_mtu_discovery, null)
    pmtu_discovery_variable = try(color.path_mtu_discovery_variable, null)
    dscp                    = try(color.default_dscp, null)
    dscp_variable           = try(color.dscp_variable, null)
    optional                = try(color.optional, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_bgp_feature_template" "cisco_bgp_feature_template" {
  for_each                     = { for t in try(local.edge_feature_templates.bgp_templates, {}) : t.name => t }
  name                         = each.value.name
  description                  = each.value.description
  device_types                 = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.bgp_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  always_compare_med           = try(each.value.always_compare_med, null)
  always_compare_med_variable  = try(each.value.always_compare_med_variable, null)
  as_number                    = try(each.value.as_number, null)
  as_number_variable           = try(each.value.as_number_variable, null)
  compare_router_id            = try(each.value.compare_router_id, null)
  compare_router_id_variable   = try(each.value.compare_router_idr_variable, null)
  deterministic_med            = try(each.value.deterministic_med, null)
  deterministic_med_variable   = try(each.value.deterministic_med_variable, null)
  distance_external            = try(each.value.distance_external, null)
  distance_external_variable   = try(each.value.distance_external_variable, null)
  distance_internal            = try(each.value.distance_internal, null)
  distance_internal_variable   = try(each.value.distance_internal_variable, null)
  distance_local               = try(each.value.distance_local, null)
  distance_local_variable      = try(each.value.distance_local_variable, null)
  holdtime                     = try(each.value.holdtime, null)
  holdtime_variable            = try(each.value.holdtime_variable, null)
  keepalive                    = try(each.value.keepalive, null)
  keepalive_variable           = try(each.value.keepalive_variable, null)
  missing_med_worst            = try(each.value.missing_med_as_worst, null)
  missing_med_worst_variable   = try(each.value.missing_med_as_worst_variable, null)
  multipath_relax              = try(each.value.multipath_relax, null)
  multipath_relax_variable     = try(each.value.multipath_relax_variable, null)
  propagate_aspath             = try(each.value.propagate_as_path, null)
  propagate_aspath_variable    = try(each.value.propagate_as_path_variable, null)
  propagate_community          = try(each.value.propagate_community, null)
  propagate_community_variable = try(each.value.propagate_community_variable, null)
  router_id                    = try(each.value.router_id, null)
  router_id_variable           = try(each.value.router_id_variable, null)
  shutdown                     = try(each.value.shutdown, null)
  shutdown_variable            = try(each.value.shutdown_variable, null)
  address_families = flatten([
    try(each.value.ipv4_address_family, null) == null ? [] : [{
      family_type                            = "ipv4-unicast"
      default_information_originate          = try(each.value.ipv4_address_family.default_information_originate, null)
      default_information_originate_variable = try(each.value.ipv4_address_family.default_information_originate_variable, null)
      maximum_paths                          = try(each.value.ipv4_address_family.maximum_paths, null)
      maximum_paths_variable                 = try(each.value.ipv4_address_family.maximum_paths_variable, null)
      table_map_filter                       = try(each.value.ipv4_address_family.table_map_filter, null)
      table_map_filter_variable              = try(each.value.ipv4_address_family.table_map_filter_variable, null)
      table_map_policy                       = try(each.value.ipv4_address_family.table_map_policy, null)
      table_map_policy_variable              = try(each.value.ipv4_address_family.table_map_policy_variable, null)
      ipv4_aggregate_addresses = try(length(each.value.ipv4_address_family.aggregate_addresses) == 0, true) ? null : [for p in each.value.ipv4_address_family.aggregate_addresses : {
        prefix                = try(p.prefix, null)
        prefix_variable       = try(p.prefix_variable, null)
        as_set_path           = try(p.as_set_path, null)
        as_set_path_variable  = try(p.as_set_path_variable, null)
        summary_only          = try(p.summary_only, null)
        summary_only_variable = try(p.summary_only_variable, null)
        optional              = try(p.optional, null)
      }]
      ipv4_networks = try(length(each.value.ipv4_address_family.networks) == 0, true) ? null : [for p in each.value.ipv4_address_family.networks : {
        prefix          = try(p.prefix, null)
        prefix_variable = try(p.prefix_variable, null)
        optional        = try(p.optional, null)
      }]
      redistribute_routes = try(length(each.value.ipv4_address_family.redistributes) == 0, true) ? null : [for p in each.value.ipv4_address_family.redistributes : {
        protocol              = try(p.protocol, null)
        protocol_variable     = try(p.protocol_variable, null)
        route_policy          = try(p.route_policy, null)
        route_policy_variable = try(p.route_policy_variable, null)
        optional              = try(p.optional, null)
      }]
    }],
    try(each.value.ipv6_address_family, null) == null ? [] : [{
      family_type                            = "ipv6-unicast"
      default_information_originate          = try(each.value.ipv6_address_family.default_information_originate, null)
      default_information_originate_variable = try(each.value.ipv6_address_family.default_information_originate_variable, null)
      maximum_paths                          = try(each.value.ipv6_address_family.maximum_paths, null)
      maximum_paths_variable                 = try(each.value.ipv6_address_family.maximum_paths_variable, null)
      table_map_filter                       = try(each.value.ipv6_address_family.table_map_filter, null)
      table_map_filter_variable              = try(each.value.ipv6_address_family.table_map_filter_variable, null)
      table_map_policy                       = try(each.value.ipv6_address_family.table_map_policy, null)
      table_map_policy_variable              = try(each.value.ipv6_address_family.table_map_policy_variable, null)
      ipv6_aggregate_addresses = try(length(each.value.ipv6_address_family.aggregate_addresses) == 0, true) ? null : [for p in each.value.ipv6_address_family.aggregate_addresses : {
        prefix                = try(p.prefix, null)
        prefix_variable       = try(p.prefix_variable, null)
        as_set_path           = try(p.as_set_path, null)
        as_set_path_variable  = try(p.as_set_path_variable, null)
        summary_only          = try(p.summary_only, null)
        summary_only_variable = try(p.summary_only_variable, null)
        optional              = try(p.optional, null)
      }]
      ipv6_networks = try(length(each.value.ipv6_address_family.networks) == 0, true) ? null : [for p in each.value.ipv6_address_family.networks : {
        prefix          = try(p.prefix, null)
        prefix_variable = try(p.prefix_variable, null)
        optional        = try(p.optional, null)
      }]
      redistribute_routes = try(length(each.value.ipv6_address_family.redistributes) == 0, true) ? null : [for p in each.value.ipv6_address_family.redistributes : {
        protocol              = try(p.protocol, null)
        protocol_variable     = try(p.protocol_variable, null)
        route_policy          = try(p.route_policy, null)
        route_policy_variable = try(p.route_policy_variable, null)
        optional              = try(p.optional, null)
      }]
    }]
  ])
  ipv4_neighbors = try(length(each.value.ipv4_address_family.neighbors) == 0, true) ? null : [for n in each.value.ipv4_address_family.neighbors : {
    address                      = try(n.address, null)
    address_variable             = try(n.address_variable, null)
    allow_as_in                  = try(n.allow_as_in, null)
    allow_as_in_variable         = try(n.allow_as_in_variable, null)
    as_override                  = try(n.as_override, null)
    as_override_variable         = try(n.as_override_variable, null)
    description                  = try(n.description, null)
    description_variable         = try(n.description_variable, null)
    ebgp_multihop                = try(n.ebgp_multihop, null)
    ebgp_multihop_variable       = try(n.ebgp_multihop_variable, null)
    holdtime                     = try(n.holdtime, null)
    holdtime_variable            = try(n.holdtime_variable, null)
    keepalive                    = try(n.keepalive, null)
    keepalive_variable           = try(n.keepalive_variable, null)
    next_hop_self                = try(n.next_hop_self, null)
    next_hop_self_variable       = try(n.next_hop_self_variable, null)
    password                     = try(n.password, null)
    password_variable            = try(n.password_variable, null)
    remote_as                    = try(n.remote_as, null)
    remote_as_variable           = try(n.remote_as_variable, null)
    send_community               = try(n.send_community, null)
    send_community_variable      = try(n.send_community_variable, null)
    send_ext_community           = try(n.send_extended_community, null)
    send_ext_community_variable  = try(n.send_extended_community_variable, null)
    send_label                   = try(n.send_label, null)
    send_label_variable          = try(n.send_label_variable, null)
    send_label_explicit          = try(n.send_label_explicit_null, null)
    send_label_explicit_variable = try(n.send_label_explicit_null_variable, null)
    shutdown                     = try(n.shutdown, null)
    shutdown_variable            = try(n.shutdown_variable, null)
    source_interface             = try(n.source_interface, null)
    source_interface_variable    = try(n.source_interface_variable, null)
    optional                     = try(n.optional, null)
    optional_variable            = try(n.optional_variable, null)
    address_families = try(length(n.address_families) == 0, true) ? null : [for af in n.address_families : {
      family_type                            = try(af.family_type, null)
      maximum_prefixes                       = try(af.maximum_prefixes, null)
      maximum_prefixes_variable              = try(af.maximum_prefixes_variable, null)
      maximum_prefixes_restart               = try(af.maximum_prefixes_restart, null)
      maximum_prefixes_restart_variable      = try(af.maximum_prefixes_restart_variable, null)
      maximum_prefixes_threshold             = try(af.maximum_prefixes_threshold, null)
      maximum_prefixes_threshold_variable    = try(af.maximum_prefixes_threshold_variable, null)
      maximum_prefixes_warning_only          = try(af.maximum_prefixes_warning_only, null)
      maximum_prefixes_warning_only_variable = try(af.maximum_prefixes_warning_only_variable, null)
      optional                               = try(af.optional, null)
      optional_variable                      = try(af.optional_variable, null)
      route_policies = try(af.route_policy_in, af.route_policy_in_variable, af.route_policy_out, af.route_policy_out_variable, null) == null ? null : flatten([
        try(af.route_policy_in, af.route_policy_in_variable, null) == null ? [] : [{
          direction            = "in"
          policy_name          = try(af.route_policy_in, null)
          policy_name_variable = try(af.route_policy_in_variable, null)
        }],
        try(af.route_policy_out, null) == null && try(af.route_policy_out_variable, null) == null ? [] : [{
          direction            = "out"
          policy_name          = try(af.route_policy_out, null)
          policy_name_variable = try(af.route_policy_out_variable, null)
        }]
      ])
    }]
  }]
  ipv6_neighbors = try(length(each.value.ipv6_address_family.neighbors) == 0, true) ? null : [for n in each.value.ipv6_address_family.neighbors : {
    address                      = try(n.address, null)
    address_variable             = try(n.address_variable, null)
    allow_as_in                  = try(n.allow_as_in, null)
    allow_as_in_variable         = try(n.allow_as_in_variable, null)
    as_override                  = try(n.as_override, null)
    as_override_variable         = try(n.as_override_variable, null)
    description                  = try(n.description, null)
    description_variable         = try(n.description_variable, null)
    ebgp_multihop                = try(n.ebgp_multihop, null)
    ebgp_multihop_variable       = try(n.ebgp_multihop_variable, null)
    holdtime                     = try(n.holdtime, null)
    holdtime_variable            = try(n.holdtime_variable, null)
    keepalive                    = try(n.keepalive, null)
    keepalive_variable           = try(n.keepalive_variable, null)
    next_hop_self                = try(n.next_hop_self, null)
    next_hop_self_variable       = try(n.next_hop_self_variable, null)
    password                     = try(n.password, null)
    password_variable            = try(n.password_variable, null)
    remote_as                    = try(n.remote_as, null)
    remote_as_variable           = try(n.remote_as_variable, null)
    send_community               = try(n.send_community, null)
    send_community_variable      = try(n.send_community_variable, null)
    send_ext_community           = try(n.send_extended_community, null)
    send_ext_community_variable  = try(n.send_extended_community_variable, null)
    send_label                   = try(n.send_label, null)
    send_label_variable          = try(n.send_label_variable, null)
    send_label_explicit          = try(n.send_label_explicit_null, null)
    send_label_explicit_variable = try(n.send_label_explicit_null_variable, null)
    shutdown                     = try(n.shutdown, null)
    shutdown_variable            = try(n.shutdown_variable, null)
    source_interface             = try(n.source_interface, null)
    source_interface_variable    = try(n.source_interface_variable, null)
    optional                     = try(n.optional, null)
    optional_variable            = try(n.optional_variable, null)
    address_families = try(length(n.address_families) == 0, true) ? null : [for af in n.address_families : {
      family_type                            = try(af.family_type, null)
      maximum_prefixes                       = try(af.maximum_prefixes, null)
      maximum_prefixes_variable              = try(af.maximum_prefixes_variable, null)
      maximum_prefixes_restart               = try(af.maximum_prefixes_restart, null)
      maximum_prefixes_restart_variable      = try(af.maximum_prefixes_restart_variable, null)
      maximum_prefixes_threshold             = try(af.maximum_prefixes_threshold, null)
      maximum_prefixes_threshold_variable    = try(af.maximum_prefixes_threshold_variable, null)
      maximum_prefixes_warning_only          = try(af.maximum_prefixes_warning_only, null)
      maximum_prefixes_warning_only_variable = try(af.maximum_prefixes_warning_only_variable, null)
      optional                               = try(af.optional, null)
      optional_variable                      = try(af.optional_variable, null)
      route_policies = try(af.route_policy_in, af.route_policy_in_variable, af.route_policy_out, af.route_policy_out_variable, null) == null ? null : flatten([
        try(af.route_policy_in, af.route_policy_in_variable, null) == null ? [] : [{
          direction            = "in"
          policy_name          = try(af.route_policy_in, null)
          policy_name_variable = try(af.route_policy_in_variable, null)
        }],
        try(af.route_policy_out, null) == null && try(af.route_policy_out_variable, null) == null ? [] : [{
          direction            = "out"
          policy_name          = try(af.route_policy_out, null)
          policy_name_variable = try(af.route_policy_out_variable, null)
        }]
      ])
    }]
  }]
  ipv4_route_targets = try(length(each.value.ipv4_address_family.route_targets) == 0, true) ? null : [for rt in each.value.ipv4_address_family.route_targets : {
    optional        = try(rt.optional, null)
    vpn_id          = try(rt.vpn_id, null)
    vpn_id_variable = try(rt.vpn_id_variable, null)
    export = try(length(rt.exports) == 0, true) ? null : [for e in rt.exports : {
      asn_ip          = try(e.asn_ip, null)
      asn_ip_variable = try(e.asn_ip_variable, null)
    }]
    import = try(length(rt.imports) == 0, true) ? null : [for i in rt.imports : {
      asn_ip          = try(i.asn_ip, null)
      asn_ip_variable = try(i.asn_ip_variable, null)
    }]
  }]
  ipv6_route_targets = try(length(each.value.ipv6_address_family.route_targets) == 0, true) ? null : [for rt in each.value.ipv6_address_family.route_targets : {
    optional        = try(rt.optional, null)
    vpn_id          = try(rt.vpn_id, null)
    vpn_id_variable = try(rt.vpn_id_variable, null)
    export = try(length(rt.exports) == 0, true) ? null : [for e in rt.exports : {
      asn_ip          = try(e.asn_ip, null)
      asn_ip_variable = try(e.asn_ip_variable, null)
    }]
    import = try(length(rt.imports) == 0, true) ? null : [for i in rt.imports : {
      asn_ip          = try(i.asn_ip, null)
      asn_ip_variable = try(i.asn_ip_variable, null)
    }]
  }]
  mpls_interfaces = try(length(each.value.mpls_interfaces) == 0, true) ? null : [for m in each.value.mpls_interfaces : {
    interface_name          = try(m.interface_name, null)
    interface_name_variable = try(m.interface_name_variable, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_dhcp_server_feature_template" "cisco_dhcp_server_feature_template" {
  for_each                   = { for t in try(local.edge_feature_templates.dhcp_server_templates, {}) : t.name => t }
  name                       = each.value.name
  description                = each.value.description
  device_types               = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.dhcp_server_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  address_pool               = try(each.value.address_pool, null)
  address_pool_variable      = try(each.value.address_pool_variable, null)
  default_gateway            = try(each.value.default_gateway, null)
  default_gateway_variable   = try(each.value.default_gateway_variable, null)
  dns_servers                = try(each.value.dns_servers, null)
  dns_servers_variable       = try(each.value.dns_servers_variable, null)
  domain_name                = try(each.value.domain_name, null)
  domain_name_variable       = try(each.value.domain_name_variable, null)
  exclude_addresses          = try(each.value.exclude_addresses, each.value.exclude_addresses_ranges, null) == null ? null : concat(try(each.value.exclude_addresses, []), [for r in try(each.value.exclude_addresses_ranges, []) : "${r.from}-${r.to}"])
  exclude_addresses_variable = try(each.value.exclude_addresses_variable, null)
  interface_mtu              = try(each.value.interface_mtu, null)
  interface_mtu_variable     = try(each.value.interface_mtu_variable, null)
  lease_time                 = try(each.value.lease_time, null)
  lease_time_variable        = try(each.value.lease_time_variable, null)
  tftp_servers               = try(each.value.tftp_servers, null)
  tftp_servers_variable      = try(each.value.tftp_servers_variable, null)
  options = try(length(each.value.options) == 0, true) ? null : [for option in each.value.options : {
    ascii                = try(option.ascii, null)
    ascii_variable       = try(option.ascii_variable, null)
    hex                  = try(option.hex, null)
    hex_variable         = try(option.hex_variable, null)
    ip_address           = try(option.ip_addresses, null)
    ip_address_variable  = try(option.ip_addresses_variable, null)
    option_code          = try(option.option_code, null)
    option_code_variable = try(option.option_code_variable, null)
  }]
  static_leases = try(length(each.value.static_leases) == 0, true) ? null : [for lease in each.value.static_leases : {
    ip_address           = try(lease.ip_address, null)
    ip_address_variable  = try(lease.ip_address_variable, null)
    mac_address          = try(lease.mac_address, null)
    mac_address_variable = try(lease.mac_address_variable, null)
    hostname             = try(lease.hostname, null)
    hostname_variable    = try(lease.hostname_variable, null)
    optional             = try(lease.optional, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_logging_feature_template" "cisco_logging_feature_template" {
  for_each               = { for t in try(local.edge_feature_templates.logging_templates, {}) : t.name => t }
  name                   = each.value.name
  description            = each.value.description
  device_types           = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.logging_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  disk_logging           = try(each.value.disk_logging, null)
  disk_logging_variable  = try(each.value.disk_logging_variable, null)
  log_rotations          = try(each.value.log_rotations, null)
  log_rotations_variable = try(each.value.log_rotations_variable, null)
  max_size               = try(each.value.max_size, null)
  max_size_variable      = try(each.value.max_size_variable, null)
  ipv4_servers = try(length(each.value.ipv4_servers) == 0, true) ? null : [for server in each.value.ipv4_servers : {
    hostname_ip               = try(server.hostname_ip, null)
    hostname_ip_variable      = try(server.hostname_ip_variable, null)
    enable_tls                = try(server.enable_tls, null)
    enable_tls_variable       = try(server.enable_tls_variable, null)
    logging_level             = try(server.logging_level, null)
    logging_level_variable    = try(server.logging_level_variable, null)
    source_interface          = try(server.source_interface, null)
    source_interface_variable = try(server.source_interface_variable, null)
    custom_profile            = try(server.tls_profile, null) == null ? null : true
    profile                   = try(server.tls_profile, null)
    profile_variable          = try(server.tls_profile_variable, null)
    optional                  = try(server.optional, null)
    vpn_id                    = try(server.vpn_id, null)
    vpn_id_variable           = try(server.vpn_id_variable, null)
  }]
  ipv6_servers = try(length(each.value.ipv6_servers) == 0, true) ? null : [for server in each.value.ipv6_servers : {
    hostname_ip               = try(server.hostname_ip, null)
    hostname_ip_variable      = try(server.hostname_ip_variable, null)
    enable_tls                = try(server.enable_tls, null)
    enable_tls_variable       = try(server.enable_tls_variable, null)
    logging_level             = try(server.logging_level, null)
    logging_level_variable    = try(server.logging_level_variable, null)
    source_interface          = try(server.source_interface, null)
    source_interface_variable = try(server.source_interface_variable, null)
    custom_profile            = try(server.tls_profile, null) == null ? null : true
    profile                   = try(server.tls_profile, null)
    profile_variable          = try(server.tls_profile_variable, null)
    optional                  = try(server.optional, null)
    vpn_id                    = try(server.vpn_id, null)
    vpn_id_variable           = try(server.vpn_id_variable, null)
  }]
  tls_profiles = try(length(each.value.tls_profiles) == 0, true) ? null : [for prof in each.value.tls_profiles : {
    name                         = try(prof.name, null)
    name_variable                = try(prof.name_variable, null)
    authentication_type          = try(prof.authentication_type, null) == "server" ? "Server" : try(prof.authentication_type, null) == "mutual" ? "Mutual" : null
    authentication_type_variable = try(prof.authentication_type_variable, null)
    version                      = try(prof.version, null)
    version_variable             = try(prof.version_variable, null)
    ciphersuite_list             = try(prof.ciphersuites, null)
    ciphersuite_list_variable    = try(prof.version_ciphersuites_variablevariable, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cedge_multicast_feature_template" "cedge_multicast_feature_template" {
  for_each                  = { for m in try(local.edge_feature_templates.multicast_templates, {}) : m.name => m }
  name                      = each.value.name
  description               = each.value.description
  device_types              = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.multicast_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  spt_only                  = try(each.value.spt_only, null)
  spt_only_variable         = try(each.value.spt_only_variable, null)
  local_replicator          = try(each.value.local_replicator, null)
  local_replicator_variable = try(each.value.local_replicator_variable, null)
  threshold                 = try(each.value.threshold, null)
  threshold_variable        = try(each.value.threshold_variable, null)
}

resource "sdwan_cisco_ntp_feature_template" "cisco_ntp_feature_template" {
  for_each                         = { for t in try(local.edge_feature_templates.ntp_templates, {}) : t.name => t }
  name                             = each.value.name
  description                      = each.value.description
  device_types                     = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.ntp_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  master                           = try(each.value.master, null)
  master_variable                  = try(each.value.master_variable, null)
  master_stratum                   = try(each.value.master_stratum, null)
  master_stratum_variable          = try(each.value.master_stratum_variable, null)
  master_source_interface          = try(each.value.master_source_interface, null)
  master_source_interface_variable = try(each.value.master_source_interface_variable, null)
  authentication_keys = try(length(each.value.authentication_keys) == 0, true) ? null : [for key in each.value.authentication_keys : {
    id             = try(key.id, null)
    id_variable    = try(key.id_variable, null)
    optional       = try(key.optional, null)
    value          = try(key.value, null)
    value_variable = try(key.value_variable, null)
  }]
  servers = try(length(each.value.servers) == 0, true) ? null : [for server in each.value.servers : {
    authentication_key_id          = try(server.authentication_key_id, null)
    authentication_key_id_variable = try(server.authentication_key_id_variable, null)
    hostname_ip                    = try(server.hostname_ip, null)
    hostname_ip_variable           = try(server.hostname_ip_variable, null)
    optional                       = try(server.optional, null)
    prefer                         = try(server.prefer, null)
    prefer_variable                = try(server.prefer_variable, null)
    source_interface               = try(server.source_interface, null)
    source_interface_variable      = try(server.source_interface_variable, null)
    version                        = try(server.version, null)
    version_variable               = try(server.version_variable, null)
    vpn_id                         = try(server.vpn_id, null)
    vpn_id_variable                = try(server.vpn_id_variable, null)
  }]
  trusted_keys          = try(each.value.trusted_keys, null)
  trusted_keys_variable = try(each.value.trusted_keys_variable, null)
  depends_on            = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_omp_feature_template" "cisco_omp_feature_template" {
  for_each                           = { for t in try(local.edge_feature_templates.omp_templates, {}) : t.name => t }
  name                               = each.value.name
  description                        = each.value.description
  device_types                       = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.omp_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  advertisement_interval             = try(each.value.advertisement_interval, null)
  advertisement_interval_variable    = try(each.value.advertisement_interval_variable, null)
  ecmp_limit                         = try(each.value.ecmp_limit, null)
  ecmp_limit_variable                = try(each.value.ecmp_limit_variable, null)
  eor_timer                          = try(each.value.eor_timer, null)
  eor_timer_variable                 = try(each.value.eor_timer_variable, null)
  graceful_restart                   = try(each.value.graceful_restart, null)
  graceful_restart_variable          = try(each.value.graceful_restart_variable, null)
  graceful_restart_timer             = try(each.value.graceful_restart_timer, null)
  graceful_restart_timer_variable    = try(each.value.graceful_restart_timer_variable, null)
  holdtime                           = try(each.value.holdtime, null)
  holdtime_variable                  = try(each.value.holdtime_variable, null)
  ignore_region_path_length          = try(each.value.ignore_region_path_length, null)
  ignore_region_path_length_variable = try(each.value.ignore_region_path_length_variable, null)
  omp_admin_distance_ipv4            = try(each.value.omp_admin_distance_ipv4, null)
  omp_admin_distance_ipv4_variable   = try(each.value.omp_admin_distance_ipv4_variable, null)
  omp_admin_distance_ipv6            = try(each.value.omp_admin_distance_ipv6, null)
  omp_admin_distance_ipv6_variable   = try(each.value.omp_admin_distance_ipv6_variable, null)
  overlay_as                         = try(each.value.overlay_as, null)
  overlay_as_variable                = try(each.value.overlay_as_variable, null)
  send_path_limit                    = try(each.value.send_path_limit, null)
  send_path_limit_variable           = try(each.value.send_path_limit_variable, null)
  shutdown                           = try(each.value.shutdown, null)
  shutdown_variable                  = try(each.value.shutdown_variable, null)
  transport_gateway                  = try(each.value.transport_gateway, null)
  transport_gateway_variable         = try(each.value.transport_gateway_variable, null)
  advertise_ipv4_routes = try(length(each.value.ipv4_advertise_protocols) == 0, true) ? null : [for a in each.value.ipv4_advertise_protocols : {
    protocol                = a
    advertise_external_ospf = a == "ospf" ? "external" : null
  }]
  advertise_ipv6_routes = try(length(each.value.ipv6_advertise_protocols) == 0, true) ? null : [for a in each.value.ipv6_advertise_protocols : {
    protocol = a
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_ospf_feature_template" "cisco_ospf_feature_template" {
  for_each                                           = { for t in try(local.edge_feature_templates.ospf_templates, {}) : t.name => t }
  name                                               = each.value.name
  description                                        = each.value.description
  device_types                                       = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.ospf_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  auto_cost_reference_bandwidth                      = try(each.value.auto_cost_reference_bandwidth, null)
  auto_cost_reference_bandwidth_variable             = try(each.value.auto_cost_reference_bandwidth_variable, null)
  compatible_rfc1583                                 = try(each.value.compatible_rfc1583, null)
  compatible_rfc1583_variable                        = try(each.value.compatible_rfc1583_variable, null)
  default_information_originate                      = try(each.value.default_information_originate, null)
  default_information_originate_always               = try(each.value.default_information_originate_always, null)
  default_information_originate_always_variable      = try(each.value.default_information_originate_always_variable, null)
  default_information_originate_metric               = try(each.value.default_information_originate_metric, null)
  default_information_originate_metric_variable      = try(each.value.default_information_originate_metric_variable, null)
  default_information_originate_metric_type          = try(each.value.default_information_originate_metric_type, null)
  default_information_originate_metric_type_variable = try(each.value.default_information_originate_metric_type_variable, null)
  distance_inter_area                                = try(each.value.distance_inter_area, null)
  distance_inter_area_variable                       = try(each.value.distance_inter_area_variable, null)
  distance_intra_area                                = try(each.value.distance_intra_area, null)
  distance_intra_area_variable                       = try(each.value.distance_intra_area_variable, null)
  distance_external                                  = try(each.value.distance_external, null)
  distance_external_variable                         = try(each.value.distance_external_variable, null)
  router_id                                          = try(each.value.router_id, null)
  router_id_variable                                 = try(each.value.router_id_variable, null)
  timers_spf_delay                                   = try(each.value.timers_spf_delay, null)
  timers_spf_delay_variable                          = try(each.value.timers_spf_delay_variable, null)
  timers_spf_initial_hold                            = try(each.value.timers_spf_initial_hold, null)
  timers_spf_initial_hold_variable                   = try(each.value.timers_spf_initial_hold_variable, null)
  timers_spf_max_hold                                = try(each.value.timers_spf_max_hold, null)
  timers_spf_max_hold_variable                       = try(each.value.timers_spf_max_hold_variable, null)
  areas = try(length(each.value.areas) == 0, true) ? null : [for a in each.value.areas : {
    area_number          = try(a.area_number, null)
    area_number_variable = try(a.area_number_variable, null)
    stub                 = try(a.area_type, null) == "stub" ? true : null
    stub_no_summary      = try(a.area_type, null) == "stub" && try(a.no_summary, null) == true ? true : try(a.area_type, null) == "stub" && try(a.no_summary, null) == null ? false : null
    nssa                 = try(a.area_type, null) == "nssa" ? true : null
    nssa_no_summary      = try(a.area_type, null) == "nssa" && try(a.no_summary, null) == true ? true : try(a.area_type, null) == "nssa" && try(a.no_summary, null) == null ? false : null
    interfaces = try(length(a.interfaces) == 0, true) ? null : [for i in a.interfaces : {
      name                                          = try(i.name, null)
      name_variable                                 = try(i.name_variable, null)
      authentication_type                           = try(i.authentication_type, null)
      authentication_type_variable                  = try(i.authentication_type_variable, null)
      authentication_message_digest_key             = try(i.authentication_message_digest_key, null)
      authentication_message_digest_key_variable    = try(i.authentication_message_digest_key_variable, null)
      authentication_message_digest_key_id          = try(i.authentication_message_digest_key_id, null)
      authentication_message_digest_key_id_variable = try(i.authentication_message_digest_key_id_variable, null)
      cost                                          = try(i.cost, null)
      cost_variable                                 = try(i.cost_variable, null)
      dead_interval                                 = try(i.dead_interval, null)
      dead_interval_variable                        = try(i.dead_intervale_variable, null)
      hello_interval                                = try(i.hello_interval, null)
      hello_interval_variable                       = try(i.hello_interval_variable, null)
      network                                       = try(i.network_type, null)
      network_variable                              = try(i.network_type_variable, null)
      passive_interface                             = try(i.passive_interface, null)
      passive_interface_variable                    = try(i.passive_interface_variable, null)
      priority                                      = try(i.priority, null)
      priority_variable                             = try(i.priority_variable, null)
      retransmit_interval                           = try(i.retransmit_interval, null)
      retransmit_interval_variable                  = try(i.retransmit_interval_variable, null)
    }]
    ranges = try(length(a.ranges) == 0, true) ? null : [for r in a.ranges : {
      address               = try(r.address, null)
      address_variable      = try(r.address_variable, null)
      cost                  = try(r.cost, null)
      cost_variable         = try(r.cost_variable, null)
      no_advertise          = try(r.no_advertise, null)
      no_advertise_variable = try(r.no_advertise_variable, null)
    }]
    optional = try(a.optional, null)
  }]
  max_metric_router_lsa = try(length(each.value.max_metric_router_lsas) == 0, true) ? null : [for r in each.value.max_metric_router_lsas : {
    ad_type       = r.type
    time          = try(r.time, null)
    time_variable = try(r.time_variable, null)
  }]
  redistribute = try(length(each.value.redistributes) == 0, true) ? null : [for r in each.value.redistributes : {
    protocol              = try(r.protocol, null)
    protocol_variable     = try(r.protocol_variable, null)
    route_policy          = try(r.route_policy, null)
    route_policy_variable = try(r.route_policy_variable, null)
    nat_dia               = try(r.nat_dia, null)
    nat_dia_variable      = try(r.nat_dia_variable, null)
    optional              = try(r.optional, null)
  }]
  route_policies = try(each.value.route_policy, each.value.route_policy_variable, null) == null ? null : [{
    direction            = "in"
    policy_name          = try(each.value.route_policy, null)
    policy_name_variable = try(each.value.route_policy_variable, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cedge_pim_feature_template" "cedge_pim_feature_template" {
  for_each               = { for t in try(local.edge_feature_templates.pim_templates, {}) : t.name => t }
  name                   = each.value.name
  description            = each.value.description
  device_types           = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.pim_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  default                = try(each.value.ssm_default, null)
  default_variable       = try(each.value.ssm_default_variable, null)
  range                  = try(each.value.ssm_access_list_range, null)
  range_variable         = try(each.value.ssm_access_list_range_variable, null)
  auto_rp                = try(each.value.auto_rp, null)
  auto_rp_variable       = try(each.value.auto_rp_variable, null)
  spt_threshold          = try(each.value.spt_threshold, null)
  spt_threshold_variable = try(each.value.spt_threshold_variable, null)
  rp_announce_fields = try(length(each.value.rp_announces) == 0, true) ? null : [for key in each.value.rp_announces : {
    interface_name          = try(key.interface_name, null)
    interface_name_variable = try(key.interface_name_variable, null)
    optional                = try(key.optional, null)
    scope                   = try(key.scope, null)
    scope_variable          = try(key.scope_variable, null)
  }]
  interface_name          = try(each.value.rp_discovery_interface, null)
  interface_name_variable = try(each.value.rp_discovery_interface_variable, null)
  scope                   = try(each.value.rp_discovery_scope, null)
  scope_variable          = try(each.value.rp_discovery_scope_variable, null)
  rp_addresses = try(length(each.value.rp_addresses) == 0, true) ? null : [for addr in each.value.rp_addresses : {
    access_list          = try(addr.access_list, null)
    access_list_variable = try(addr.access_list_variable, null)
    ip_address           = try(addr.ip_address, null)
    ip_address_variable  = try(addr.ip_address_variable, null)
    optional             = try(addr.optional, null)
    override             = try(addr.override, null)
    override_variable    = try(addr.override_variable, null)
  }]
  rp_candidates = try(length(each.value.rp_candidates) == 0, true) ? null : [for candidate in each.value.rp_candidates : {
    access_list          = try(candidate.access_list, null)
    access_list_variable = try(candidate.access_list_variable, null)
    interface            = try(candidate.interface_name, null)
    interface_variable   = try(candidate.interface_name_variable, null)
    interval             = try(candidate.interval, null)
    interval_variable    = try(candidate.interval_variable, null)
    optional             = try(candidate.optional, null)
    priority             = try(candidate.priority, null)
    priority_variable    = try(candidate.priority_variable, null)
  }]
  bsr_candidate                     = try(each.value.bsr_candidate_interface, null)
  bsr_candidate_variable            = try(each.value.bsr_candidate_interface_variable, null)
  hash_mask_length                  = try(each.value.bsr_candidate_hash_mask_length, null)
  hash_mask_length_variable         = try(each.value.bsr_candidate_hash_mask_length_variable, null)
  priority                          = try(each.value.bsr_candidate_priority, null)
  priority_variable                 = try(each.value.bsr_candidate_priority_variable, null)
  rp_candidate_access_list          = try(each.value.bsr_candidate_rp_access_list, null)
  rp_candidate_access_list_variable = try(each.value.bsr_candidate_rp_access_list_variable, null)
  interfaces = try(length(each.value.interfaces) == 0, true) ? null : [for i in each.value.interfaces : {
    interface_name               = try(i.interface_name, null)
    interface_name_variable      = try(i.interface_name_variable, null)
    join_prune_interval          = try(i.join_prune_interval, null)
    join_prune_interval_variable = try(i.join_prune_interval_variable, null)
    optional                     = try(i.optional, null)
    query_interval               = try(i.query_interval, null)
    query_interval_variable      = try(i.query_interval_variable, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_secure_internet_gateway_feature_template" "cisco_secure_internet_gateway_feature_template" {
  for_each                   = { for t in try(local.edge_feature_templates.secure_internet_gateway_templates, {}) : t.name => t }
  name                       = each.value.name
  description                = each.value.description
  device_types               = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  tracker_source_ip          = try(each.value.tracker_source_ip, null)
  tracker_source_ip_variable = try(each.value.tracker_source_ip_variable, null)
  vpn_id                     = 0
  interfaces = try(length(each.value.interfaces) == 0, true) ? null : [for interface in try(each.value.interfaces, []) : {
    application                            = "sig"
    auto_tunnel_mode                       = each.value.sig_provider == "other" ? false : true
    description                            = try(interface.description, null)
    description_variable                   = try(interface.description_variable, null)
    dead_peer_detection_interval           = try(interface.dpd_interval, null)
    dead_peer_detection_interval_variable  = try(interface.dpd_interval_variable, null)
    dead_peer_detection_retries            = try(interface.dpd_retries, null)
    dead_peer_detection_retries_variable   = try(interface.dpd_retries_variable, null)
    ike_ciphersuite                        = interface.tunnel_type == "ipsec" ? try(interface.ike_ciphersuite, can(interface.ike_ciphersuite_variable) ? null : local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ike_ciphersuite) : null
    ike_ciphersuite_variable               = interface.tunnel_type == "ipsec" ? try(interface.ike_ciphersuite_variable, null) : null
    ike_group                              = interface.tunnel_type == "ipsec" ? try(interface.ike_group, can(interface.ike_group_variable) ? null : local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ike_group) : null
    ike_group_variable                     = interface.tunnel_type == "ipsec" ? try(interface.ike_group_variable, null) : null
    ike_pre_shared_key                     = interface.tunnel_type == "ipsec" ? try(interface.ike_pre_shared_key, null) : null
    ike_pre_shared_key_variable            = interface.tunnel_type == "ipsec" ? try(interface.ike_pre_shared_key_variable, null) : null
    ike_pre_shared_key_dynamic             = each.value.sig_provider == "other" ? null : interface.tunnel_type == "ipsec" ? true : null
    ike_pre_shared_key_local_id            = interface.tunnel_type == "ipsec" ? try(interface.ike_pre_shared_key_local_id, null) : null
    ike_pre_shared_key_local_id_variable   = interface.tunnel_type == "ipsec" ? try(interface.ike_pre_shared_key_local_id_variable, null) : null
    ike_pre_shared_key_remote_id           = interface.tunnel_type == "ipsec" ? try(interface.ike_pre_shared_key_remote_id, null) : null
    ike_pre_shared_key_remote_id_variable  = interface.tunnel_type == "ipsec" ? try(interface.ike_pre_shared_key_remote_id_variable, null) : null
    ike_rekey_interval                     = interface.tunnel_type == "ipsec" ? try(interface.ike_rekey_interval, can(interface.ike_rekey_interval_variable) ? null : local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ike_rekey_interval) : null
    ike_rekey_interval_variable            = interface.tunnel_type == "ipsec" ? try(interface.ike_rekey_interval_variable, null) : null
    ike_version                            = interface.tunnel_type == "ipsec" ? 2 : null
    ip_unnumbered                          = "true"
    ipsec_ciphersuite                      = interface.tunnel_type == "ipsec" ? try(interface.ipsec_ciphersuite, can(interface.ipsec_ciphersuite_variable) ? null : local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_ciphersuite) : null
    ipsec_ciphersuite_variable             = interface.tunnel_type == "ipsec" ? try(interface.ipsec_ciphersuite_variable, null) : null
    ipsec_perfect_forward_secrecy          = interface.tunnel_type == "ipsec" ? try(interface.ipsec_perfect_forward_secrecy, can(interface.ipsec_perfect_forward_secrecy_variable) ? null : local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_perfect_forward_secrecy) : null
    ipsec_perfect_forward_secrecy_variable = interface.tunnel_type == "ipsec" ? try(interface.ipsec_perfect_forward_secrecy_variable, null) : null
    ipsec_rekey_interval                   = interface.tunnel_type == "ipsec" ? try(interface.ipsec_rekey_interval, can(interface.ipsec_rekey_interval_variable) ? null : local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_rekey_interval) : null
    ipsec_rekey_interval_variable          = interface.tunnel_type == "ipsec" ? try(interface.ipsec_rekey_interval_variable, null) : null
    ipsec_replay_window                    = interface.tunnel_type == "ipsec" ? try(interface.ipsec_replay_window, can(interface.ipsec_replay_window_variable) ? null : local.defaults.sdwan.edge_feature_templates.secure_internet_gateway_templates.interfaces.ipsec_replay_window) : null
    ipsec_replay_window_variable           = interface.tunnel_type == "ipsec" ? try(interface.ipsec_replay_window_variable, null) : null
    mtu                                    = try(interface.mtu, null)
    mtu_variable                           = try(interface.mtu_variable, null)
    name                                   = try(interface.name, null)
    name_variable                          = try(interface.name_variable, null)
    shutdown                               = try(interface.shutdown, null)
    sig_provider                           = each.value.sig_provider == "umbrella" ? "secure-internet-gateway-umbrella" : each.value.sig_provider == "zscaler" ? "secure-internet-gateway-zscaler" : each.value.sig_provider == "other" ? "secure-internet-gateway-other" : null
    tcp_mss                                = try(interface.tcp_mss, null)
    tcp_mss_variable                       = try(interface.tcp_mss_variable, null)
    track_enable                           = try(interface.track, null)
    tracker                                = try(interface.tracker, null)
    tracker_variable                       = try(interface.tracker_variable, null)
    tunnel_dc_preference                   = try(interface.tunnel_dc_preference, null)
    tunnel_destination                     = each.value.sig_provider == "other" ? try(interface.tunnel_destination, null) : "dynamic"
    tunnel_destination_variable            = each.value.sig_provider == "other" ? try(interface.tunnel_destination_variable, null) : null
    tunnel_route_via                       = try(interface.tunnel_source_interface, null)
    tunnel_route_via_variable              = try(interface.tunnel_source_interface_variable, null)
    tunnel_public_ip                       = interface.tunnel_type == "gre" ? try(interface.tunnel_public_source_ip, null) : null
    tunnel_public_ip_variable              = interface.tunnel_type == "gre" ? try(interface.tunnel_public_source_ip_variable, null) : null
    tunnel_source_interface                = try(interface.tunnel_source_interface, null)
    tunnel_source_interface_variable       = try(interface.tunnel_source_interface_variable, null)
  }]
  trackers = try(length(each.value.trackers) == 0, true) ? null : [for tracker in try(each.value.trackers, []) : {
    tracker_type              = "SIG"
    endpoint_api_url          = try(tracker.endpoint_api_url, null)
    endpoint_api_url_variable = try(tracker.endpoint_api_url_variable, null)
    multiplier                = try(tracker.multiplier, null)
    multiplier_variable       = try(tracker.multiplier_variable, null)
    interval                  = try(tracker.interval, null)
    interval_variable         = try(tracker.interval_variable, null)
    name                      = try(tracker.name, null)
    name_variable             = try(tracker.name_variable, null)
    threshold                 = try(tracker.threshold, null)
    threshold_variable        = try(tracker.threshold_variable, null)
  }]
  services = [{
    service_type                                    = "sig"
    umbrella_primary_data_center                    = try(each.value.umbrella_primary_data_center, null)
    umbrella_primary_data_center_variable           = try(each.value.umbrella_primary_data_center_variable, null)
    umbrella_secondary_data_center                  = try(each.value.umbrella_secondary_data_center, null)
    umbrella_secondary_data_center_variable         = try(each.value.umbrella_secondary_data_center_variable, null)
    zscaler_aup_block_internet_until_accepted       = try(each.value.zscaler_aup_block_internet_until_accepted, null)
    zscaler_aup_enabled                             = try(each.value.zscaler_aup_enabled, null)
    zscaler_aup_force_ssl_inspection                = try(each.value.zscaler_aup_force_ssl_inspection, null)
    zscaler_aup_timeout                             = try(each.value.zscaler_aup_timeout, null)
    zscaler_authentication_required                 = try(each.value.zscaler_authentication_required, null)
    zscaler_caution_enabled                         = try(each.value.zscaler_caution_enabled, null)
    zscaler_firewall_enabled                        = try(each.value.zscaler_firewall_enabled, null)
    zscaler_ips_control_enabled                     = try(each.value.zscaler_ips_control_enabled, null)
    zscaler_location_name_variable                  = try(each.value.zscaler_location_name_variable, null)
    zscaler_primary_data_center                     = try(each.value.zscaler_primary_data_center, null)
    zscaler_primary_data_center_variable            = try(each.value.zscaler_primary_data_center_variable, null)
    zscaler_secondary_data_center                   = try(each.value.zscaler_secondary_data_center, null)
    zscaler_secondary_data_center_variable          = try(each.value.zscaler_secondary_data_center_variable, null)
    zscaler_surrogate_display_time_unit             = try(upper(each.value.zscaler_surrogate_display_time_unit), null)
    zscaler_surrogate_idle_time                     = try(each.value.zscaler_surrogate_idle_time, null)
    zscaler_surrogate_ip                            = try(each.value.zscaler_surrogate_ip, null)
    zscaler_surrogate_ip_enforce_for_known_browsers = try(each.value.zscaler_surrogate_ip_enforce_for_known_browsers, null)
    zscaler_surrogate_refresh_time                  = try(each.value.zscaler_surrogate_refresh_time, null)
    zscaler_surrogate_refresh_time_unit             = try(upper(each.value.zscaler_surrogate_refresh_time_unit), null)
    zscaler_xff_forward                             = try(each.value.zscaler_xff_forward, null)
    interface_pairs = try(length(each.value.high_availability_interface_pairs) == 0, true) ? null : [for pair in try(each.value.high_availability_interface_pairs, []) : {
      active_interface        = try(pair.active_interface, null)
      active_interface_weight = try(pair.active_interface_weight, null)
      backup_interface        = try(pair.backup_interface == "none" ? "None" : pair.backup_interface, null)
      backup_interface_weight = try(pair.backup_interface_weight, null)
    }]
  }]
  depends_on = [
    sdwan_localized_policy.localized_policy,
    sdwan_cisco_sig_credentials_feature_template.cisco_sig_credentials_feature_template
  ]
}

resource "sdwan_cisco_security_feature_template" "cisco_security_feature_template" {
  for_each                    = { for t in try(local.edge_feature_templates.security_templates, {}) : t.name => t }
  name                        = each.value.name
  description                 = each.value.description
  device_types                = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.security_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  extended_ar_window          = try(each.value.extended_anti_replay_window, null)
  extended_ar_window_variable = try(each.value.extended_anti_replay_window_variable, null)
  integrity_type              = try(each.value.authentication_types, null)
  integrity_type_variable     = try(each.value.authentication_types_variable, null)
  pairwise_keying             = try(each.value.pairwise_keying, null)
  pairwise_keying_variable    = try(each.value.pairwise_keying_variable, null)
  rekey_interval              = try(each.value.rekey_interval, null)
  rekey_interval_variable     = try(each.value.rekey_interval_variable, null)
  replay_window               = try(each.value.replay_window, null)
  replay_window_variable      = try(each.value.replay_window_variable, null)
  authentication_type = try(length(each.value.authentication_types) == 0, true) ? null : [for a in each.value.authentication_types :
    a == "esp" ? "sha1-hmac" :
    a == "ip-udp-esp" ? "ah-sha1-hmac" :
    a == "ip-udp-esp-no-id" ? "ah-no-id" :
  a]
  authentication_type_variable = try(each.value.authentication_types_variable, null)
  keychains = try(length(each.value.key_chains) == 0, true) ? null : [for key in each.value.key_chains : {
    key_id = key.key_id
    name   = key.name
  }]
  keys = try(length(each.value.keys) == 0, true) ? null : [for key in each.value.keys : {
    accept_ao_mismatch                = try(key.accept_ao_mismatch, null)
    accept_ao_mismatch_variable       = try(key.accept_ao_mismatch_variable, null)
    accept_lifetime_local             = try(key.accept_lifetime, null)
    accept_lifetime_local_variable    = try(key.accept_lifetime_variable, null)
    accept_lifetime_duration          = try(key.accept_lifetime_duration_seconds, null)
    accept_lifetime_duration_variable = try(key.accept_lifetime_duration_variable, null)
    accept_lifetime_end_time          = try(key.accept_lifetime_end_time_epoch, null)
    accept_lifetime_end_time_format   = try(key.accept_lifetime_end_time_format, null)
    accept_lifetime_infinite          = try(key.accept_lifetime_end_time_format, null) == "infinite" ? true : null
    accept_lifetime_start_time        = try(key.accept_lifetime_start_time_epoch, null)
    chain_name                        = key.key_chain_name
    crypto_algorithm                  = try(key.crypto_algorithm, null)
    id                                = key.id
    include_tcp_options               = try(key.include_tcp_options, null)
    key_string                        = try(key.key_string, null)
    key_string_variable               = try(key.key_string_variable, null)
    receive_id                        = try(key.receive_id, null)
    receive_id_variable               = try(key.receive_id_variable, null)
    send_id                           = try(key.send_id, null)
    send_id_variable                  = try(key.send_id_variable, null)
    send_lifetime_local               = try(key.send_lifetime, null)
    send_lifetime_local_variable      = try(key.send_lifetime_variable, null)
    send_lifetime_duration            = try(key.send_lifetime_duration_seconds, null)
    send_lifetime_duration_variable   = try(key.send_lifetime_duration_variable, null)
    send_lifetime_end_time            = try(key.send_lifetime_end_time_epoch, null)
    send_lifetime_end_time_format     = try(key.send_lifetime_end_time_format, null)
    send_lifetime_infinite            = try(key.send_lifetime_end_time_format, null) == "infinite" ? true : null
    send_lifetime_start_time          = try(key.send_lifetime_start_time_epoch, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_sig_credentials_feature_template" "cisco_sig_credentials_feature_template" {
  for_each                          = { for t in try(local.edge_feature_templates.sig_credentials_templates, {}) : t.name => t }
  name                              = each.value.name
  description                       = each.value.name == "Cisco-Umbrella-Global-Credentials" ? "Global credentials for umbrella" : "Global credentials for zscaler"
  device_types                      = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.sig_credentials_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  umbrella_api_key                  = try(each.value.umbrella_api_key, null)
  umbrella_api_key_variable         = try(each.value.umbrella_api_key_variable, null)
  umbrella_api_secret               = try(each.value.umbrella_api_secret, null)
  umbrella_api_secret_variable      = try(each.value.umbrella_api_secret_variable, null)
  umbrella_organization_id          = try(each.value.umbrella_organization_id, null)
  umbrella_organization_id_variable = try(each.value.umbrella_organization_id_variable, null)
  zscaler_organization              = try(each.value.zscaler_organization, null)
  zscaler_organization_variable     = try(each.value.zscaler_organization_variable, null)
  zscaler_partner_api_key           = try(each.value.zscaler_partner_api_key, null)
  zscaler_partner_api_key_variable  = try(each.value.zscaler_partner_api_key_variable, null)
  zscaler_partner_base_uri          = try(each.value.zscaler_partner_base_uri, null)
  zscaler_partner_base_uri_variable = try(each.value.zscaler_partner_base_uri_variable, null)
  zscaler_password                  = try(each.value.zscaler_password, null)
  zscaler_password_variable         = try(each.value.zscaler_password_variable, null)
  zscaler_username                  = try(each.value.zscaler_username, null)
  zscaler_username_variable         = try(each.value.zscaler_username_variable, null)
  depends_on                        = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_snmp_feature_template" "cisco_snmp_feature_template" {
  for_each          = { for t in try(local.edge_feature_templates.snmp_templates, {}) : t.name => t }
  name              = each.value.name
  description       = each.value.description
  device_types      = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.snmp_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  contact           = try(each.value.contact, null)
  contact_variable  = try(each.value.contact_variable, null)
  location          = try(each.value.location, null)
  location_variable = try(each.value.location_variable, null)
  shutdown          = try(each.value.shutdown, null)
  shutdown_variable = try(each.value.shutdown_variable, null)
  communities = try(length(each.value.communities) == 0, true) ? null : [for c in each.value.communities : {
    name                   = c.name
    authorization          = try(c.authorization_read_only, can(c.authorization_variable) ? null : local.defaults.sdwan.edge_feature_templates.snmp_templates.communities.authorization_read_only) == true ? "read-only" : null
    authorization_variable = try(c.authorization_read_only_variable, null)
    view                   = try(c.view, null)
    view_variable          = try(c.view_variable, null)
  }]
  groups = try(length(each.value.groups) == 0, true) ? null : [for g in each.value.groups : {
    name           = g.name
    security_level = g.security_level
    view           = try(g.view, null)
    view_variable  = try(g.view_variable, null)
  }]
  trap_targets = try(length(each.value.trap_target_servers) == 0, true) ? null : [for t in each.value.trap_target_servers : {
    community_name            = try(t.community_name, null)
    community_name_variable   = try(t.community_name_variable, null)
    ip                        = try(t.ip, null)
    ip_variable               = try(t.ip_variable, null)
    source_interface          = try(t.source_interface, null)
    source_interface_variable = try(t.source_interface_variable, null)
    udp_port                  = try(t.udp_port, null)
    udp_port_variable         = try(t.udp_port_variable, null)
    user                      = try(t.user, null)
    user_variable             = try(t.user_variable, null)
    vpn_id                    = try(t.vpn_id, null)
    vpn_id_variable           = try(t.vpn_id_variable, null)
  }]
  users = try(length(each.value.users) == 0, true) ? null : [for u in each.value.users : {
    name                             = u.name
    authentication_password          = try(u.authentication_password, null)
    authentication_password_variable = try(u.authentication_password_variable, null)
    authentication_protocol          = try(u.authentication_protocol, null)
    authentication_protocol_variable = try(u.authentication_protocol_variable, null)
    group                            = try(u.group, null)
    group_variable                   = try(u.group_variable, null)
    privacy_password                 = try(u.privacy_password, null)
    privacy_password_variable        = try(u.privacy_password_variable, null)
    privacy_protocol                 = try(u.privacy_protocol, null)
    privacy_protocol_variable        = try(u.privacy_protocol_variable, null)
  }]
  views = try(length(each.value.views) == 0, true) ? null : [for v in each.value.views : {
    name = v.name
    object_identifiers = try(length(v.oids) == 0, true) ? null : [for o in v.oids : {
      id               = try(o.id, null)
      id_variable      = try(o.id_variable, null)
      exclude          = try(o.exclude, null)
      exclude_variable = try(o.exclude_variable, null)
    }]
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_system_feature_template" "cisco_system_feature_template" {
  for_each                           = { for t in try(local.edge_feature_templates.system_templates, {}) : t.name => t }
  name                               = each.value.name
  description                        = each.value.description
  device_types                       = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.system_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  admin_tech_on_failure              = try(each.value.admin_tech_on_failure, null)
  admin_tech_on_failure_variable     = try(each.value.admin_tech_on_failure_variable, null)
  affinity_group_number              = try(each.value.affinity_group_number, null)
  affinity_group_number_variable     = try(each.value.affinity_group_number_variable, null)
  affinity_group_preference          = try(each.value.affinity_group_preferences, null)
  affinity_group_preference_variable = try(each.value.affinity_group_preferences_variable, null)
  console_baud_rate                  = try(each.value.console_baud_rate, null)
  console_baud_rate_variable         = try(each.value.console_baud_rate_variable, null)
  control_session_pps                = try(each.value.control_session_pps, null)
  control_session_pps_variable       = try(each.value.control_session_pps_variable, null)
  controller_group_list              = try(each.value.controller_groups, null)
  controller_group_list_variable     = try(each.value.controller_groups_variable, null)
  device_groups                      = try(each.value.device_groups, null)
  device_groups_variable             = try(each.value.device_groups_variable, null)
  enable_mrf_migration               = try(each.value.enable_mrf_migration, null)
  geo_fencing                        = try(each.value.geo_fencing, null)
  geo_fencing_sms                    = try(each.value.geo_fencing_sms_phone_numbers, null) == null ? null : true
  geo_fencing_sms_phone_numbers = try(length(each.value.geo_fencing_sms_phone_numbers) == 0, true) ? null : [for obj in each.value.geo_fencing_sms_phone_numbers : {
    number          = try(obj.number, null)
    number_variable = try(obj.number_variable, null)
  }]
  geo_fencing_range                      = try(each.value.geo_fencing_range, null)
  geo_fencing_range_variable             = try(each.value.geo_fencing_range_variable, null)
  hostname_variable                      = try(each.value.hostname_variable, null)
  idle_timeout                           = try(each.value.idle_timeout, null)
  idle_timeout_variable                  = try(each.value.idle_timeout_variable, null)
  latitude                               = try(each.value.latitude, null)
  latitude_variable                      = try(each.value.latitude_variable, null)
  location                               = try(each.value.location, null)
  location_variable                      = try(each.value.location_variable, null)
  longitude                              = try(each.value.longitude, null)
  longitude_variable                     = try(each.value.longitude_variable, null)
  max_omp_sessions                       = try(each.value.max_omp_sessions, null)
  max_omp_sessions_variable              = try(each.value.max_omp_sessions_variable, null)
  migration_bgp_community                = try(each.value.migration_bgp_community, null)
  multi_tenant                           = try(each.value.multi_tenant, null)
  multi_tenant_variable                  = try(each.value.multi_tenant_variable, null)
  on_demand_tunnel                       = try(each.value.on_demand_tunnel, null)
  on_demand_tunnel_variable              = try(each.value.on_demand_tunnel_variable, null)
  on_demand_tunnel_idle_timeout          = try(each.value.on_demand_tunnel_idle_timeout, null)
  on_demand_tunnel_idle_timeout_variable = try(each.value.on_demand_tunnel_idle_timeout_variable, null)
  overlay_id                             = try(each.value.overlay_id, null)
  overlay_id_variable                    = try(each.value.overlay_id_variable, null)
  port_hopping                           = try(each.value.port_hopping, null)
  port_hopping_variable                  = try(each.value.port_hopping_variable, null)
  port_offset                            = try(each.value.port_offset, null)
  port_offset_variable                   = try(each.value.port_offset_variable, null)
  region_id                              = try(each.value.region_id, null)
  region_id_variable                     = try(each.value.region_id_variable, null)
  role                                   = try(each.value.role, null)
  role_variable                          = try(each.value.role_variable, null)
  secondary_region_id                    = try(each.value.secondary_region_id, null)
  secondary_region_id_variable           = try(each.value.secondary_region_id_variable, null)
  site_id                                = try(each.value.site_id, null)
  site_id_variable                       = try(each.value.site_id_variable, null)
  system_description                     = try(each.value.system_description, null)
  system_description_variable            = try(each.value.system_description_variable, null)
  system_ip_variable                     = try(each.value.system_ip_variable, null)
  timezone                               = try(each.value.timezone, null)
  timezone_variable                      = try(each.value.timezone_variable, null)
  track_default_gateway                  = try(each.value.track_default_gateway, null)
  track_default_gateway_variable         = try(each.value.track_default_gateway_variable, null)
  track_interface_tag                    = try(each.value.track_interface_omp_tag, null)
  track_interface_tag_variable           = try(each.value.track_interface_omp_tag_variable, null)
  track_transport                        = try(each.value.track_transport, null)
  track_transport_variable               = try(each.value.track_transport_variable, null)
  transport_gateway                      = try(each.value.transport_gateway, null)
  transport_gateway_variable             = try(each.value.transport_gateway_variable, null)
  enhanced_app_aware_routing             = try(each.value.enhanced_app_aware_routing, null)
  enhanced_app_aware_routing_variable    = try(each.value.enhanced_app_aware_routing_variable, null)
  object_trackers = try(length(each.value.object_trackers) == 0, true) ? null : [for obj in each.value.object_trackers : {
    object_number          = try(obj.id, null)
    object_number_variable = try(obj.id_variable, null)
    boolean                = try(obj.group_criteria, null)
    boolean_variable       = try(obj.group_criteria_variable, null)
    group_tracks_ids = try(length(obj.group_trackers) == 0, true) ? null : [for i in obj.group_trackers : {
      track_id          = try(i, null)
      track_id_variable = try(obj.group_trackers_variable, null)
    }]
    interface          = try(obj.interface, null)
    interface_variable = try(obj.interface_variable, null)
    ip                 = try(obj.ip, null)
    ip_variable        = try(obj.ip_variable, null)
    mask               = try(obj.mask, null)
    mask_variable      = try(obj.mask_variable, null)
    optional           = try(obj.optional, null)
    vpn_id             = try(obj.vpn_id, null)
  }]
  trackers = try(length(each.value.endpoint_trackers) == 0, true) ? null : [for obj in each.value.endpoint_trackers : {
    name                                 = try(obj.name, null)
    name_variable                        = try(obj.name_variable, null)
    boolean                              = try(obj.group_criteria, null)
    boolean_variable                     = try(obj.group_criteria_variable, null)
    elements                             = try(obj.group_trackers, null)
    elements_variable                    = try(obj.group_trackers_variable, null)
    endpoint_api_url                     = try(obj.endpoint_api_url, null)
    endpoint_api_url_variable            = try(obj.endpoint_api_url_variable, null)
    endpoint_dns_name                    = try(obj.endpoint_dns_name, null)
    endpoint_dns_name_variable           = try(obj.endpoint_dns_name_variable, null)
    endpoint_ip                          = try(obj.endpoint_ip, null)
    endpoint_ip_variable                 = try(obj.endpoint_ip_variable, null)
    interval                             = try(obj.interval, can(obj.interval_variable) ? null : local.defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.interval)
    interval_variable                    = try(obj.interval_variable, null)
    multiplier                           = try(obj.multiplier, can(obj.multiplier_variable) ? null : local.defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.multiplier)
    multiplier_variable                  = try(obj.multiplier_variable, null)
    optional                             = try(obj.optional, null)
    threshold                            = try(obj.threshold, can(obj.threshold_variable) ? null : local.defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.threshold)
    threshold_variable                   = try(obj.threshold_variable, null)
    transport_endpoint_ip                = try(obj.transport_endpoint_ip, null)
    transport_endpoint_ip_variable       = try(obj.transport_endpoint_ip_variable, null)
    transport_endpoint_port              = try(obj.transport_endpoint_port, null)
    transport_endpoint_port_variable     = try(obj.transport_endpoint_port_variable, null)
    transport_endpoint_protocol          = try(obj.transport_endpoint_protocol, null)
    transport_endpoint_protocol_variable = try(obj.transport_endpoint_protocol_variable, null)
    type                                 = try(can(obj.group_trackers) ? "tracker-group" : try(obj.type, can(obj.type_variable) ? null : local.defaults.sdwan.edge_feature_templates.system_templates.endpoint_trackers.type))
    type_variable                        = try(obj.type_variable, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_thousandeyes_feature_template" "cisco_thousandeyes_feature_template" {
  for_each     = { for t in try(local.edge_feature_templates.thousandeyes_templates, {}) : t.name => t }
  name         = each.value.name
  description  = each.value.description
  device_types = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.thousandeyes_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  virtual_applications = [{
    application_type                = "te"
    instance_id                     = 1
    te_account_group_token          = try(each.value.account_group_token, null)
    te_account_group_token_variable = try(each.value.account_group_token_variable, null)
    te_agent_ip                     = try(each.value.ip, null)
    te_agent_ip_variable            = try(each.value.ip_variable, null)
    te_default_gateway              = try(each.value.default_gateway, null)
    te_default_gateway_variable     = try(each.value.default_gateway_variable, null)
    te_hostname                     = try(each.value.hostname, null)
    te_hostname_variable            = try(each.value.hostname_variable, null)
    te_name_server                  = try(each.value.name_server, null)
    te_name_server_variable         = try(each.value.name_server_variable, null)
    te_pac_url                      = try(each.value.proxy_pac_url, null)
    te_pac_url_variable             = try(each.value.proxy_pac_url_variable, null)
    te_proxy_host                   = try(each.value.proxy_host, null)
    te_proxy_host_variable          = try(each.value.proxy_host_variable, null)
    te_proxy_port                   = try(each.value.proxy_port, null)
    te_proxy_port_variable          = try(each.value.proxy_port_variable, null)
    te_vpn                          = try(each.value.vpn_id, null)
    te_vpn_variable                 = try(each.value.vpn_id_variable, null)
    te_web_proxy_type               = try(each.value.proxy_type, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_vpn_feature_template" "cisco_vpn_feature_template" {
  for_each                         = { for t in try(local.edge_feature_templates.vpn_templates, {}) : t.name => t }
  name                             = each.value.name
  description                      = each.value.description
  device_types                     = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.vpn_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  enhance_ecmp_keying              = try(each.value.enhance_ecmp_keying, null)
  enhance_ecmp_keying_variable     = try(each.value.enhance_ecmp_keying_variable, null)
  omp_admin_distance_ipv4          = try(each.value.omp_admin_distance_ipv4, null)
  omp_admin_distance_ipv4_variable = try(each.value.omp_admin_distance_ipv4_variable, null)
  omp_admin_distance_ipv6          = try(each.value.omp_admin_distance_ipv6, null)
  omp_admin_distance_ipv6_variable = try(each.value.omp_admin_distance_ipv6_variable, null)
  vpn_id                           = try(each.value.vpn_id, null)
  vpn_name                         = try(each.value.vpn_name, null)
  vpn_name_variable                = try(each.value.vpn_name_variable, null)
  dns_hosts = try(each.value.ipv4_dns_hosts, each.value.ipv6_dns_hosts, null) == null ? null : flatten([
    try(each.value.ipv4_dns_hosts, null) == null ? [] : [for host in each.value.ipv4_dns_hosts : {
      hostname          = try(host.hostname, null)
      hostname_variable = try(host.hostname_variable, null)
      ip                = try(host.ips, null)
      ip_variable       = try(host.ips_variable, null)
      optional          = try(host.optional, null)
    }],
    try(each.value.ipv6_dns_hosts, null) == null ? [] : [for host in each.value.ipv6_dns_hosts : {
      hostname          = try(host.hostname, null)
      hostname_variable = try(host.hostname_variable, null)
      ip                = try(host.ips, null)
      ip_variable       = try(host.ips_variable, null)
      optional          = try(host.optional, null)
    }]
  ])
  dns_ipv4_servers = try(each.value.ipv4_primary_dns_server, each.value.ipv4_primary_dns_server_variable, each.value.ipv4_secondary_dns_server, each.value.ipv4_secondary_dns_server_variable, null) == null ? null : flatten([
    try(each.value.ipv4_primary_dns_server, each.value.ipv4_primary_dns_server_variable, null) == null ? [] : [{
      address          = try(each.value.ipv4_primary_dns_server, null)
      address_variable = try(each.value.ipv4_primary_dns_server_variable, null)
      role             = "primary"
    }],
    try(each.value.ipv4_secondary_dns_server, each.value.ipv4_secondary_dns_server_variable, null) == null ? [] : [{
      address          = try(each.value.ipv4_secondary_dns_server, null)
      address_variable = try(each.value.ipv4_secondary_dns_server_variable, null)
      role             = "secondary"
    }]
  ])
  dns_ipv6_servers = try(each.value.ipv6_primary_dns_server, each.value.ipv6_primary_dns_server_variable, each.value.ipv6_secondary_dns_server, each.value.ipv6_secondary_dns_server_variable, null) == null ? null : flatten([
    try(each.value.ipv6_primary_dns_server, each.value.ipv6_primary_dns_server_variable, null) == null ? [] : [{
      address          = try(each.value.ipv6_primary_dns_server, null)
      address_variable = try(each.value.ipv6_primary_dns_server_variable, null)
      role             = "primary"
    }],
    try(each.value.ipv6_secondary_dns_server, each.value.ipv6_secondary_dns_server_variable, null) == null ? [] : [{
      address          = try(each.value.ipv6_secondary_dns_server, null)
      address_variable = try(each.value.ipv6_secondary_dns_server_variable, null)
      role             = "secondary"
    }]
  ])
  ipv4_static_gre_routes = try(length(each.value.ipv4_static_gre_routes) == 0, true) ? null : [for route in each.value.ipv4_static_gre_routes : {
    interfaces          = try(route.interfaces, null)
    interfaces_variable = try(route.interfaces_variable, null)
    prefix              = try(route.prefix, null)
    prefix_variable     = try(route.prefix_variable, null)
    optional            = try(route.optional, null)
    vpn_id              = 0
  }]
  ipv4_static_ipsec_routes = try(length(each.value.ipv4_static_ipsec_routes) == 0, true) ? null : [for route in each.value.ipv4_static_ipsec_routes : {
    interfaces          = try(route.interfaces, null)
    interfaces_variable = try(route.interfaces_variable, null)
    prefix              = try(route.prefix, null)
    prefix_variable     = try(route.prefix_variable, null)
    optional            = try(route.optional, null)
    vpn_id              = 0
  }]
  ipv4_static_routes = try(length(each.value.ipv4_static_routes) == 0, true) ? null : [for route in each.value.ipv4_static_routes : {
    dhcp              = try(route.next_hop_dhcp, null)
    null0             = try(route.next_hop_null0, null)
    distance          = try(route.next_hop_null0_distance, null)
    distance_variable = try(route.next_hop_null0_distance_variable, null)
    prefix            = try(route.prefix, null)
    prefix_variable   = try(route.prefix_variable, null)
    optional          = try(route.optional, null)
    vpn_id            = try(route.next_hop_dia, null) == true ? 0 : null
    next_hops = try(length(route.next_hops) == 0, true) ? null : [for nh in route.next_hops : {
      address           = try(nh.address, null)
      address_variable  = try(nh.address_variable, null)
      distance          = try(nh.distance, null)
      distance_variable = try(nh.distance_variable, null)
    }]
    track_next_hops = try(length(route.track_next_hops) == 0, true) ? null : [for nh in route.track_next_hops : {
      address           = try(nh.address, null)
      address_variable  = try(nh.address_variable, null)
      distance          = try(nh.distance, null)
      distance_variable = try(nh.distance_variable, null)
      tracker           = try(nh.tracker, null)
      tracker_variable  = try(nh.tracker_variable, null)
    }]
  }]
  ipv4_static_service_routes = try(length(each.value.ipv4_static_service_routes) == 0, true) ? null : [for route in each.value.ipv4_static_service_routes : {
    prefix          = try(route.prefix, null)
    prefix_variable = try(route.prefix_variable, null)
    service         = try(route.service, null)
    vpn_id          = 0
  }]
  ipv6_static_routes = try(length(each.value.ipv6_static_routes) == 0, true) ? null : [for route in each.value.ipv6_static_routes : {
    nat             = try(route.nat, null)
    nat_variable    = try(route.nat_variable, null)
    null0           = try(route.next_hop_null0, null)
    prefix          = try(route.prefix, null)
    prefix_variable = try(route.prefix_variable, null)
    optional        = try(route.optional, null)
    next_hops = try(length(route.next_hops) == 0, true) ? null : [for nh in route.next_hops : {
      address           = try(nh.address, null)
      address_variable  = try(nh.address_variable, null)
      distance          = try(nh.distance, null)
      distance_variable = try(nh.distance_variable, null)
    }]
  }]
  nat64_pools = try(length(each.value.nat64_pools) == 0, true) ? null : [for pool in each.value.nat64_pools : {
    end_address            = try(pool.range_end, null)
    end_address_variable   = try(pool.range_end_variable, null)
    name                   = try(pool.name, null)
    name_variable          = try(pool.name_variable, null)
    overload               = try(pool.overload, null)
    overload_variable      = try(pool.overload_variable, null)
    start_address          = try(pool.range_start, null)
    start_address_variable = try(pool.range_start_variable, null)
  }]
  nat_pools = try(length(each.value.nat_pools) == 0, true) ? null : [for pool in each.value.nat_pools : {
    direction              = try(pool.direction, null)
    direction_variable     = try(pool.direction_variable, null)
    name                   = try(pool.id, null)
    name_variable          = try(pool.id_variable, null)
    overload               = try(pool.overload, null)
    overload_variable      = try(pool.overload_variable, null)
    prefix_length          = try(pool.prefix_length, null)
    prefix_length_variable = try(pool.prefix_length_variable, null)
    range_end              = try(pool.range_end, null)
    range_end_variable     = try(pool.range_end_variable, null)
    range_start            = try(pool.range_start, null)
    range_start_variable   = try(pool.range_start_variable, null)
    tracker_id             = try(pool.tracker_id, null)
    tracker_id_variable    = try(pool.tracker_id_variable, null)
  }]
  omp_advertise_ipv4_routes = try(length(each.value.omp_advertise_ipv4_routes) == 0, true) ? null : [for route in each.value.omp_advertise_ipv4_routes : {
    protocol              = try(route.protocol, null)
    protocol_variable     = try(route.protocol_variable, null)
    protocol_sub_type     = try(route.protocol, "") == "ospf" ? ["external"] : null
    route_policy          = try(route.route_policy, null)
    route_policy_variable = try(route.route_policy_variable, null)
    prefixes = try(length(route.networks) == 0, true) ? null : [for p in route.networks : {
      aggregate_only          = try(p.aggregate_only, null)
      aggregate_only_variable = try(p.aggregate_only_variable, null)
      prefix_entry            = try(p.prefix, null)
      prefix_entry_variable   = try(p.prefix_variable, null)
      optional                = try(p.optional, null)
    }]
  }]
  omp_advertise_ipv6_routes = try(length(each.value.omp_advertise_ipv6_routes) == 0, true) ? null : [for route in each.value.omp_advertise_ipv6_routes : {
    protocol              = try(route.protocol, null)
    protocol_variable     = try(route.protocol_variable, null)
    route_policy          = try(route.route_policy, null)
    route_policy_variable = try(route.route_policy_variable, null)
    prefixes = try(length(route.networks) == 0, true) ? null : [for p in route.networks : {
      aggregate_only          = try(p.aggregate_only, null)
      aggregate_only_variable = try(p.aggregate_only_variable, null)
      prefix_entry            = try(p.prefix, null)
      prefix_entry_variable   = try(p.prefix_variable, null)
      optional                = try(p.optional, null)
    }]
  }]
  port_forward_rules = try(length(each.value.port_forwarding_rules) == 0, true) ? null : [for rule in each.value.port_forwarding_rules : {
    pool_name               = try(rule.nat_pool_id, null)
    pool_name_variable      = try(rule.nat_pool_id_variable, null)
    protocol                = try(rule.protocol, null)
    protocol_variable       = try(rule.protocol_variable, null)
    source_ip               = try(rule.source_ip, null)
    source_ip_variable      = try(rule.source_ip_variable, null)
    source_port             = try(rule.source_port, null)
    source_port_variable    = try(rule.source_port_variable, null)
    translate_ip            = try(rule.translate_ip, null)
    translate_ip_variable   = try(rule.translate_ip_variable, null)
    translate_port          = try(rule.translate_port, null)
    translate_port_variable = try(rule.translate_port_variable, null)
  }]
  route_global_exports = try(length(each.value.route_global_exports) == 0, true) ? null : [for exp in each.value.route_global_exports : {
    protocol          = try(exp.protocol, null)
    protocol_variable = try(exp.protocol_variable, null)
    protocol_sub_type = try(exp.protocol, null) != null ? ["external"] : null
    route_policy      = try(exp.route_policy, null)
    redistributes = try(length(exp.redistributes) == 0, true) ? null : [for r in exp.redistributes : {
      protocol          = try(r.protocol, null)
      protocol_variable = try(r.protocol_variable, null)
      route_policy      = try(r.route_policy, null)
    }]
  }]
  route_global_imports = try(length(each.value.route_global_imports) == 0, true) ? null : [for imp in each.value.route_global_imports : {
    protocol          = try(imp.protocol, null)
    protocol_variable = try(imp.protocol_variable, null)
    protocol_sub_type = try(imp.protocol, null) != null ? ["external"] : null
    route_policy      = try(imp.route_policy, null)
    redistributes = try(length(imp.redistributes) == 0, true) ? null : [for r in imp.redistributes : {
      protocol          = try(r.protocol, null)
      protocol_variable = try(r.protocol_variable, null)
      route_policy      = try(r.route_policy, null)
    }]
  }]
  route_vpn_imports = try(length(each.value.route_vpn_imports) == 0, true) ? null : [for imp in each.value.route_vpn_imports : {
    protocol               = try(imp.protocol, null)
    protocol_variable      = try(imp.protocol_variable, null)
    route_policy           = try(imp.route_policy, null)
    route_policy_variable  = try(imp.route_policy_variable, null)
    source_vpn_id          = try(imp.source_vpn_id, null)
    source_vpn_id_variable = try(imp.source_vpn_id_variable, null)
    redistributes = try(length(imp.redistributes) == 0, true) ? null : [for r in imp.redistributes : {
      protocol              = try(r.protocol, null)
      protocol_variable     = try(r.protocol_variable, null)
      route_policy          = try(r.route_policy, null)
      route_policy_variable = try(r.route_policy_variable, null)
    }]
  }]
  services = try(length(each.value.services) == 0, true) ? null : [for service in each.value.services : {
    address               = try(service.addresses, null)
    address_variable      = try(service.addresses_variable, null)
    service_types         = try(service.service_type, null)
    track_enable          = try(service.track_enable, null)
    track_enable_variable = try(service.track_enable_variable, null)
  }]
  static_nat_rules = try(length(each.value.static_nat_rules) == 0, true) ? null : [for rule in each.value.static_nat_rules : {
    pool_name                     = try(rule.nat_pool_id, null)
    pool_name_variable            = try(rule.nat_pool_id_variable, null)
    optional                      = try(rule.optional, null)
    source_ip                     = try(rule.source_ip, null)
    source_ip_variable            = try(rule.source_ip_variable, null)
    static_nat_direction          = try(rule.direction, null)
    static_nat_direction_variable = try(rule.direction_variable, null)
    tracker_id                    = try(rule.tracker_id, null)
    tracker_id_variable           = try(rule.tracker_id_variable, null)
    translate_ip                  = try(rule.translate_ip, null)
    translate_ip_variable         = try(rule.translate_ip_variable, null)
  }]
  static_nat_subnet_rules = try(length(each.value.static_nat_subnet_rules) == 0, true) ? null : [for rule in each.value.static_nat_subnet_rules : {
    prefix_length                 = try(rule.prefix_length, null)
    prefix_length_variable        = try(rule.prefix_length_variable, null)
    optional                      = try(rule.optional, null)
    source_ip_subnet              = try(rule.source_ip_subnet, null)
    source_ip_subnet_variable     = try(rule.source_ip_subnet_variable, null)
    static_nat_direction          = try(rule.direction, null)
    static_nat_direction_variable = try(rule.direction_variable, null)
    tracker_id                    = try(rule.tracker_id, null)
    tracker_id_variable           = try(rule.tracker_id_variable, null)
    translate_ip_subnet           = try(rule.translate_ip_subnet, null)
    translate_ip_subnet_variable  = try(rule.translate_ip_subnet_variable, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_vpn_interface_feature_template" "cisco_vpn_interface_feature_template" {
  for_each                                       = { for t in try(local.edge_feature_templates.ethernet_interface_templates, {}) : t.name => t }
  name                                           = each.value.name
  description                                    = each.value.description
  device_types                                   = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.ethernet_interface_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  address                                        = try(each.value.ipv4_address, null)
  address_variable                               = try(each.value.ipv4_address_variable, null)
  arp_timeout                                    = try(each.value.arp_timeout, null)
  arp_timeout_variable                           = try(each.value.arp_timeout_variable, null)
  auto_bandwidth_detect                          = try(each.value.bandwidth_auto_detect, null)
  auto_bandwidth_detect_variable                 = try(each.value.bandwidth_auto_detect_variable, null)
  autonegotiate                                  = try(each.value.autonegotiate, null)
  autonegotiate_variable                         = try(each.value.autonegotiate_variable, null)
  bandwidth_downstream                           = try(each.value.bandwidth_downstream, null)
  bandwidth_downstream_variable                  = try(each.value.bandwidth_downstream_variable, null)
  bandwidth_upstream                             = try(each.value.bandwidth_upstream, null)
  bandwidth_upstream_variable                    = try(each.value.bandwidth_upstream_variable, null)
  block_non_source_ip                            = try(each.value.block_non_source_ip, null)
  block_non_source_ip_variable                   = try(each.value.block_non_source_ip_variable, null)
  core_region                                    = try(each.value.tunnel_interface.core_region, null)
  core_region_variable                           = try(each.value.tunnel_interface.core_region_variable, null)
  dhcp                                           = try(each.value.ipv4_address_dhcp, null) == true ? true : null
  dhcp_distance                                  = try(each.value.dhcp_distance, null)
  dhcp_distance_variable                         = try(each.value.dhcp_distance_variable, null)
  duplex                                         = try(each.value.duplex, null)
  duplex_variable                                = try(each.value.duplex_variable, null)
  enable_core_region                             = try(each.value.tunnel_interface.enable_core_region, null)
  enable_sgt                                     = try(each.value.enable_sgt, null)
  gre_tunnel_source_ip                           = try(each.value.gre_tunnel_source_ip, null)
  gre_tunnel_source_ip_variable                  = try(each.value.gre_tunnel_source_ip_variable, null)
  gre_tunnel_xconnect                            = try(each.value.gre_tunnel_xconnect, null)
  gre_tunnel_xconnect_variable                   = try(each.value.gre_tunnel_xconnect_variable, null)
  icmp_redirect_disable                          = try(each.value.icmp_redirect_disable, null)
  icmp_redirect_disable_variable                 = try(each.value.icmp_redirect_disable_variable, null)
  interface_description                          = try(each.value.interface_description, null)
  interface_description_variable                 = try(each.value.interface_description_variable, null)
  interface_mtu                                  = try(each.value.mtu, null)
  interface_mtu_variable                         = try(each.value.mtu_variable, null)
  interface_name                                 = try(each.value.interface_name, null)
  interface_name_variable                        = try(each.value.interface_name_variable, null)
  ip_directed_broadcast                          = try(each.value.ip_directed_broadcast, null)
  ip_directed_broadcast_variable                 = try(each.value.ip_directed_broadcast_variable, null)
  ip_mtu                                         = try(each.value.ip_mtu, null)
  ip_mtu_variable                                = try(each.value.ip_mtu_variable, null)
  iperf_server                                   = try(each.value.iperf_server, null)
  iperf_server_variable                          = try(each.value.iperf_server_variable, null)
  ipv4_dhcp_helper                               = try(each.value.ipv4_dhcp_helpers, null)
  ipv4_dhcp_helper_variable                      = try(each.value.ipv4_dhcp_helpers_variable, null)
  ipv6_address                                   = try(each.value.ipv6_address, null)
  ipv6_address_variable                          = try(each.value.ipv6_address_variable, null)
  ipv6_nat                                       = try(each.value.ipv6_nat, null)
  load_interval                                  = try(each.value.load_interval, null)
  load_interval_variable                         = try(each.value.load_interval_variable, null)
  mac_address                                    = try(each.value.mac_address, null)
  mac_address_variable                           = try(each.value.mac_address_variable, null)
  media_type                                     = try(each.value.media_type, null)
  media_type_variable                            = try(each.value.media_type_variable, null)
  nat                                            = try(each.value.ipv4_nat, each.value.ipv6_nat, null)
  nat64_interface                                = try(each.value.ipv6_nat_type, null) == "nat64" ? true : null
  nat66_interface                                = try(each.value.ipv6_nat_type, null) == "nat66" ? true : null
  nat_inside_source_loopback_interface           = try(each.value.ipv4_nat_inside_source_loopback_interface, null)
  nat_inside_source_loopback_interface_variable  = try(each.value.ipv4_nat_inside_source_loopback_interface_variable, null)
  nat_overload                                   = try(each.value.ipv4_nat_overload, null)
  nat_overload_variable                          = try(each.value.ipv4_nat_overload_variable, null)
  nat_pool_prefix_length                         = try(each.value.ipv4_nat_pool_prefix_length, null)
  nat_pool_prefix_length_variable                = try(each.value.ipv4_nat_pool_prefix_length_variable, null)
  nat_pool_range_end                             = try(each.value.ipv4_nat_pool_range_end, null)
  nat_pool_range_end_variable                    = try(each.value.ipv4_nat_pool_range_end_variable, null)
  nat_pool_range_start                           = try(each.value.ipv4_nat_pool_range_start, null)
  nat_pool_range_start_variable                  = try(each.value.ipv4_nat_pool_range_start_variable, null)
  nat_type                                       = try(each.value.ipv4_nat_type, null)
  nat_type_variable                              = try(each.value.ipv4_nat_type_variable, null)
  propagate_sgt                                  = try(each.value.sgt_propagation, null)
  qos_adaptive_bandwidth_downstream              = try(each.value.adaptive_qos_shaping_rate_downstream.default, null)
  qos_adaptive_bandwidth_downstream_variable     = try(each.value.adaptive_qos_shaping_rate_downstream.default_variable, null)
  qos_adaptive_bandwidth_upstream                = try(each.value.adaptive_qos_shaping_rate_upstream.default, null)
  qos_adaptive_bandwidth_upstream_variable       = try(each.value.adaptive_qos_shaping_rate_upstream.default_variable, null)
  qos_adaptive_max_downstream                    = try(each.value.adaptive_qos_shaping_rate_downstream.maximum, null)
  qos_adaptive_max_downstream_variable           = try(each.value.adaptive_qos_shaping_rate_downstream.maximum_variable, null)
  qos_adaptive_max_upstream                      = try(each.value.adaptive_qos_shaping_rate_upstream.maximum, null)
  qos_adaptive_max_upstream_variable             = try(each.value.adaptive_qos_shaping_rate_upstream.maximum_variable, null)
  qos_adaptive_min_downstream                    = try(each.value.adaptive_qos_shaping_rate_downstream.minimum, null)
  qos_adaptive_min_downstream_variable           = try(each.value.adaptive_qos_shaping_rate_downstream.minimum_variable, null)
  qos_adaptive_min_upstream                      = try(each.value.adaptive_qos_shaping_rate_upstream.minimum, null)
  qos_adaptive_min_upstream_variable             = try(each.value.adaptive_qos_shaping_rate_upstream.minimum_variable, null)
  qos_adaptive_period                            = try(each.value.adaptive_qos_period, null)
  qos_adaptive_period_variable                   = try(each.value.adaptive_qos_period_variable, null)
  qos_map                                        = try(each.value.qos_map, null)
  qos_map_variable                               = try(each.value.qos_map_variable, null)
  qos_map_vpn                                    = try(each.value.vpn_qos_map, null)
  qos_map_vpn_variable                           = try(each.value.vpn_qos_map_variable, null)
  rewrite_rule_name                              = try(each.value.rewrite_rule, null)
  rewrite_rule_name_variable                     = try(each.value.rewrite_rule_variable, null)
  secondary_region                               = try(each.value.tunnel_interface.secondary_region, null)
  secondary_region_variable                      = try(each.value.tunnel_interface.secondary_region_variable, null)
  sgt_enforcement                                = try(each.value.sgt_enforcement, null)
  sgt_enforcement_sgt                            = try(each.value.sgt_enforcement_tag, null)
  sgt_enforcement_sgt_variable                   = try(each.value.sgt_enforcement_tag_variable, null)
  shaping_rate                                   = try(each.value.shaping_rate, null)
  shaping_rate_variable                          = try(each.value.shaping_rate_variable, null)
  shutdown                                       = try(each.value.shutdown, null)
  shutdown_variable                              = try(each.value.shutdown_variable, null)
  speed                                          = try(each.value.speed, null)
  speed_variable                                 = try(each.value.speed_variable, null)
  static_sgt                                     = try(each.value.static_sgt, null)
  static_sgt_variable                            = try(each.value.static_sgt_variable, null)
  static_sgt_trusted                             = try(each.value.sgt_trusted, null)
  tcp_mss_adjust                                 = try(each.value.tcp_mss, null)
  tcp_mss_adjust_variable                        = try(each.value.tcp_mss_variable, null)
  tcp_timeout                                    = try(each.value.ipv4_nat_tcp_timeout, null)
  tcp_timeout_variable                           = try(each.value.ipv4_nat_tcp_timeout_variable, null)
  tloc_extension                                 = try(each.value.tloc_extension, null)
  tloc_extension_variable                        = try(each.value.tloc_extension_variable, null)
  tracker                                        = try([each.value.tracker], null)
  tracker_variable                               = try(each.value.tracker_variable, null)
  tunnel_bandwidth                               = try(each.value.tunnel_interface.per_tunnel_qos_bandwidth_percent, null)
  tunnel_bandwidth_variable                      = try(each.value.tunnel_interface.per_tunnel_qos_bandwidth_percent_variable, null)
  tunnel_interface_allow_all                     = try(each.value.tunnel_interface.allow_service_all, null)
  tunnel_interface_allow_all_variable            = try(each.value.tunnel_interface.allow_service_all_variable, null)
  tunnel_interface_allow_bgp                     = try(each.value.tunnel_interface.allow_service_bgp, null)
  tunnel_interface_allow_bgp_variable            = try(each.value.tunnel_interface.allow_service_bgp_variable, null)
  tunnel_interface_allow_dhcp                    = try(each.value.tunnel_interface.allow_service_dhcp, null)
  tunnel_interface_allow_dhcp_variable           = try(each.value.tunnel_interface.allow_service_dhcp_variable, null)
  tunnel_interface_allow_dns                     = try(each.value.tunnel_interface.allow_service_dns, null)
  tunnel_interface_allow_dns_variable            = try(each.value.tunnel_interface.allow_service_dns_variable, null)
  tunnel_interface_allow_https                   = try(each.value.tunnel_interface.allow_service_https, null)
  tunnel_interface_allow_https_variable          = try(each.value.tunnel_interface.allow_service_https_variable, null)
  tunnel_interface_allow_icmp                    = try(each.value.tunnel_interface.allow_service_icmp, null)
  tunnel_interface_allow_icmp_variable           = try(each.value.tunnel_interface.allow_service_icmp_variable, null)
  tunnel_interface_allow_netconf                 = try(each.value.tunnel_interface.allow_service_netconf, null)
  tunnel_interface_allow_netconf_variable        = try(each.value.tunnel_interface.allow_service_netconf_variable, null)
  tunnel_interface_allow_ntp                     = try(each.value.tunnel_interface.allow_service_ntp, null)
  tunnel_interface_allow_ntp_variable            = try(each.value.tunnel_interface.allow_service_ntp_variable, null)
  tunnel_interface_allow_ospf                    = try(each.value.tunnel_interface.allow_service_ospf, null)
  tunnel_interface_allow_ospf_variable           = try(each.value.tunnel_interface.allow_service_ospf_variable, null)
  tunnel_interface_allow_snmp                    = try(each.value.tunnel_interface.allow_service_snmp, null)
  tunnel_interface_allow_snmp_variable           = try(each.value.tunnel_interface.allow_service_snmp_variable, null)
  tunnel_interface_allow_ssh                     = try(each.value.tunnel_interface.allow_service_ssh, null)
  tunnel_interface_allow_ssh_variable            = try(each.value.tunnel_interface.allow_service_ssh_variable, null)
  tunnel_interface_allow_stun                    = try(each.value.tunnel_interface.allow_service_stun, null)
  tunnel_interface_allow_stun_variable           = try(each.value.tunnel_interface.allow_service_stun_variable, null)
  tunnel_interface_bind_loopback_tunnel          = try(each.value.tunnel_interface.bind_loopback_tunnel, null)
  tunnel_interface_bind_loopback_tunnel_variable = try(each.value.tunnel_interface.bind_loopback_tunnel_variable, null)
  tunnel_interface_border                        = try(each.value.tunnel_interface.border, null)
  tunnel_interface_border_variable               = try(each.value.tunnel_interface.border_variable, null)
  tunnel_interface_carrier                       = try(each.value.tunnel_interface.carrier, null)
  tunnel_interface_carrier_variable              = try(each.value.tunnel_interface.carrier_variable, null)
  tunnel_interface_clear_dont_fragment           = try(each.value.tunnel_interface.clear_dont_fragment, null)
  tunnel_interface_clear_dont_fragment_variable  = try(each.value.tunnel_interface.clear_dont_fragment_variable, null)
  tunnel_interface_color                         = try(each.value.tunnel_interface.color, null)
  tunnel_interface_color_variable                = try(each.value.tunnel_interface.color_variable, null)
  tunnel_interface_color_restrict                = try(each.value.tunnel_interface.restrict, null)
  tunnel_interface_color_restrict_variable       = try(each.value.tunnel_interface.restrict_variable, null)
  tunnel_interface_encapsulations = try(each.value.tunnel_interface.gre_encapsulation, each.value.tunnel_interface.ipsec_encapsulation, null) == null ? null : flatten([
    try(each.value.tunnel_interface.gre_encapsulation, null) == null ? [] : [{
      encapsulation       = "gre"
      preference          = try(each.value.tunnel_interface.gre_preference, null)
      preference_variable = try(each.value.tunnel_interface.gre_preference_variable, null)
      weight              = try(each.value.tunnel_interface.gre_weight, null)
      weight_variable     = try(each.value.tunnel_interface.gre_weight_variable, null)
    }],
    try(each.value.tunnel_interface.ipsec_encapsulation, null) == null ? [] : [{
      encapsulation       = "ipsec"
      preference          = try(each.value.tunnel_interface.ipsec_preference, null)
      preference_variable = try(each.value.tunnel_interface.ipsec_preference_variable, null)
      weight              = try(each.value.tunnel_interface.ipsec_weight, null)
      weight_variable     = try(each.value.tunnel_interface.ipsec_weight_variable, null)
    }]
  ])
  tunnel_interface_exclude_controller_group_list          = try(each.value.tunnel_interface.exclude_controller_groups, null)
  tunnel_interface_exclude_controller_group_list_variable = try(each.value.tunnel_interface.exclude_controller_groups_variable, null)
  tunnel_interface_gre_tunnel_destination_ip              = try(each.value.tunnel_interface.gre_tunnel_destination_ip, null)
  tunnel_interface_gre_tunnel_destination_ip_variable     = try(each.value.tunnel_interface.gre_tunnel_destination_ip_variable, null)
  tunnel_interface_groups                                 = try([each.value.tunnel_interface.group], null)
  tunnel_interface_groups_variable                        = try(each.value.tunnel_interface.group_variable, null)
  tunnel_interface_hello_interval                         = try(each.value.tunnel_interface.hello_interval, null)
  tunnel_interface_hello_interval_variable                = try(each.value.tunnel_interface.hello_interval_variable, null)
  tunnel_interface_hello_tolerance                        = try(each.value.tunnel_interface.hello_tolerance, null)
  tunnel_interface_hello_tolerance_variable               = try(each.value.tunnel_interface.hello_tolerance_variable, null)
  tunnel_interface_last_resort_circuit                    = try(each.value.tunnel_interface.last_resort_circuit, null)
  tunnel_interface_last_resort_circuit_variable           = try(each.value.tunnel_interface.last_resort_circuit_variable, null)
  tunnel_interface_low_bandwidth_link                     = try(each.value.tunnel_interface.low_bandwidth_link, null)
  tunnel_interface_low_bandwidth_link_variable            = try(each.value.tunnel_interface.low_bandwidth_link_variable, null)
  tunnel_interface_max_control_connections                = try(each.value.tunnel_interface.max_control_connections, null)
  tunnel_interface_max_control_connections_variable       = try(each.value.tunnel_interface.max_control_connections_variable, null)
  tunnel_interface_nat_refresh_interval                   = try(each.value.tunnel_interface.nat_refresh_interval, null)
  tunnel_interface_nat_refresh_interval_variable          = try(each.value.tunnel_interface.nat_refresh_interval_variable, null)
  tunnel_interface_network_broadcast                      = try(each.value.tunnel_interface.network_broadcast, null)
  tunnel_interface_network_broadcast_variable             = try(each.value.tunnel_interface.network_broadcast_variable, null)
  tunnel_interface_port_hop                               = try(each.value.tunnel_interface.port_hop, null)
  tunnel_interface_port_hop_variable                      = try(each.value.tunnel_interface.port_hop_variable, null)
  tunnel_interface_propagate_sgt                          = try(each.value.tunnel_interface.propagate_sgt, null)
  tunnel_interface_propagate_sgt_variable                 = try(each.value.tunnel_interface.propagate_sgt_variable, null)
  tunnel_interface_tunnel_tcp_mss                         = try(each.value.tunnel_interface.tcp_mss, null)
  tunnel_interface_tunnel_tcp_mss_variable                = try(each.value.tunnel_interface.tcp_mss_variable, null)
  tunnel_interface_vbond_as_stun_server                   = try(each.value.tunnel_interface.vbond_as_stun_server, null)
  tunnel_interface_vbond_as_stun_server_variable          = try(each.value.tunnel_interface.vbond_as_stun_server_variable, null)
  tunnel_interface_vmanage_connection_preference          = try(each.value.tunnel_interface.vmanage_connection_preference, null)
  tunnel_interface_vmanage_connection_preference_variable = try(each.value.tunnel_interface.vmanage_connection_preference_variable, null)
  tunnel_qos_mode                                         = try(each.value.tunnel_interface.per_tunnel_qos_mode, null)
  tunnel_qos_mode_variable                                = try(each.value.tunnel_interface.per_tunnel_qos_mode_variable, null)
  udp_timeout                                             = try(each.value.ipv4_nat_udp_timeout, null)
  udp_timeout_variable                                    = try(each.value.ipv4_nat_udp_timeout_variable, null)

  access_lists = try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? null : flatten([
    try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_ingress_access_list, null)
      acl_name_variable = try(each.value.ipv4_ingress_access_list_variable, null)
      direction         = "in"
    }],
    try(each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_egress_access_list, null)
      acl_name_variable = try(each.value.ipv4_egress_access_list_variable, null)
      direction         = "out"
    }]
  ])
  ipv4_secondary_addresses = try(length(each.value.ipv4_secondary_addresses) == 0, true) ? null : [for adr in try(each.value.ipv4_secondary_addresses, []) : {
    address          = try(adr.address, null)
    address_variable = try(adr.address_variable, null)
  }]
  ipv4_vrrps = try(length(each.value.ipv4_vrrp_groups) == 0, true) ? null : [for group in each.value.ipv4_vrrp_groups : {
    group_id            = try(group.id, null)
    group_id_variable   = try(group.id_variable, null)
    ip_address          = try(group.address, null)
    ip_address_variable = try(group.address_variable, null)
    ipv4_secondary_addresses = try(length(group.secondary_addresses) == 0, true) ? null : [for adr in group.secondary_addresses : {
      ip_address          = try(adr.address, null)
      ip_address_variable = try(adr.address_variable, null)
    }]
    optional                              = try(group.optional, null)
    priority                              = try(group.priority, null)
    priority_variable                     = try(group.priority_variable, null)
    timer                                 = try(group.timer, null)
    timer_variable                        = try(group.timer_variable, null)
    tloc_preference_change                = try(group.tloc_preference_change, null)
    tloc_preference_change_value          = try(group.tloc_preference_change_value, null)
    tloc_preference_change_value_variable = try(group.tloc_preference_change_value_variable, null)
    track_omp                             = try(group.track_omp, null)
    track_prefix_list                     = try(group.track_prefix_list, null)
    track_prefix_list_variable            = try(group.track_prefix_list_variable, null)
    tracking_objects = try(length(group.tracking_objects) == 0, true) ? null : [for obj in group.tracking_objects : {
      decrement_value          = try(obj.decrement_value, null)
      decrement_value_variable = try(obj.decrement_value_variable, null)
      track_action             = try(obj.action, null)
      track_action_variable    = try(obj.action_variable, null)
      tracker_id               = try(obj.id, null)
      tracker_id_variable      = try(obj.id_variable, null)
    }]
  }]
  ipv6_access_lists = try(each.value.ipv6_ingress_access_list, each.value.ipv6_ingress_access_list_variable, each.value.ipv6_egress_access_list, each.value.ipv6_egress_access_list_variable, null) == null ? null : flatten([
    try(each.value.ipv6_ingress_access_list, each.value.ipv6_ingress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv6_ingress_access_list, null)
      acl_name_variable = try(each.value.ipv6_ingress_access_list_variable, null)
      direction         = "in"
    }],
    try(each.value.ipv6_egress_access_list, each.value.ipv6_egress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv6_egress_access_list, null)
      acl_name_variable = try(each.value.ipv6_egress_access_list_variable, null)
      direction         = "out"
    }]
  ])
  ipv6_dhcp_helpers = try(length(each.value.ipv6_dhcp_helpers) == 0, true) ? null : [for helper in each.value.ipv6_dhcp_helpers : {
    address          = try(helper.address, null)
    address_variable = try(helper.address_variable, null)
    vpn_id           = try(helper.vpn_id, null)
    vpn_id_variable  = try(helper.vpn_id_variable, null)
  }]
  ipv6_secondary_addresses = try(length(each.value.ipv6_secondary_addresses) == 0, true) ? null : [for adr in each.value.ipv6_secondary_addresses : {
    address          = try(adr.address, null)
    address_variable = try(adr.address_variable, null)
  }]
  ipv6_vrrps = try(length(each.value.ipv6_vrrp_groups) == 0, true) ? null : [for group in each.value.ipv6_vrrp_groups : {
    group_id          = try(group.id, null)
    group_id_variable = try(group.id_variable, null)
    ipv6_addresses = try(group.link_local_address, group.link_local_address_variable, group.global_prefix, group.global_prefix_variable, null) == null ? null : [{
      ipv6_link_local          = try(group.link_local_address, null)
      ipv6_link_local_variable = try(group.link_local_address_variable, null)
      prefix                   = try(group.global_prefix, null)
      prefix_variable          = try(group.global_prefix_variable, null)
    }]
    optional                   = try(group.optional, null)
    priority                   = try(group.priority, null)
    priority_variable          = try(group.priority_variable, null)
    timer                      = try(group.timer, null)
    timer_variable             = try(group.timer_variable, null)
    track_omp                  = try(group.track_omp, null)
    track_omp_variable         = try(group.track_omp_variable, null)
    track_prefix_list          = try(group.track_prefix_list, null)
    track_prefix_list_variable = try(group.track_prefix_list_variable, null)
  }]
  static_arps = try(length(each.value.static_arps) == 0, true) ? null : [for arp in each.value.static_arps : {
    ip_address          = try(arp.ip_address, null)
    ip_address_variable = try(arp.ip_address_variable, null)
    mac                 = try(arp.mac_address, null)
    mac_variable        = try(arp.mac_address_variable, null)
    optional            = try(arp.optional, null)
  }]
  static_nat66_entries = try(length(each.value.ipv6_static_nat_rules) == 0, true) ? null : [for entry in each.value.ipv6_static_nat_rules : {
    source_prefix                     = try(entry.source_prefix, null)
    source_prefix_variable            = try(entry.source_prefix_variable, null)
    source_vpn_id                     = try(entry.source_vpn_id, null)
    source_vpn_id_variable            = try(entry.source_vpn_id_variable, null)
    translated_source_prefix          = try(entry.translated_source_prefix, null)
    translated_source_prefix_variable = try(entry.translated_source_prefix_variable, null)
    optional                          = try(entry.optional, null)
  }]
  static_nat_entries = try(length(each.value.ipv4_static_nat_rules) == 0, true) ? null : [for entry in each.value.ipv4_static_nat_rules : {
    source_ip              = try(entry.source_ip, null)
    source_ip_variable     = try(entry.source_ip_variable, null)
    source_vpn_id          = try(entry.source_vpn_id, null)
    source_vpn_id_variable = try(entry.source_vpn_id_variable, null)
    static_nat_direction   = "inside"
    translate_ip           = try(entry.translate_ip, null)
    translate_ip_variable  = try(entry.translate_ip_variable, null)
    optional               = try(entry.optional, null)
  }]
  static_port_forward_entries = try(length(each.value.ipv4_port_forwarding_rules) == 0, true) ? null : [for entry in each.value.ipv4_port_forwarding_rules : {
    protocol                = try(entry.protocol, null)
    protocol_variable       = try(entry.protocol_variable, null)
    source_ip               = try(entry.source_ip, null)
    source_ip_variable      = try(entry.source_ip_variable, null)
    source_port             = try(entry.source_port, null)
    source_port_variable    = try(entry.source_port_variable, null)
    source_vpn_id           = try(entry.source_vpn_id, null)
    source_vpn_id_variable  = try(entry.source_vpn_id_variable, null)
    static_nat_direction    = "inside"
    translate_ip            = try(entry.translate_ip, null)
    translate_ip_variable   = try(entry.translate_ip_variable, null)
    translate_port          = try(entry.translate_port, null)
    translate_port_variable = try(entry.translate_port_variable, null)
    optional                = try(entry.optional, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cisco_vpn_interface_ipsec_feature_template" "cisco_vpn_interface_ipsec_feature_template" {
  for_each                               = { for t in try(local.edge_feature_templates.ipsec_interface_templates, {}) : t.name => t }
  name                                   = each.value.name
  description                            = each.value.description
  device_types                           = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.ipsec_interface_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  application                            = try(each.value.application, null)
  application_variable                   = try(each.value.application_variable, null)
  clear_dont_fragment                    = try(each.value.clear_dont_fragment, null)
  clear_dont_fragment_variable           = try(each.value.clear_dont_fragment_variable, null)
  dead_peer_detection_interval           = try(each.value.dead_peer_detection_interval, null)
  dead_peer_detection_interval_variable  = try(each.value.dead_peer_detection_interval_variable, null)
  dead_peer_detection_retries            = try(each.value.dead_peer_detection_retries, null)
  dead_peer_detection_retries_variable   = try(each.value.dead_peer_detection_retries_variable, null)
  ike_ciphersuite                        = try(each.value.ike.ciphersuite, null)
  ike_ciphersuite_variable               = try(each.value.ike.ciphersuite_variable, null)
  ike_group                              = try(each.value.ike.group, null)
  ike_group_variable                     = try(each.value.ike.group_variable, null)
  ike_mode                               = try(each.value.ike.mode, null)
  ike_mode_variable                      = try(each.value.ike.mode_variable, null)
  ike_pre_shared_key                     = try(each.value.ike.pre_shared_key, null)
  ike_pre_shared_key_variable            = try(each.value.ike.pre_shared_key_variable, null)
  ike_pre_shared_key_local_id            = try(each.value.ike.pre_shared_key_local_id, null)
  ike_pre_shared_key_local_id_variable   = try(each.value.ike.pre_shared_key_local_id_variable, null)
  ike_pre_shared_key_remote_id           = try(each.value.ike.pre_shared_key_remote_id, null)
  ike_pre_shared_key_remote_id_variable  = try(each.value.ike.pre_shared_key_remote_id_variable, null)
  ike_rekey_interval                     = try(each.value.ike.rekey_interval, null)
  ike_rekey_interval_variable            = try(each.value.ike.rekey_interval_variable, null)
  ike_version                            = try(each.value.ike.version, null)
  interface_description                  = try(each.value.interface_description, null)
  interface_description_variable         = try(each.value.interface_description_variable, null)
  interface_name                         = try(each.value.interface_name, null)
  interface_name_variable                = try(each.value.interface_name_variable, null)
  ip_address                             = try(each.value.ip_address, null)
  ip_address_variable                    = try(each.value.ip_address_variable, null)
  ipsec_ciphersuite                      = try(each.value.ipsec.ciphersuite, null)
  ipsec_ciphersuite_variable             = try(each.value.ipsec.ciphersuite_variable, null)
  ipsec_perfect_forward_secrecy          = try(each.value.ipsec.perfect_forward_secrecy, null)
  ipsec_perfect_forward_secrecy_variable = try(each.value.ipsec.perfect_forward_secrecy_variable, null)
  ipsec_rekey_interval                   = try(each.value.ipsec.rekey_interval, null)
  ipsec_rekey_interval_variable          = try(each.value.ipsec.rekey_interval_variable, null)
  ipsec_replay_window                    = try(each.value.ipsec.replay_window, null)
  ipsec_replay_window_variable           = try(each.value.ipsec.replay_window_variable, null)
  mtu                                    = try(each.value.mtu, null)
  mtu_variable                           = try(each.value.mtu_variable, null)
  shutdown                               = try(each.value.shutdown, null)
  shutdown_variable                      = try(each.value.shutdown_variable, null)
  tcp_mss_adjust                         = try(each.value.tcp_mss, null)
  tcp_mss_adjust_variable                = try(each.value.tcp_mss_variable, null)
  tracker                                = try([each.value.tracker], null)
  tracker_variable                       = try(each.value.tracker_variable, null)
  tunnel_destination                     = try(each.value.tunnel_destination, null)
  tunnel_destination_variable            = try(each.value.tunnel_destination_variable, null)
  tunnel_source_interface                = try(each.value.tunnel_source_interface, null)
  tunnel_source_interface_variable       = try(each.value.tunnel_source_interface_variable, null)
  tunnel_source                          = try(each.value.tunnel_source_ip, null)
  tunnel_source_variable                 = try(each.value.tunnel_source_ip_variable, null)
  depends_on                             = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_cli_template_feature_template" "cli_template_feature_template" {
  for_each     = { for t in try(local.edge_feature_templates.cli_templates, {}) : t.name => t }
  name         = each.value.name
  description  = each.value.description
  device_types = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.cli_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  cli_config   = each.value.cli_config
  depends_on = [
    sdwan_cedge_aaa_feature_template.cedge_aaa_feature_template,
    sdwan_cedge_global_feature_template.cedge_global_feature_template,
    sdwan_cisco_banner_feature_template.cisco_banner_feature_template,
    sdwan_cisco_bfd_feature_template.cisco_bfd_feature_template,
    sdwan_cisco_bgp_feature_template.cisco_bgp_feature_template,
    sdwan_cisco_dhcp_server_feature_template.cisco_dhcp_server_feature_template,
    sdwan_cisco_logging_feature_template.cisco_logging_feature_template,
    sdwan_cisco_ntp_feature_template.cisco_ntp_feature_template,
    sdwan_cisco_omp_feature_template.cisco_omp_feature_template,
    sdwan_cisco_ospf_feature_template.cisco_ospf_feature_template,
    sdwan_cisco_secure_internet_gateway_feature_template.cisco_secure_internet_gateway_feature_template,
    sdwan_cisco_security_feature_template.cisco_security_feature_template,
    sdwan_cisco_sig_credentials_feature_template.cisco_sig_credentials_feature_template,
    sdwan_cisco_snmp_feature_template.cisco_snmp_feature_template,
    sdwan_cisco_system_feature_template.cisco_system_feature_template,
    sdwan_cisco_thousandeyes_feature_template.cisco_thousandeyes_feature_template,
    sdwan_cisco_vpn_feature_template.cisco_vpn_feature_template,
    sdwan_cisco_vpn_interface_feature_template.cisco_vpn_interface_feature_template,
    sdwan_cisco_vpn_interface_ipsec_feature_template.cisco_vpn_interface_ipsec_feature_template,
    sdwan_switchport_feature_template.switchport_feature_template,
    sdwan_vpn_interface_svi_feature_template.vpn_interface_svi_feature_template
  ]
}

resource "sdwan_switchport_feature_template" "switchport_feature_template" {
  for_each              = { for t in try(local.edge_feature_templates.switchport_templates, {}) : t.name => t }
  name                  = each.value.name
  description           = each.value.description
  device_types          = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.switchport_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  age_out_time          = try(each.value.age_out_time, null)
  age_out_time_variable = try(each.value.age_out_time_variable, null)
  module_type           = each.value.module_type
  slot                  = each.value.slot
  sub_slot              = each.value.sub_slot
  interfaces = try(length(each.value.interfaces) == 0, true) ? null : [for interface in try(each.value.interfaces, []) : {
    dot1x_control_direction                           = try(interface.dot1x.control_direction, null)
    dot1x_control_direction_variable                  = try(interface.dot1x.control_direction_variable, null)
    dot1x_critical_vlan                               = try(interface.dot1x.critical_vlan, null)
    dot1x_critical_vlan_variable                      = try(interface.dot1x.critical_vlan_variable, null)
    dot1x_enable                                      = try(interface.dot1x.enable, null)
    dot1x_enable_criticial_voice_vlan                 = try(interface.dot1x.enable_criticial_voice_vlan, null)
    dot1x_enable_criticial_voice_vlan_variable        = try(interface.dot1x.enable_criticial_voice_vlan_variable, null)
    dot1x_pae_enable                                  = try(interface.dot1x.enable_pae, null)
    dot1x_pae_enable_variable                         = try(interface.dot1x.enable_pae_variable, null)
    dot1x_enable_periodic_reauth                      = try(interface.dot1x.enable_periodic_reauth, null)
    dot1x_enable_periodic_reauth_variable             = try(interface.dot1x.enable_periodic_reauth_variable, null)
    dot1x_guest_vlan                                  = try(interface.dot1x.guest_vlan, null)
    dot1x_guest_vlan_variable                         = try(interface.dot1x.guest_vlan_variable, null)
    dot1x_host_mode                                   = try(interface.dot1x.host_mode, null)
    dot1x_host_mode_variable                          = try(interface.dot1x.host_mode_variable, null)
    dot1x_mac_authentication_bypass                   = try(interface.dot1x.mac_authentication_bypass, null)
    dot1x_mac_authentication_bypass_variable          = try(interface.dot1x.mac_authentication_bypass_variable, null)
    dot1x_periodic_reauth_inactivity_timeout          = try(interface.dot1x.periodic_reauth_inactivity_timeout, null)
    dot1x_periodic_reauth_inactivity_timeout_variable = try(interface.dot1x.periodic_reauth_inactivity_timeout_variable, null)
    dot1x_periodic_reauth_interval                    = try(interface.dot1x.periodic_reauth_interval, null)
    dot1x_periodic_reauth_interval_variable           = try(interface.dot1x.periodic_reauth_interval_variable, null)
    dot1x_port_control                                = try(interface.dot1x.port_control_mode, null)
    dot1x_port_control_variable                       = try(interface.dot1x.port_control_mode_variable, null)
    dot1x_restricted_vlan                             = try(interface.dot1x.restricted_vlan, null)
    dot1x_restricted_vlan_variable                    = try(interface.dot1x.restricted_vlan_variable, null)
    voice_vlan                                        = try(interface.voice_vlan, null)
    voice_vlan_variable                               = try(interface.voice_vlan_variable, null)
    duplex                                            = try(interface.duplex, null)
    duplex_variable                                   = try(interface.duplex_variable, null)
    name                                              = try(interface.name, null)
    name_variable                                     = try(interface.name_variable, null)
    optional                                          = try(interface.optional, null)
    shutdown                                          = try(interface.shutdown, null)
    shutdown_variable                                 = try(interface.shutdown_variable, null)
    speed                                             = try(interface.speed, null)
    speed_variable                                    = try(interface.speed_variable, null)
    switchport_mode                                   = try(interface.mode, null)
    switchport_access_vlan                            = try(interface.access_vlan, null)
    switchport_access_vlan_variable                   = try(interface.access_vlan_variable, null)
    switchport_trunk_allowed_vlans                    = length(concat(try(interface.trunk_allowed_vlans, []), try(interface.trunk_allowed_vlans_ranges, []))) > 0 ? join(",", concat([for p in try(interface.trunk_allowed_vlans, []) : p], [for r in try(interface.trunk_allowed_vlans_ranges, []) : "${r.from}-${r.to}"])) : null
    switchport_trunk_allowed_vlans_variable           = try(interface.trunk_allowed_vlans_variable, null)
    switchport_trunk_native_vlan                      = try(interface.trunk_native_vlan, null)
    switchport_trunk_native_vlan_variable             = try(interface.trunk_native_vlan_variable, null)
  }]
  static_mac_addresses = try(length(each.value.static_mac_addresses) == 0, true) ? null : [for sma in try(each.value.static_mac_addresses, []) : {
    if_name              = try(sma.interface_name, null)
    if_name_variable     = try(sma.interface_name_variable, null)
    mac_address          = try(sma.mac_address, null) == null ? null : format("%s.%s.%s", substr(replace(sma.mac_address, ":", ""), 0, 4), substr(replace(sma.mac_address, ":", ""), 4, 4), substr(replace(sma.mac_address, ":", ""), 8, 4))
    mac_address_variable = try(sma.mac_address_variable, null)
    optional             = try(sma.optional, null)
    vlan                 = try(sma.vlan, null)
    vlan_variable        = try(sma.vlan_variable, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_vpn_interface_svi_feature_template" "vpn_interface_svi_feature_template" {
  for_each                       = { for t in try(local.edge_feature_templates.svi_interface_templates, {}) : t.name => t }
  name                           = each.value.name
  description                    = each.value.description
  device_types                   = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.svi_interface_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  arp_timeout                    = try(each.value.arp_timeout, null)
  arp_timeout_variable           = try(each.value.arp_timeout_variable, null)
  if_name                        = try(each.value.interface_name, null)
  if_name_variable               = try(each.value.interface_name_variable, null)
  interface_description          = try(each.value.interface_description, null)
  interface_description_variable = try(each.value.interface_description_variable, null)
  ip_directed_broadcast          = try(each.value.ip_directed_broadcast, null)
  ip_directed_broadcast_variable = try(each.value.ip_directed_broadcast_variable, null)
  ip_mtu                         = try(each.value.ip_mtu, null)
  ip_mtu_variable                = try(each.value.ip_mtu_variable, null)
  ipv4_address                   = try(each.value.ipv4_address, null)
  ipv4_address_variable          = try(each.value.ipv4_address_variable, null)
  ipv4_dhcp_helper               = try(each.value.ipv4_dhcp_helpers, null)
  ipv4_dhcp_helper_variable      = try(each.value.ipv4_dhcp_helpers_variable, null)
  ipv6_address                   = try(each.value.ipv6_address, null)
  ipv6_address_variable          = try(each.value.ipv6_address_variable, null)
  mtu                            = try(each.value.mtu, null)
  mtu_variable                   = try(each.value.mtu_variable, null)
  shutdown                       = try(each.value.shutdown, null)
  shutdown_variable              = try(each.value.shutdown_variable, null)
  tcp_mss_adjust                 = try(each.value.tcp_mss, null)
  tcp_mss_adjust_variable        = try(each.value.tcp_mss_variable, null)
  ipv4_access_lists = try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? null : flatten([
    try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_ingress_access_list, null)
      acl_name_variable = try(each.value.ipv4_ingress_access_list_variable, null)
      direction         = "in"
    }],
    try(each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_egress_access_list, null)
      acl_name_variable = try(each.value.ipv4_egress_access_list_variable, null)
      direction         = "out"
    }]
  ])
  ipv6_access_lists = try(each.value.ipv6_ingress_access_list, each.value.ipv6_ingress_access_list_variable, each.value.ipv6_egress_access_list, each.value.ipv6_egress_access_list_variable, null) == null ? null : flatten([
    try(each.value.ipv6_ingress_access_list, each.value.ipv6_ingress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv6_ingress_access_list, null)
      acl_name_variable = try(each.value.ipv6_ingress_access_list_variable, null)
      direction         = "in"
    }],
    try(each.value.ipv6_egress_access_list, each.value.ipv6_egress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv6_egress_access_list, null)
      acl_name_variable = try(each.value.ipv6_egress_access_list_variable, null)
      direction         = "out"
    }]
  ])
  ipv4_secondary_addresses = try(length(each.value.ipv4_secondary_addresses) == 0, true) ? null : [for a in try(each.value.ipv4_secondary_addresses, []) : {
    ipv4_address          = try(a.address, null)
    ipv4_address_variable = try(a.address_variable, null)
  }]
  ipv6_secondary_addresses = try(length(each.value.ipv6_secondary_addresses) == 0, true) ? null : [for a in try(each.value.ipv6_secondary_addresses, []) : {
    ipv6_address          = try(a.address, null)
    ipv6_address_variable = try(a.address_variable, null)
  }]
  ipv4_vrrps = try(length(each.value.ipv4_vrrp_groups) == 0, true) ? null : [for v in try(each.value.ipv4_vrrp_groups, []) : {
    group_id              = try(v.id, null)
    group_id_variable     = try(v.id_variable, null)
    ipv4_address          = try(v.address, null)
    ipv4_address_variable = try(v.address_variable, null)
    ipv4_secondary_addresses = try(length(v.secondary_addresses) == 0, true) ? null : [for sa in try(v.secondary_addresses, []) : {
      ipv4_address          = try(sa.address, null)
      ipv4_address_variable = try(sa.address_variable, null)
    }]
    optional                              = try(v.optional, null)
    priority                              = try(v.priority, null)
    priority_variable                     = try(v.priority_variable, null)
    timer                                 = try(v.timer, null)
    timer_variable                        = try(v.timer_variable, null)
    tloc_preference_change                = try(v.tloc_preference_change, null)
    tloc_preference_change_value          = try(v.tloc_preference_change_value, null)
    tloc_preference_change_value_variable = try(v.tloc_preference_change_value_variable, null)
    track_omp                             = try(v.track_omp, null)
    track_omp_variable                    = try(v.track_omp_variable, null)
    track_prefix_list                     = try(v.track_prefix_list, null)
    track_prefix_list_variable            = try(v.track_prefix_list_variable, null)
    tracking_objects = try(length(v.tracking_objects) == 0, true) ? null : [for t in try(v.tracking_objects, []) : {
      name                     = try(t.id, null)
      name_variable            = try(t.id_variable, null)
      decrement_value          = try(t.decrement_value, null)
      decrement_value_variable = try(t.decrement_value_variable, null)
      track_action             = try(t.action, null)
      track_action_variable    = try(t.action_variable, null)
    }]
  }]
  ipv6_dhcp_helpers = try(length(each.value.ipv6_dhcp_helpers) == 0, true) ? null : [for h in try(each.value.ipv6_dhcp_helpers, []) : {
    address          = try(h.address, null)
    address_variable = try(h.address_variable, null)
    vpn_id           = try(h.vpn_id, null)
    vpn_id_variable  = try(h.vpn_id_variable, null)
  }]
  ipv6_vrrps = try(length(each.value.ipv6_vrrp_groups) == 0, true) ? null : [for v in try(each.value.ipv6_vrrp_groups, []) : {
    group_id          = try(v.id, null)
    group_id_variable = try(v.id_variable, null)
    ipv6_addresses = try(v.link_local_address, v.link_local_address_variable, v.global_prefix, v.global_prefix_variable, null) == null ? null : [{
      link_local_address          = try(v.link_local_address, null)
      link_local_address_variable = try(v.link_local_address_variable, null)
      prefix                      = try(v.global_prefix, null)
      prefix_variable             = try(v.global_prefix_variable, null)
    }]
    ipv6_secondary_addresses = try(length(v.secondary_addresses) == 0, true) ? null : [for sa in try(v.secondary_addresses, []) : {
      prefix          = try(sa.address, null)
      prefix_variable = try(sa.address_variable, null)
    }]
    optional                   = try(v.optional, null)
    priority                   = try(v.priority, null)
    priority_variable          = try(v.priority_variable, null)
    timer                      = try(v.timer, null)
    timer_variable             = try(v.timer_variable, null)
    track_omp                  = try(v.track_omp, null)
    track_omp_variable         = try(v.track_omp_variable, null)
    track_prefix_list          = try(v.track_prefix_list, null)
    track_prefix_list_variable = try(v.track_prefix_list_variable, null)
  }]
  static_arp_entries = try(length(each.value.static_arps) == 0, true) ? null : [for e in try(each.value.static_arps, []) : {
    ipv4_address          = try(e.ip_address, null)
    ipv4_address_variable = try(e.ip_address_variable, null)
    mac_address           = try(e.mac_address, null)
    mac_address_variable  = try(e.mac_address_variable, null)
    optional              = try(e.optional, null)
  }]
  depends_on = [sdwan_localized_policy.localized_policy]
}

resource "sdwan_security_app_hosting_feature_template" "security_app_hosting_feature_template" {
  for_each     = { for t in try(local.edge_feature_templates.secure_app_hosting_templates, {}) : t.name => t }
  name         = each.value.name
  description  = each.value.description
  device_types = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.secure_app_hosting_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  virtual_applications = [{
    nat                       = try(each.value.nat, null)
    nat_variable              = try(each.value.nat_variable, null)
    database_url              = try(each.value.download_url_database_on_device, null)
    database_url_variable     = try(each.value.download_url_database_on_device_variable, null)
    resource_profile          = try(each.value.resource_profile, null)
    resource_profile_variable = try(each.value.resource_profile_variable, null)
    instance_id               = 1
  }]
}

resource "sdwan_cellular_controller_feature_template" "cellular_controller_feature_template" {
  for_each                       = { for t in try(local.edge_feature_templates.cellular_controller_templates, {}) : t.name => t }
  name                           = each.value.name
  description                    = each.value.description
  device_types                   = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.cellular_controller_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  cellular_interface_id          = try(each.value.cellular_interface_id, null)
  cellular_interface_id_variable = try(each.value.cellular_interface_id_variable, null)
  primary_sim_slot               = try(each.value.primary_sim_slot, null)
  primary_sim_slot_variable      = try(each.value.primary_sim_slot_variable, null)
  sim_failover_retries           = try(each.value.sim_failover_retries, null)
  sim_failover_retries_variable  = try(each.value.sim_failover_retries_variable, null)
  sim_failover_timeout           = try(each.value.sim_failover_timeout, null)
  sim_failover_timeout_variable  = try(each.value.sim_failover_timeout_variable, null)
}

resource "sdwan_cellular_cedge_profile_feature_template" "cellular_cedge_profile_feature_template" {
  for_each                          = { for t in try(local.edge_feature_templates.cellular_profile_templates, {}) : t.name => t }
  name                              = each.value.name
  description                       = each.value.description
  device_types                      = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.cellular_profile_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  profile_id                        = try(each.value.profile_id, null)
  profile_id_variable               = try(each.value.profile_id_variable, null)
  access_point_name                 = try(each.value.access_point_name, null)
  access_point_name_variable        = try(each.value.access_point_name_variable, null)
  packet_data_network_type          = try(each.value.packet_data_network_type, null)
  packet_data_network_type_variable = try(each.value.packet_data_network_type_variable, null)
  authentication_type               = try(each.value.authentication_type, null)
  authentication_type_variable      = try(each.value.authentication_type_variable, null)
  profile_username                  = try(each.value.profile_username, null)
  profile_username_variable         = try(each.value.profile_username_variable, null)
  profile_password                  = try(each.value.profile_password, null)
  profile_password_variable         = try(each.value.profile_password_variable, null)
  no_overwrite                      = try(each.value.no_overwrite, null)
  no_overwrite_variable             = try(each.value.no_overwrite_variable, null)
}

resource "sdwan_cisco_vpn_interface_gre_feature_template" "cisco_vpn_interface_gre_feature_template" {
  for_each                         = { for t in try(local.edge_feature_templates.gre_interface_templates, {}) : t.name => t }
  name                             = each.value.name
  description                      = each.value.description
  device_types                     = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.gre_interface_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  interface_name                   = try(each.value.interface_name, null)
  interface_name_variable          = try(each.value.interface_name_variable, null)
  interface_description            = try(each.value.interface_description, null)
  interface_description_variable   = try(each.value.interface_description_variable, null)
  shutdown                         = try(each.value.shutdown, null)
  shutdown_variable                = try(each.value.shutdown_variable, null)
  tunnel_source_interface          = try(each.value.tunnel_source_interface, null)
  tunnel_source_interface_variable = try(each.value.tunnel_source_interface_variable, null)
  tunnel_source                    = try(each.value.tunnel_source_ip, null)
  tunnel_source_variable           = try(each.value.tunnel_source_ip_variable, null)
  tunnel_destination               = try(each.value.tunnel_destination, null)
  tunnel_destination_variable      = try(each.value.tunnel_destination_variable, null)
  ip_address                       = try(each.value.ip_address, null)
  ip_address_variable              = try(each.value.ip_address_variable, null)
  ip_mtu                           = try(each.value.ip_mtu, null)
  ip_mtu_variable                  = try(each.value.ip_mtu_variable, null)
  tcp_mss_adjust                   = try(each.value.tcp_mss, null)
  tcp_mss_adjust_variable          = try(each.value.tcp_mss_variable, null)
  clear_dont_fragment              = try(each.value.clear_dont_fragment, null)
  clear_dont_fragment_variable     = try(each.value.clear_dont_fragment_variable, null)
  rewrite_rule                     = try(each.value.rewrite_rule, null)
  rewrite_rule_variable            = try(each.value.rewrite_rule_variable, null)
  tracker                          = try([each.value.tracker], null)
  tracker_variable                 = try(each.value.tracker_variable, null)
  application                      = try(each.value.application, null)
  application_variable             = try(each.value.application_variable, null)
  access_lists = try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? null : flatten([
    try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_ingress_access_list, null)
      acl_name_variable = try(each.value.ipv4_ingress_access_list_variable, null)
      direction         = "in"
    }],
    try(each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_egress_access_list, null)
      acl_name_variable = try(each.value.ipv4_egress_access_list_variable, null)
      direction         = "out"
    }]
  ])
}

resource "sdwan_vpn_interface_cellular_feature_template" "vpn_interface_cellular_feature_template" {
  for_each                                                = { for t in try(local.edge_feature_templates.cellular_interface_templates, {}) : t.name => t }
  name                                                    = each.value.name
  description                                             = each.value.description
  device_types                                            = [for d in try(each.value.device_types, local.defaults.sdwan.edge_feature_templates.cellular_interface_templates.device_types) : try(local.device_type_map[d], "vedge-${d}")]
  cellular_interface_name                                 = try(each.value.interface_name, null)
  cellular_interface_name_variable                        = try(each.value.interface_name_variable, null)
  interface_description                                   = try(each.value.interface_description, null)
  interface_description_variable                          = try(each.value.interface_description_variable, null)
  shutdown                                                = try(each.value.shutdown, null)
  shutdown_variable                                       = try(each.value.shutdown_variable, null)
  ipv4_dhcp_helper                                        = try(each.value.dhcp_helpers, null)
  ipv4_dhcp_helper_variable                               = try(each.value.dhcp_helpers_variable, null)
  bandwidth_downstream                                    = try(each.value.bandwidth_downstream, null)
  bandwidth_downstream_variable                           = try(each.value.bandwidth_downstream_variable, null)
  bandwidth_upstream                                      = try(each.value.bandwidth_upstream, null)
  bandwidth_upstream_variable                             = try(each.value.bandwidth_upstream_variable, null)
  ip_mtu                                                  = try(each.value.ip_mtu, null)
  ip_mtu_variable                                         = try(each.value.ip_mtu_variable, null)
  tunnel_interface_allow_all                              = try(each.value.tunnel_interface.allow_service_all, null)
  tunnel_interface_allow_all_variable                     = try(each.value.tunnel_interface.allow_service_all_variable, null)
  tunnel_interface_allow_bgp                              = try(each.value.tunnel_interface.allow_service_bgp, null)
  tunnel_interface_allow_bgp_variable                     = try(each.value.tunnel_interface.allow_service_bgp_variable, null)
  tunnel_interface_allow_dhcp                             = try(each.value.tunnel_interface.allow_service_dhcp, null)
  tunnel_interface_allow_dhcp_variable                    = try(each.value.tunnel_interface.allow_service_dhcp_variable, null)
  tunnel_interface_allow_dns                              = try(each.value.tunnel_interface.allow_service_dns, null)
  tunnel_interface_allow_dns_variable                     = try(each.value.tunnel_interface.allow_service_dns_variable, null)
  tunnel_interface_allow_https                            = try(each.value.tunnel_interface.allow_service_https, null)
  tunnel_interface_allow_https_variable                   = try(each.value.tunnel_interface.allow_service_https_variable, null)
  tunnel_interface_allow_icmp                             = try(each.value.tunnel_interface.allow_service_icmp, null)
  tunnel_interface_allow_icmp_variable                    = try(each.value.tunnel_interface.allow_service_icmp_variable, null)
  tunnel_interface_allow_netconf                          = try(each.value.tunnel_interface.allow_service_netconf, null)
  tunnel_interface_allow_netconf_variable                 = try(each.value.tunnel_interface.allow_service_netconf_variable, null)
  tunnel_interface_allow_ntp                              = try(each.value.tunnel_interface.allow_service_ntp, null)
  tunnel_interface_allow_ntp_variable                     = try(each.value.tunnel_interface.allow_service_ntp_variable, null)
  tunnel_interface_allow_ospf                             = try(each.value.tunnel_interface.allow_service_ospf, null)
  tunnel_interface_allow_ospf_variable                    = try(each.value.tunnel_interface.allow_service_ospf_variable, null)
  tunnel_interface_allow_snmp                             = try(each.value.tunnel_interface.allow_service_snmp, null)
  tunnel_interface_allow_snmp_variable                    = try(each.value.tunnel_interface.allow_service_snmp_variable, null)
  tunnel_interface_allow_ssh                              = try(each.value.tunnel_interface.allow_service_ssh, null)
  tunnel_interface_allow_ssh_variable                     = try(each.value.tunnel_interface.allow_service_ssh_variable, null)
  tunnel_interface_allow_stun                             = try(each.value.tunnel_interface.allow_service_stun, null)
  tunnel_interface_allow_stun_variable                    = try(each.value.tunnel_interface.allow_service_stun_variable, null)
  tunnel_interface_bind_loopback_tunnel                   = try(each.value.tunnel_interface.bind_loopback_tunnel, null)
  tunnel_interface_bind_loopback_tunnel_variable          = try(each.value.tunnel_interface.bind_loopback_tunnel_variable, null)
  tunnel_interface_border                                 = try(each.value.tunnel_interface.border, null)
  tunnel_interface_border_variable                        = try(each.value.tunnel_interface.border_variable, null)
  tunnel_interface_carrier                                = try(each.value.tunnel_interface.carrier, null)
  tunnel_interface_carrier_variable                       = try(each.value.tunnel_interface.carrier_variable, null)
  tunnel_interface_clear_dont_fragment                    = try(each.value.tunnel_interface.clear_dont_fragment, null)
  tunnel_interface_clear_dont_fragment_variable           = try(each.value.tunnel_interface.clear_dont_fragment_variable, null)
  tunnel_interface_color                                  = try(each.value.tunnel_interface.color, null)
  tunnel_interface_color_variable                         = try(each.value.tunnel_interface.color_variable, null)
  tunnel_interface_color_restrict                         = try(each.value.tunnel_interface.restrict, null)
  tunnel_interface_color_restrict_variable                = try(each.value.tunnel_interface.restrict_variable, null)
  core_region                                             = try(each.value.tunnel_interface.core_region, null)
  core_region_variable                                    = try(each.value.tunnel_interface.core_region_variable, null)
  enable_core_region                                      = try(each.value.tunnel_interface.enable_core_region, null)
  enable_core_region_variable                             = try(each.value.tunnel_interface.enable_core_region_variable, null)
  tunnel_interface_exclude_controller_group_list          = try(each.value.tunnel_interface.exclude_controller_groups, null)
  tunnel_interface_exclude_controller_group_list_variable = try(each.value.tunnel_interface.exclude_controller_groups_variable, null)
  tunnel_interface_encapsulations = try(each.value.tunnel_interface.gre_encapsulation, each.value.tunnel_interface.ipsec_encapsulation, null) == null ? null : flatten([
    try(each.value.tunnel_interface.gre_encapsulation, null) == null ? [] : [{
      encapsulation       = "gre"
      preference          = try(each.value.tunnel_interface.gre_preference, null)
      preference_variable = try(each.value.tunnel_interface.gre_preference_variable, null)
      weight              = try(each.value.tunnel_interface.gre_weight, null)
      weight_variable     = try(each.value.tunnel_interface.gre_weight_variable, null)
    }],
    try(each.value.tunnel_interface.ipsec_encapsulation, null) == null ? [] : [{
      encapsulation       = "ipsec"
      preference          = try(each.value.tunnel_interface.ipsec_preference, null)
      preference_variable = try(each.value.tunnel_interface.ipsec_preference_variable, null)
      weight              = try(each.value.tunnel_interface.ipsec_weight, null)
      weight_variable     = try(each.value.tunnel_interface.ipsec_weight_variable, null)
    }]
  ])
  tunnel_interface_groups                                 = try([each.value.tunnel_interface.group], null)
  tunnel_interface_groups_variable                        = try(each.value.tunnel_interface.group_variable, null)
  tunnel_interface_hello_interval                         = try(each.value.tunnel_interface.hello_interval, null)
  tunnel_interface_hello_interval_variable                = try(each.value.tunnel_interface.hello_interval_variable, null)
  tunnel_interface_hello_tolerance                        = try(each.value.tunnel_interface.hello_tolerance, null)
  tunnel_interface_hello_tolerance_variable               = try(each.value.tunnel_interface.hello_tolerance_variable, null)
  tunnel_interface_last_resort_circuit                    = try(each.value.tunnel_interface.last_resort_circuit, null)
  tunnel_interface_last_resort_circuit_variable           = try(each.value.tunnel_interface.last_resort_circuit_variable, null)
  tunnel_interface_low_bandwidth_link                     = try(each.value.tunnel_interface.low_bandwidth_link, null)
  tunnel_interface_low_bandwidth_link_variable            = try(each.value.tunnel_interface.low_bandwidth_link_variable, null)
  tunnel_interface_max_control_connections                = try(each.value.tunnel_interface.max_control_connections, null)
  tunnel_interface_max_control_connections_variable       = try(each.value.tunnel_interface.max_control_connections_variable, null)
  tunnel_interface_nat_refresh_interval                   = try(each.value.tunnel_interface.nat_refresh_interval, null)
  tunnel_interface_nat_refresh_interval_variable          = try(each.value.tunnel_interface.nat_refresh_interval_variable, null)
  tunnel_interface_network_broadcast                      = try(each.value.tunnel_interface.network_broadcast, null)
  tunnel_interface_network_broadcast_variable             = try(each.value.tunnel_interface.network_broadcast_variable, null)
  tunnel_interface_port_hop                               = try(each.value.tunnel_interface.port_hop, null)
  tunnel_interface_port_hop_variable                      = try(each.value.tunnel_interface.port_hop_variable, null)
  tunnel_interface_tunnel_tcp_mss                         = try(each.value.tunnel_interface.tcp_mss, null)
  tunnel_interface_tunnel_tcp_mss_variable                = try(each.value.tunnel_interface.tcp_mss_variable, null)
  tunnel_qos_mode                                         = try(each.value.tunnel_interface.per_tunnel_qos_mode, null)
  tunnel_qos_mode_variable                                = try(each.value.tunnel_interface.per_tunnel_qos_mode_variable, null)
  secondary_region                                        = try(each.value.tunnel_interface.secondary_region, null)
  secondary_region_variable                               = try(each.value.tunnel_interface.secondary_region_variable, null)
  tunnel_interface_vbond_as_stun_server                   = try(each.value.tunnel_interface.vbond_as_stun_server, null)
  tunnel_interface_vbond_as_stun_server_variable          = try(each.value.tunnel_interface.vbond_as_stun_server_variable, null)
  tunnel_interface_vmanage_connection_preference          = try(each.value.tunnel_interface.vmanage_connection_preference, null)
  tunnel_interface_vmanage_connection_preference_variable = try(each.value.tunnel_interface.vmanage_connection_preference_variable, null)
  nat                                                     = try(each.value.nat, null)
  nat_refresh_mode                                        = try(each.value.nat_refresh_mode, null)
  nat_refresh_mode_variable                               = try(each.value.nat_refresh_mode_variable, null)
  nat_tcp_timeout                                         = try(each.value.nat_tcp_timeout, null)
  nat_tcp_timeout_variable                                = try(each.value.nat_tcp_timeout_variable, null)
  nat_udp_timeout                                         = try(each.value.nat_udp_timeout, null)
  nat_udp_timeout_variable                                = try(each.value.nat_udp_timeout_variable, null)
  nat_block_icmp_error                                    = try(each.value.nat_block_icmp, null)
  nat_block_icmp_error_variable                           = try(each.value.nat_block_icmp_variable, null)
  nat_response_to_ping                                    = try(each.value.nat_respond_to_ping, null)
  nat_response_to_ping_variable                           = try(each.value.nat_respond_to_ping_variable, null)
  nat_port_forwards = try(each.value.nat_port_forwarding_rules, null) == null ? null : [for pfr in each.value.nat_port_forwarding_rules : {
    port_start_range            = try(pfr.port_range_start, null)
    port_end_range              = try(pfr.port_range_end, null)
    protocol                    = try(pfr.protocol, null)
    private_vpn                 = try(pfr.vpn, null)
    private_vpn_variable        = try(pfr.vpn_variable, null)
    private_ip_address          = try(pfr.private_ip, null)
    private_ip_address_variable = try(pfr.private_ip_variable, null)
  }]
  qos_adaptive_period                        = try(each.value.adaptive_qos_period, null)
  qos_adaptive_period_variable               = try(each.value.adaptive_qos_period_variable, null)
  qos_adaptive_bandwidth_downstream          = try(each.value.adaptive_qos_shaping_rate_downstream.default, null)
  qos_adaptive_bandwidth_downstream_variable = try(each.value.adaptive_qos_shaping_rate_downstream.default_variable, null)
  qos_adaptive_bandwidth_upstream            = try(each.value.adaptive_qos_shaping_rate_upstream.default, null)
  qos_adaptive_bandwidth_upstream_variable   = try(each.value.adaptive_qos_shaping_rate_upstream.default_variable, null)
  qos_adaptive_max_downstream                = try(each.value.adaptive_qos_shaping_rate_downstream.maximum, null)
  qos_adaptive_max_downstream_variable       = try(each.value.adaptive_qos_shaping_rate_downstream.maximum_variable, null)
  qos_adaptive_max_upstream                  = try(each.value.adaptive_qos_shaping_rate_upstream.maximum, null)
  qos_adaptive_max_upstream_variable         = try(each.value.adaptive_qos_shaping_rate_upstream.maximum_variable, null)
  qos_adaptive_min_downstream                = try(each.value.adaptive_qos_shaping_rate_downstream.minimum, null)
  qos_adaptive_min_downstream_variable       = try(each.value.adaptive_qos_shaping_rate_downstream.minimum_variable, null)
  qos_adaptive_min_upstream                  = try(each.value.adaptive_qos_shaping_rate_upstream.minimum, null)
  qos_adaptive_min_upstream_variable         = try(each.value.adaptive_qos_shaping_rate_upstream.minimum_variable, null)
  shaping_rate                               = try(each.value.shaping_rate, null)
  shaping_rate_variable                      = try(each.value.shaping_rate_variable, null)
  qos_map                                    = try(each.value.qos_map, null)
  qos_map_variable                           = try(each.value.qos_map_variable, null)
  qos_map_vpn                                = try(each.value.vpn_qos_map, null)
  qos_map_vpn_variable                       = try(each.value.vpn_qos_map_variable, null)
  write_rule                                 = try(each.value.rewrite_rule, null)
  write_rule_variable                        = try(each.value.rewrite_rule_variable, null)
  ipv4_access_lists = try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? null : flatten([
    try(each.value.ipv4_ingress_access_list, each.value.ipv4_ingress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_ingress_access_list, null)
      acl_name_variable = try(each.value.ipv4_ingress_access_list_variable, null)
      direction         = "in"
    }],
    try(each.value.ipv4_egress_access_list, each.value.ipv4_egress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv4_egress_access_list, null)
      acl_name_variable = try(each.value.ipv4_egress_access_list_variable, null)
      direction         = "out"
    }]
  ])
  ipv6_access_lists = try(each.value.ipv6_ingress_access_list, each.value.ipv6_ingress_access_list_variable, each.value.ipv6_egress_access_list, each.value.ipv6_egress_access_list_variable, null) == null ? null : flatten([
    try(each.value.ipv6_ingress_access_list, each.value.ipv6_ingress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv6_ingress_access_list, null)
      acl_name_variable = try(each.value.ipv6_ingress_access_list_variable, null)
      direction         = "in"
    }],
    try(each.value.ipv6_egress_access_list, each.value.ipv6_egress_access_list_variable, null) == null ? [] : [{
      acl_name          = try(each.value.ipv6_egress_access_list, null)
      acl_name_variable = try(each.value.ipv6_egress_access_list_variable, null)
      direction         = "out"
    }]
  ])
  policers = try(each.value.ingress_policer_name, each.value.ingress_policer_name_variable, each.value.egress_policer_name, each.value.egress_policer_name_variable, null) == null ? null : flatten([
    try(each.value.ingress_policer_name, each.value.ingress_policer_name_variable, null) == null ? [] : [{
      policer_name = try(each.value.ingress_policer_name, null)
      direction    = "in"
    }],
    try(each.value.egress_policer_name, each.value.egress_policer_name_variable, null) == null ? [] : [{
      policer_name = try(each.value.egress_policer_name, null)
      direction    = "out"
    }]
  ])
  static_arps = try(length(each.value.static_arps) == 0, true) ? null : [for arp in each.value.static_arps : {
    ip_address          = try(arp.ip_address, null)
    ip_address_variable = try(arp.ip_address_variable, null)
    mac                 = try(arp.mac_address, null)
    mac_variable        = try(arp.mac_address_variable, null)
    optional            = try(arp.optional, null)
  }]
  pmtu_discovery                   = try(each.value.path_mtu_discovery, null)
  pmtu_discovery_variable          = try(each.value.path_mtu_discovery_variable, null)
  tcp_mss                          = try(each.value.tcp_mss, null)
  tcp_mss_variable                 = try(each.value.tcp_mss_variable, null)
  clear_dont_fragment_bit          = try(each.value.clear_dont_fragment, null)
  clear_dont_fragment_bit_variable = try(each.value.clear_dont_fragment_variable, null)
  static_ingress_qos               = try(each.value.static_ingress_qos, null)
  static_ingress_qos_variable      = try(each.value.static_ingress_qos_variable, null)
  autonegotiate                    = try(each.value.autonegotiate, null)
  autonegotiate_variable           = try(each.value.autonegotiate_variable, null)
  tloc_extension                   = try(each.value.tloc_extension, null)
  tloc_extension_variable          = try(each.value.tloc_extension_variable, null)
  tracker                          = try([each.value.tracker], null)
  tracker_variable                 = try(each.value.tracker_variable, null)
  ip_directed_broadcast            = try(each.value.ip_directed_broadcast, null)
  ip_directed_broadcast_variable   = try(each.value.ip_directed_broadcast_variable, null)
}
