# GENERAL

variable "name_prefix" {
  description = <<-EOF
  A prefix that will be added to all created resources.
  There is no default delimiter applied between the prefix and the resource name.
  Please include the delimiter in the actual prefix.

  Example:
  ```
  name_prefix = "test-"
  ```

  **Note!** \
  This prefix is not applied to existing resources. If you plan to reuse i.e. a VNET please specify it's full name,
  even if it is also prefixed with the same value as the one in this property.
  EOF
  default     = ""
  type        = string
}

variable "create_resource_group" {
  description = <<-EOF
  When set to `true` it will cause a Resource Group creation.
  Name of the newly specified RG is controlled by `resource_group_name`.

  When set to `false` the `resource_group_name` parameter is used to specify a name of an existing Resource Group.
  EOF
  default     = true
  type        = bool
}

variable "resource_group_name" {
  description = "Name of the Resource Group."
  type        = string
}

variable "region" {
  description = "The Azure region to use."
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to the created resources."
  default     = {}
  type        = map(string)
}

# NETWORK

variable "vnets" {
  description = <<-EOF
  A map defining VNETs.

  For detailed documentation on each property refer to [module documentation](../../modules/vnet/README.md)

  - `create_virtual_network`                   - (`bool`, optional, defaults to `true`) when set to `true` will create a VNET,
                                                 `false` will source an existing VNET.
  - `name`                                     - (`string`, required) a name of a VNET. In case `create_virtual_network = false`
                                                 this should be a full resource name, including prefixes.
  - `resource_group_name`                      - (`string`, optional, defaults to current RG) a name of an existing Resource
                                                 Group in which the VNET will reside or is sourced from.
  - `address_space`                            - (`list`, required when `create_virtual_network = false`) a list of CIDRs for a
                                                 newly created VNET.
  - `dns_servers`                              - (`list`, optional, defaults to module defaults) a list of IP addresses of custom
                                                 DNS servers (by default Azure DNS is used).
  - `vnet_encryption`                          - (`string`, optional, defaults to module default) enables Azure Virtual Network
                                                 Encryption when set, only possible value at the moment is `AllowUnencrypted`. 
                                                 When set to `null`, the feature is disabled.
  - `ddos_protection_plan_name`                - (`string`, optional, defaults to `null`) name of an existing Azure Network DDOS
                                                 Protection Plan to be associated with the VNET.
  - `ddos_protection_plan_resource_group_name` - (`string`, optional, defaults to `null`) name of the Resource Group containing
                                                 an existing Azure Network DDOS Protection Plan to be associated with the VNET.
  - `network_security_groups`                  - (`map`, optional) map of Network Security Groups to create, for details see
                                                 [VNET module documentation](../../modules/vnet/README.md#network_security_groups).
  - `route_tables`                             - (`map`, optional) map of Route Tables to create, for details see
                                                 [VNET module documentation](../../modules/vnet/README.md#route_tables).
  - `subnets`                                  - (`map`, optional) map of Subnets to create or source, for details see
                                                 [VNET module documentation](../../modules/vnet/README.md#subnets).
  EOF
  type = map(object({
    create_virtual_network                   = optional(bool, true)
    name                                     = string
    resource_group_name                      = optional(string)
    address_space                            = optional(list(string))
    dns_servers                              = optional(list(string))
    vnet_encryption                          = optional(string)
    ddos_protection_plan_name                = optional(string)
    ddos_protection_plan_resource_group_name = optional(string)
    network_security_groups = optional(map(object({
      name = string
      rules = optional(map(object({
        name                         = string
        priority                     = number
        direction                    = string
        access                       = string
        protocol                     = string
        source_port_range            = optional(string)
        source_port_ranges           = optional(list(string))
        destination_port_range       = optional(string)
        destination_port_ranges      = optional(list(string))
        source_address_prefix        = optional(string)
        source_address_prefixes      = optional(list(string))
        destination_address_prefix   = optional(string)
        destination_address_prefixes = optional(list(string))
      })), {})
    })), {})
    route_tables = optional(map(object({
      name                          = string
      bgp_route_propagation_enabled = optional(bool)
      routes = map(object({
        name                = string
        address_prefix      = string
        next_hop_type       = string
        next_hop_ip_address = optional(string)
      }))
    })), {})
    subnets = optional(map(object({
      create                          = optional(bool, true)
      name                            = string
      address_prefixes                = optional(list(string), [])
      network_security_group_key      = optional(string)
      route_table_key                 = optional(string)
      enable_storage_service_endpoint = optional(bool)
      enable_cloudngfw_delegation     = optional(bool)
    })), {})
  }))
}

variable "vnet_peerings" {
  description = <<-EOF
  A map defining VNET peerings.

  Following properties are supported:
  - `local_vnet_name`            - (`string`, required) name of the local VNET.
  - `local_resource_group_name`  - (`string`, optional) name of the resource group, in which local VNET exists.
  - `remote_vnet_name`           - (`string`, required) name of the remote VNET.
  - `remote_resource_group_name` - (`string`, optional) name of the resource group, in which remote VNET exists.
  EOF
  default     = {}
  type = map(object({
    local_vnet_name            = string
    local_resource_group_name  = optional(string)
    remote_vnet_name           = string
    remote_resource_group_name = optional(string)
  }))
}

variable "public_ips" {
  description = <<-EOF
  A map defining Public IP Addresses and Prefixes.

  Following properties are available:

  - `public_ip_addresses` - (`map`, optional) map of objects describing Public IP Addresses, please refer to
                            [module documentation](../../modules/public_ip/README.md#public_ip_addresses)
                            for available properties.
  - `public_ip_prefixes`  - (`map`, optional) map of objects describing Public IP Prefixes, please refer to
                            [module documentation](../../modules/public_ip/README.md#public_ip_prefixes)
                            for available properties.
  EOF
  default     = {}
  type = object({
    public_ip_addresses = optional(map(object({
      create                     = bool
      name                       = string
      resource_group_name        = optional(string)
      zones                      = optional(list(string))
      domain_name_label          = optional(string)
      idle_timeout_in_minutes    = optional(number)
      prefix_name                = optional(string)
      prefix_resource_group_name = optional(string)
    })), {})
    public_ip_prefixes = optional(map(object({
      create              = bool
      name                = string
      resource_group_name = optional(string)
      zones               = optional(list(string))
      length              = optional(number)
    })), {})
  })
}

variable "natgws" {
  description = <<-EOF
  A map defining NAT Gateways.

  Please note that a NAT Gateway is a zonal resource, this means it's always placed in a zone (even when you do not specify one
  explicitly). Please refer to Microsoft documentation for notes on NAT Gateway's zonal resiliency.
  For detailed documentation on each property refer to [module documentation](../../modules/natgw/README.md).

  Following properties are supported:
  - `name`                - (`string`, required) a name of a NAT Gateway. In case `create_natgw = false` this should be a full
                            resource name, including prefixes.
  - `vnet_key`            - (`string`, required) a name (key value) of a VNET defined in `var.vnets` that hosts a subnet this
                            NAT Gateway will be assigned to.
  - `subnet_keys`         - (`list(string)`, required) a list of subnets (key values) the NAT Gateway will be assigned to,
                            defined in `var.vnets` for a VNET described by `vnet_name`.
  - `create_natgw`        - (`bool`, optional, defaults to `true`) create (`true`) or source an existing NAT Gateway (`false`),
                            created or sourced: the NAT Gateway will be assigned to a subnet created by the `vnet` module.
  - `resource_group_name` - (`string`, optional) name of a Resource Group hosting the NAT Gateway (newly created or the existing
                            one).
  - `zone`                - (`string`, optional) an Availability Zone in which the NAT Gateway will be placed, when skipped
                            Azure will pick a zone.
  - `idle_timeout`        - (`number`, optional, defults to 4) connection IDLE timeout in minutes, for newly created resources.
  - `public_ip`           - (`object`, optional) an object defining a public IP resource attached to the NAT Gateway.
  - `public_ip_prefix`    - (`object`, optional) an object defining a public IP prefix resource attached to the NAT Gatway.

  Example:
  ```
  natgws = {
    "natgw" = {
      name        = "natgw"
      vnet_key    = "transit-vnet"
      subnet_keys = ["management"]
      public_ip = {
        create = true
        name   = "natgw-pip"
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name                = string
    vnet_key            = string
    subnet_keys         = list(string)
    create_natgw        = optional(bool, true)
    resource_group_name = optional(string)
    zone                = optional(string)
    idle_timeout        = optional(number, 4)
    public_ip = optional(object({
      create              = bool
      name                = optional(string)
      resource_group_name = optional(string)
      key                 = optional(string)
    }))
    public_ip_prefix = optional(object({
      create              = bool
      name                = optional(string)
      resource_group_name = optional(string)
      length              = optional(number)
      key                 = optional(string)
    }))
  }))
}

# LOAD BALANCING

variable "load_balancers" {
  description = <<-EOF
  A map containing configuration for all (both private and public) Load Balancers.

  This is a brief description of available properties. For a detailed one please refer to
  [module documentation](../../modules/loadbalancer/README.md).

  Following properties are available:

  - `name`                    - (`string`, required) a name of the Load Balancer.
  - `vnet_key`                - (`string`, optional, defaults to `null`) a key pointing to a VNET definition in the `var.vnets`
                                map that stores the Subnet described by `subnet_key`.
  - `zones`                   - (`list`, optional, defaults to module default) a list of zones for Load Balancer's frontend IP
                                configurations.
  - `backend_name`            - (`string`, optional, defaults to "vmseries_backend") a name of the backend pool to create.
  - `health_probes`           - (`map`, optional, defaults to `null`) a map defining health probes that will be used by load
                                balancing rules, please refer to
                                [module documentation](../../modules/loadbalancer/README.md#health_probes) for more specific use
                                cases and available properties.
  - `nsg_auto_rules_settings` - (`map`, optional, defaults to `null`) a map defining a location of an existing NSG rule that will
                                be populated with `Allow` rules for each load balancing rule (`in_rules`), please refer to
                                [module documentation](../../modules/loadbalancer/README.md#nsg_auto_rules_settings) for
                                available properties.

    Please note that in this example two additional properties are available:

    - `nsg_vnet_key` - (`string`, optional, mutually exclusive with `nsg_name`) a key pointing to a VNET definition in the
                       `var.vnets` map that stores the NSG described by `nsg_key`.
    - `nsg_key`      - (`string`, optional, mutually exclusive with `nsg_name`) a key pointing to an NSG definition in the
                       `var.vnets` map.

  - `frontend_ips`            - (`map`, optional, defaults to `{}`) a map containing frontend IP configuration with respective
                                `in_rules` and `out_rules`, please refer to
                                [module documentation](../../modules/loadbalancer/README.md#frontend_ips) for available
                                properties.

    **Note!** \
    In this example the `subnet_id` is not available directly, another property has been introduced instead:

    - `subnet_key` - (`string`, optional, defaults to `null`) a key pointing to a Subnet definition in the `var.vnets` map.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name         = string
    vnet_key     = optional(string)
    zones        = optional(list(string))
    backend_name = optional(string, "vmseries_backend")
    health_probes = optional(map(object({
      name                = string
      protocol            = string
      port                = optional(number)
      probe_threshold     = optional(number)
      interval_in_seconds = optional(number)
      request_path        = optional(string)
    })))
    nsg_auto_rules_settings = optional(object({
      nsg_name                = optional(string)
      nsg_vnet_key            = optional(string)
      nsg_key                 = optional(string)
      nsg_resource_group_name = optional(string)
      source_ips              = list(string)
      base_priority           = optional(number)
    }))
    frontend_ips = optional(map(object({
      name                          = string
      subnet_key                    = optional(string)
      create_public_ip              = optional(bool, false)
      public_ip_name                = optional(string)
      public_ip_resource_group_name = optional(string)
      public_ip_key                 = optional(string)
      public_ip_prefix_key          = optional(string)
      private_ip_address            = optional(string)
      gwlb_key                      = optional(string)
      in_rules = optional(map(object({
        name                = string
        protocol            = string
        port                = number
        backend_port        = optional(number)
        health_probe_key    = optional(string)
        floating_ip         = optional(bool)
        session_persistence = optional(string)
        nsg_priority        = optional(number)
      })), {})
      out_rules = optional(map(object({
        name                     = string
        protocol                 = string
        allocated_outbound_ports = optional(number)
        enable_tcp_reset         = optional(bool)
        idle_timeout_in_minutes  = optional(number)
      })), {})
    })), {})
  }))
}

variable "appgws" {
  description = <<-EOF
  A map defining all Application Gateways in the current deployment.

  For detailed documentation on how to configure this resource, for available properties, especially for the defaults,
  refer to [module documentation](../../modules/appgw/README.md).

  **Note!** \
  The `rules` property is meant to bind together `backend_setting`, `redirect` or `url_path_map` (all 3 are mutually exclusive).
  It represents the Rules section of an Application Gateway in Azure Portal.

  Below you can find a brief list of most important properties:

  - `name`             - (`string`, required) the name of the Application Gateway, will be prefixed with `var.name_prefix`.
  - `vnet_key`         - (`string`, required) a key pointing to a VNET definition in the `var.vnets` map that stores the Subnet
                         described by `subnet_key`.
  - `subnet_key`       - (`string`, required) a key pointing to a Subnet definition in the `var.vnets` map, this has to be an
                         Application Gateway V2 dedicated subnet.
  - `zones`            - (`list`, optional, defaults to module default) parameter controlling if this is a zonal, or a non-zonal
                         deployment.
  - `public_ip`        - (`map`, required) defines a Public IP resource used by the Application Gateway instance, a newly created
                         Public IP will have it's name prefixes with `var.name_prefix`.
  - `listeners`        - (`map`, required) defines Application Gateway's Listeners, see
                         [module's documentation](../../modules/appgw/README.md#listeners) for details.
  - `backend_pool`     - (`map`, optional, defaults to module default) backend pool definition, when skipped an empty backend
                         will be created.
  - `backend_settings` - (`map`, optional, mutually exclusive with `redirects` and `url_path_maps`) defines HTTP backend
                         settings, see [module's documentation](../../modules/appgw/README.md#backend_settings) for details.
  - `probes`           - (`map`, optional, defaults to module default) defines backend probes used check health of backends, see
                         [module's documentation](../../modules/appgw/README.md#probes) for details.
  - `rewrites`         - (`map`, optional, defaults to module default) defines rewrite rules, see
                         [module's documentation](../../modules/appgw/README.md#rewrites) for details.
  - `redirects`        - (`map`, optional, mutually exclusive with `backend_settings` and `url_path_maps`) static redirects
                         definition, see [module's documentation](../../modules/appgw/README.md#redirects) for details.
  - `url_path_maps`    - (`map`, optional, mutually exclusive with `backend_settings` and `redirects`) URL path maps definition,
                         see [module's documentation](../../modules/appgw/README.md#url_path_maps) for details.
  - `rules`            - (`map`, required) Application Gateway Rules definition, bind together a `listener` with either
                         `backend_setting`, `redirect` or `url_path_map`, see
                         [module's documentation](../../modules/appgw/README.md#rules) for details.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name       = string
    vnet_key   = string
    subnet_key = string
    zones      = optional(list(string))
    public_ip = object({
      create              = optional(bool, true)
      name                = optional(string)
      resource_group_name = optional(string)
      key                 = optional(string)
    })
    domain_name_label = optional(string)
    capacity = optional(object({
      static = optional(number)
      autoscale = optional(object({
        min = number
        max = number
      }))
    }))
    enable_http2 = optional(bool)
    waf = optional(object({
      prevention_mode  = bool
      rule_set_type    = optional(string)
      rule_set_version = optional(string)
    }))
    managed_identities = optional(list(string))
    global_ssl_policy = optional(object({
      type                 = optional(string)
      name                 = optional(string)
      min_protocol_version = optional(string)
      cipher_suites        = optional(list(string))
    }))
    ssl_profiles = optional(map(object({
      name                            = string
      ssl_policy_name                 = optional(string)
      ssl_policy_min_protocol_version = optional(string)
      ssl_policy_cipher_suites        = optional(list(string))
    })))
    frontend_ip_configuration_name = optional(string, "public_ipconfig")
    listeners = map(object({
      name                     = string
      port                     = number
      protocol                 = optional(string)
      host_names               = optional(list(string))
      ssl_profile_name         = optional(string)
      ssl_certificate_path     = optional(string)
      ssl_certificate_pass     = optional(string)
      ssl_certificate_vault_id = optional(string)
      custom_error_pages       = optional(map(string))
    }))
    backend_pool = optional(object({
      name         = optional(string)
      vmseries_ips = optional(list(string))
    }))
    backend_settings = optional(map(object({
      name                      = string
      port                      = number
      protocol                  = string
      path                      = optional(string)
      hostname_from_backend     = optional(string)
      hostname                  = optional(string)
      timeout                   = optional(number)
      use_cookie_based_affinity = optional(bool)
      affinity_cookie_name      = optional(string)
      probe                     = optional(string)
      root_certs = optional(map(object({
        name = string
        path = string
      })))
    })))
    probes = optional(map(object({
      name       = string
      path       = string
      host       = optional(string)
      port       = optional(number)
      protocol   = optional(string)
      interval   = optional(number)
      timeout    = optional(number)
      threshold  = optional(number)
      match_code = optional(list(number))
      match_body = optional(string)
    })))
    rewrites = optional(map(object({
      name = optional(string)
      rules = optional(map(object({
        name     = string
        sequence = number
        conditions = optional(map(object({
          pattern     = string
          ignore_case = optional(bool)
          negate      = optional(bool)
        })))
        request_headers  = optional(map(string))
        response_headers = optional(map(string))
      })))
    })))
    redirects = optional(map(object({
      name                 = string
      type                 = string
      target_listener_key  = optional(string)
      target_url           = optional(string)
      include_path         = optional(bool)
      include_query_string = optional(bool)
    })))
    url_path_maps = optional(map(object({
      name        = string
      backend_key = string
      path_rules = optional(map(object({
        paths        = list(string)
        backend_key  = optional(string)
        redirect_key = optional(string)
      })))
    })))
    rules = map(object({
      name             = string
      priority         = number
      backend_key      = optional(string)
      listener_key     = string
      rewrite_key      = optional(string)
      url_path_map_key = optional(string)
      redirect_key     = optional(string)
    }))
  }))
}

# VM-SERIES

variable "availability_sets" {
  description = <<-EOF
  A map defining availability sets. Can be used to provide infrastructure high availability when zones cannot be used.

  Following properties are supported:

  - `name`                - (`string`, required) name of the Application Insights.
  - `update_domain_count` - (`number`, optional, defaults to Azure default) specifies the number of update domains that are used.
  - `fault_domain_count`  - (`number`, optional, defaults to Azure default) specifies the number of fault domains that are used.

  **Note!** \
  Please keep in mind that Azure defaults are not working for every region (especially the small ones, without any Availability
  Zones). Please verify how many update and fault domain are supported in a region before deploying this resource.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name                = string
    update_domain_count = optional(number)
    fault_domain_count  = optional(number)
  }))
}

variable "ngfw_metrics" {
  description = <<-EOF
  A map controlling metrics-relates resources.

  When set to explicit `null` (default) it will disable any metrics resources in this deployment.

  When defined it will either create or source a Log Analytics Workspace and create Application Insights instances (one per each
  Scale Set). All instances will be automatically connected to the workspace. The name of the Application Insights instance will
  be derived from the Scale Set name and suffixed with `-ai`.

  All the settings available below are common to the Log Analytics Workspace and Application Insight instances.

  Following properties are available:

  - `name`                      - (`string`, required) name of the (common) Log Analytics Workspace.
  - `create_workspace`          - (`bool`, optional, defaults to `true`) controls whether we create or source an existing Log
                                  Analytics Workspace.
  - `resource_group_name`       - (`string`, optional, defaults to `var.resource_group_name`) name of the Resource Group hosting
                                  the Log Analytics Workspace.
  - `sku`                       - (`string`, optional, defaults to module default) the SKU of the Log Analytics Workspace.
  - `metrics_retention_in_days` - (`number`, optional, defaults to module default) workspace and insights data retention in days,
                                  possible values are between 30 and 730. For sourced Workspaces this applies only to the
                                  Application Insights instances.
  EOF
  default     = null
  type = object({
    name                      = string
    create_workspace          = optional(bool, true)
    resource_group_name       = optional(string)
    sku                       = optional(string)
    metrics_retention_in_days = optional(number)
  })
}

variable "bootstrap_storages" {
  description = <<-EOF
  A map defining Azure Storage Accounts used to host file shares for bootstrapping NGFWs.

  You can create or re-use an existing Storage Account and/or File Share. For details on all available properties please refer to
  [module's documentation](../../modules/bootstrap/README.md). Following is just an extract of the most important ones:

  - `name`                      - (`string`, required) name of the Storage Account that will be created or sourced.

    **Note** \
    For new Storage Accounts this name will not be prefixed with `var.name_prefix`. \
    Please note the limitations on naming. This has to be a globally unique name, between 3 and 63 chars, only lower-case letters
    and numbers.

  - `resource_group_name`       - (`string`, optional, defaults to `null`) name of the Resource Group that hosts (sourced) or
                                  will host (created) a Storage Account. When skipped the code will fall back to
                                  `var.resource_group_name`.
  - `storage_account`           - (`map`, optional, defaults to `{}`) a map controlling basic Storage Account configuration.

    The property you should pay attention to is:

    - `create` - (`bool`, optional, defaults to module default) controls if the Storage Account specified in the `name` property
                 will be created or sourced.

    For detailed documentation see [module's documentation](../../modules/bootstrap/README.md#storage_account).

  - `storage_network_security`  - (`map`, optional, defaults to `{}`) a map defining network security settings for a **new**
                                  storage account.

    The properties you should pay attention to are:

    - `allowed_subnet_keys` - (`list`, optional, defaults to `[]`) a list of keys pointing to Subnet definitions in the
                              `var.vnets` map. These Subnets will have dedicated access to the Storage Account. For this to work
                              they also need to have the Storage Account Service Endpoint enabled.
    - `vnet_key`            - (`string`, optional) a key pointing to a VNET definition in the `var.vnets` map that stores the
                              Subnets described in `allowed_subnet_keys`.

    For detailed documentation see [module's documentation](../../modules/bootstrap/README.md#storage_network_security).

  - `file_shares_configuration` - (`map`, optional, defaults to `{}`) a map defining common File Share setting.

    The properties you should pay attention to are:

    - `create_file_shares`            - (`bool`, optional, defaults to module default) controls if the File Shares defined in the
                                        `file_shares` property will be created or sourced.
    - `disable_package_dirs_creation` - (`bool`, optional, defaults to module default) for sourced File Shares, controls if the
                                        bootstrap package folder structure will be created.

    For detailed documentation see [module's documentation](../../modules/bootstrap/README.md#file_shares_configuration).

  - `file_shares`               - (`map`, optional, defaults to `{}`) a map that holds File Shares and bootstrap package
                                  configuration. For detailed description see
                                  [module's documentation](../../modules/bootstrap/README.md#file_shares).
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name                = string
    resource_group_name = optional(string)
    storage_account = optional(object({
      create           = optional(bool)
      replication_type = optional(string)
      kind             = optional(string)
      tier             = optional(string)
      blob_retention   = optional(number)
    }), {})
    storage_network_security = optional(object({
      min_tls_version     = optional(string)
      allowed_public_ips  = optional(list(string))
      vnet_key            = optional(string)
      allowed_subnet_keys = optional(list(string), [])
    }), {})
    file_shares_configuration = optional(object({
      create_file_shares            = optional(bool)
      disable_package_dirs_creation = optional(bool)
      quota                         = optional(number)
      access_tier                   = optional(string)
    }), {})
    file_shares = optional(map(object({
      name                   = string
      bootstrap_package_path = optional(string)
      bootstrap_files        = optional(map(string))
      bootstrap_files_md5    = optional(map(string))
      quota                  = optional(number)
      access_tier            = optional(string)
    })), {})
  }))
}

variable "vmseries_universal" {
  description = <<-EOF
  A map defining common settings for all created VM-Series instances. 
  
  It duplicates popular properties from `vmseries` variable, specifically `vmseries.image` and `vmseries.virtual_machine` maps.
  However, if values are set in those maps, they still take precedence over the ones set within this variable. As a result, all
  universal properties can be overriden on a per-VM basis.

  Following properties are supported:
  
  - `version`           - (`string`, optional) describes the PAN-OS image version from Azure Marketplace.
  - `size`              - (`string`, optional, defaults to module default) Azure VM size (type). Consult the *VM-Series
                          Deployment Guide* as only a few selected sizes are supported.
  - `bootstrap_options` - (`map`, optional, mutually exclusive with `bootstrap_package`) bootstrap options passed to PAN-OS
                          when launched for the 1st time, for details see module documentation.
  - `bootstrap_package` - (`map`, optional, mutually exclusive with `bootstrap_options`) a map defining content of the bootstrap
                          package. For details and available properties refer to `vmseries` variable.
  EOF
  default     = {}
  type = object({
    version = optional(string)
    size    = optional(string)
    bootstrap_options = optional(object({
      type                                  = optional(string)
      ip-address                            = optional(string)
      default-gateway                       = optional(string)
      netmask                               = optional(string)
      ipv6-address                          = optional(string)
      ipv6-default-gateway                  = optional(string)
      hostname                              = optional(string)
      panorama-server                       = optional(string)
      panorama-server-2                     = optional(string)
      tplname                               = optional(string)
      dgname                                = optional(string)
      cgname                                = optional(string)
      dns-primary                           = optional(string)
      dns-secondary                         = optional(string)
      vm-auth-key                           = optional(string)
      op-command-modes                      = optional(string)
      op-cmd-dpdk-pkt-io                    = optional(string)
      plugin-op-commands                    = optional(string)
      dhcp-send-hostname                    = optional(string)
      dhcp-send-client-id                   = optional(string)
      dhcp-accept-server-hostname           = optional(string)
      dhcp-accept-server-domain             = optional(string)
      vm-series-auto-registration-pin-id    = optional(string)
      vm-series-auto-registration-pin-value = optional(string)
      auth-key                              = optional(string)
      authcodes                             = optional(string)
    }))
    bootstrap_package = optional(object({
      bootstrap_storage_key  = string
      static_files           = optional(map(string), {})
      bootstrap_package_path = optional(string)
      bootstrap_xml_template = optional(string)
      private_snet_key       = optional(string)
      public_snet_key        = optional(string)
      ai_update_interval     = optional(number, 5)
      intranet_cidr          = optional(string)
    }))
  })
  validation { # bootstrap_options & bootstrap_package
    condition = alltrue([
      var.vmseries_universal.bootstrap_options != null && var.vmseries_universal.bootstrap_package == null ||
      var.vmseries_universal.bootstrap_options == null && var.vmseries_universal.bootstrap_package != null ||
      var.vmseries_universal.bootstrap_options == null && var.vmseries_universal.bootstrap_package == null
    ])
    error_message = <<-EOF
    Either `bootstrap_options` or `bootstrap_package` property can be set.
    EOF
  }
  validation { # bootstrap_package
    condition = alltrue([
      var.vmseries_universal.bootstrap_package != null ? (
        var.vmseries_universal.bootstrap_package.bootstrap_xml_template != null ? (
          var.vmseries_universal.bootstrap_package.private_snet_key != null &&
          var.vmseries_universal.bootstrap_package.public_snet_key != null
        ) : true
      ) : true
    ])
    error_message = <<-EOF
    The `private_snet_key` and `public_snet_key` are required when `bootstrap_xml_template` is set.
    EOF
  }
}

variable "vmseries" {
  description = <<-EOF
  A map defining Azure Virtual Machines based on Palo Alto Networks Next Generation Firewall image.

  For details and defaults for available options please refer to the [`vmseries`](../../modules/vmseries/README.md) module.

  The most basic properties are as follows:

  - `name`            - (`string`, required) name of the VM, will be prefixed with the value of `var.name_prefix`.
  - `vnet_key`        - (`string`, required) a key of a VNET defined in `var.vnets`. This is the VNET that hosts subnets used to
                        deploy network interfaces for deployed VM.
  - `authentication`  - (`map`, optional, defaults to example defaults) authentication settings for the deployed VM.

    The `authentication` property is optional and holds the firewall admin access details. By default, standard username
    `panadmin` will be set and a random password will be auto-generated for you (available in Terraform outputs).

    **Note!** \
    The `disable_password_authentication` property is by default `false` in this example. When using this value, you don't have
    to specify anything but you can still additionally pass SSH keys for authentication. You can however set this property to
    `true`, then you have to specify `ssh_keys` property.

    For all properties and their default values see [module's documentation](../../modules/vmseries/README.md#authentication).

  - `image`           - (`map`, optional) properties defining a base image used by the deployed VM. The `image` property is
                        required (if no common properties were set within `vmseries_universal` variable) but there are only 2 
                        properties (mutually exclusive) that have to be set, either:

    - `version`   - (`string`, optional) describes the PAN-OS image version from Azure Marketplace.
    - `custom_id` - (`string`, optional) absolute ID of your own custom PAN-OS image.

    For details on all properties refer to [module's documentation](../../modules/vmseries/README.md#image).

  - `virtual_machine` - (`map`, optional, defaults to module default) a map that groups most common VM configuration options.
                        Most common properties are:

    - `size`              - (`string`, optional, defaults to module default) Azure VM size (type). Consult the *VM-Series
                            Deployment Guide* as only a few selected sizes are supported.
    - `zone`              - (`string`, required) the Availability Zone in which the VM and (if deployed) public IP addresses will
                            be created.
    - `disk_type`         - (`string`, optional, defaults to module default) type of a Managed Disk which should be created,
                            possible values are `Standard_LRS`, `StandardSSD_LRS` or `Premium_LRS` (works only for selected
                            `size` values).
    - `bootstrap_options` - (`map`, optional, mutually exclusive with `bootstrap_package`) bootstrap options passed to PAN-OS
                            when launched for the 1st time, for details see module documentation.
    - `bootstrap_package` - (`map`, optional, mutually exclusive with `bootstrap_options`) a map defining content of the
                            bootstrap package.

      **Note!** \
      At least one of `static_files`, `bootstrap_xml_template` or `bootstrap_package_path` is required. You can use a combination
      of all 3. The `bootstrap_package_path` is the less important. For details on this mechanism and for details on the other
      properties see the [`bootstrap` module documentation](../../modules/bootstrap/README.md).

      Following properties are available:

      - `bootstrap_storage_key`  - (`string`, required) a key of a bootstrap storage defined in `var.bootstrap_storages` that
                                   will host bootstrap packages. Each package will be hosted on a separate File Share. The File
                                   Shares will be created automatically, one for each firewall.
      - `static_files`           - (`map`, optional, defaults to `{}`) a map containing files that will be copied to a File
                                   Share, see [`file_shares.bootstrap_files`](../../modules/bootstrap/README.md#file_shares)
                                   property documentation for details.
      - `bootstrap_package_path` - (`string`, optional, defaults to `null`) a path to a folder containing a full bootstrap
                                   package.
      - `bootstrap_xml_template` - (`string`, optional, defaults to `null`) a path to a `bootstrap.xml` template. If this example
                                   is using full bootstrap method, the sample templates are in [`templates`](./templates) folder.

        The templates are used to provide `day0` like configuration which consists of:

        - network interfaces configuration.
        - one or more (depending on the architecture) Virtual Routers configurations. This config contains static routes
          required for the Load Balancer (and Application Gateway, if defined) health checks to work and routes that allow
          Inbound and OBEW traffic.
        - *any-any* security rule.
        - an outbound NAT rule that will allow the Outbound traffic to flow to the Internet.

        **Note!** \
        Day0 configuration is **not meant** to be **secure**. It's here merely to help with the basic firewall setup. When
        `bootstrap_xml_template` is set, one of the following properties might be required.

      - `private_snet_key`       - (`string`, required only when `bootstrap_xml_template` is set, defaults to `null`) a key
                                   pointing to a private Subnet definition in `var.vnets` (the `vnet_key` property is used to
                                   identify a VNET). The Subnet definition is used to calculate static routes for a private
                                   Load Balancer health checks and for Inbound traffic.
      - `public_snet_key`        - (`string`, required only when `bootstrap_xml_template` is set, defaults to `null`) a key
                                   pointing to a public Subnet definition in `var.vnets` (the `vnet_key` property is used to
                                   identify a VNET). The Subnet definition is used to calculate static routes for a public
                                   Load Balancer health checks and for Outbound traffic.
      - `ai_update_interval`     - (`number`, optional, defaults to `5`) Application Insights update interval, used only when
                                   `ngfw_metrics` module is defined and used in this example. The Application Insights
                                   Instrumentation Key will be populated automatically.
      - `intranet_cidr`          - (`string`, optional, defaults to `null`) a CIDR of the Intranet - combined CIDR of all
                                   private networks. When set it will override the private Subnet CIDR for inbound traffic
                                   static routes.

      For details on all properties refer to [module's documentation](../../modules/vmseries/README.md#virtual_machine).

  - `interfaces`      - (`list`, required) configuration of all network interfaces. Order of the interfaces does matter - the
                        1<sup>st</sup> interface is the management one. Most common properties are:

    - `name`                    - (`string`, required) name of the network interface (will be prefixed with `var.name_prefix`).
    - `subnet_key`              - (`string`, required) a key of a subnet to which the interface will be assigned as defined in
                                  `var.vnets`. Key identifying the VNET is defined in `virtual_machine.vnet_key` property.
    - `create_public_ip`        - (`bool`, optional, defaults to `false`) create a Public IP for an interface.
    - `load_balancer_key`       - (`string`, optional, defaults to `null`) key of a Load Balancer defined in `var.loadbalancers`
                                  variable, network interface that has this property defined will be added to the Load Balancer's
                                  backend pool.
    - `application_gateway_key` - (`string`, optional, defaults to `null`) key of an Application Gateway defined in `var.appgws`
                                  variable, network interface that has this property defined will be added to the Application
                                  Gateway's backend pool. Mutually exclusive with `appgw_backend_pool_id`.
    - `appgw_backend_pool_id`   - (`string`, optional, defaults to `null`) ID of the Application Gateway backend pool to which
                                  the network interface will be added. Mutually exclusive with `application_gateway_key`.

    For details on all properties refer to [module's documentation](../../modules/panorama/README.md#interfaces).
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name     = string
    vnet_key = string
    authentication = optional(object({
      username                        = optional(string, "panadmin")
      password                        = optional(string)
      disable_password_authentication = optional(bool, false)
      ssh_keys                        = optional(list(string), [])
    }), {})
    image = optional(object({
      version                 = optional(string)
      publisher               = optional(string)
      offer                   = optional(string)
      sku                     = optional(string)
      enable_marketplace_plan = optional(bool)
      custom_id               = optional(string)
    }))
    virtual_machine = object({
      size = optional(string)
      bootstrap_options = optional(object({
        type                                  = optional(string)
        ip-address                            = optional(string)
        default-gateway                       = optional(string)
        netmask                               = optional(string)
        ipv6-address                          = optional(string)
        ipv6-default-gateway                  = optional(string)
        hostname                              = optional(string)
        panorama-server                       = optional(string)
        panorama-server-2                     = optional(string)
        tplname                               = optional(string)
        dgname                                = optional(string)
        cgname                                = optional(string)
        dns-primary                           = optional(string)
        dns-secondary                         = optional(string)
        vm-auth-key                           = optional(string)
        op-command-modes                      = optional(string)
        op-cmd-dpdk-pkt-io                    = optional(string)
        plugin-op-commands                    = optional(string)
        dhcp-send-hostname                    = optional(string)
        dhcp-send-client-id                   = optional(string)
        dhcp-accept-server-hostname           = optional(string)
        dhcp-accept-server-domain             = optional(string)
        vm-series-auto-registration-pin-id    = optional(string)
        vm-series-auto-registration-pin-value = optional(string)
        auth-key                              = optional(string)
        authcodes                             = optional(string)
      }))
      bootstrap_package = optional(object({
        bootstrap_storage_key  = string
        static_files           = optional(map(string), {})
        bootstrap_package_path = optional(string)
        bootstrap_xml_template = optional(string)
        private_snet_key       = optional(string)
        public_snet_key        = optional(string)
        ai_update_interval     = optional(number, 5)
        intranet_cidr          = optional(string)
      }))
      zone                          = string
      disk_type                     = optional(string)
      disk_name                     = optional(string)
      avset_key                     = optional(string)
      capacity_reservation_group_id = optional(string)
      accelerated_networking        = optional(bool)
      allow_extension_operations    = optional(bool)
      encryption_at_host_enabled    = optional(bool)
      disk_encryption_set_id        = optional(string)
      enable_boot_diagnostics       = optional(bool, true)
      boot_diagnostics_storage_uri  = optional(string)
      identity_type                 = optional(string)
      identity_ids                  = optional(list(string))
    })
    interfaces = list(object({
      name                          = string
      subnet_key                    = string
      create_public_ip              = optional(bool, false)
      public_ip_name                = optional(string)
      public_ip_resource_group_name = optional(string)
      public_ip_key                 = optional(string)
      private_ip_address            = optional(string)
      load_balancer_key             = optional(string)
      application_gateway_key       = optional(string)
      appgw_backend_pool_id         = optional(string)
    }))
  }))
  validation { # virtual_machine.bootstrap_options & virtual_machine.bootstrap_package
    condition = alltrue([
      for _, v in var.vmseries :
      v.virtual_machine.bootstrap_options != null && v.virtual_machine.bootstrap_package == null ||
      v.virtual_machine.bootstrap_options == null && v.virtual_machine.bootstrap_package != null ||
      v.virtual_machine.bootstrap_options == null && v.virtual_machine.bootstrap_package == null
    ])
    error_message = <<-EOF
    Either `bootstrap_options` or `bootstrap_package` property can be set.
    EOF
  }
  validation { # virtual_machine.bootstrap_package
    condition = alltrue([
      for _, v in var.vmseries :
      v.virtual_machine.bootstrap_package.bootstrap_xml_template != null ? (
        v.virtual_machine.bootstrap_package.private_snet_key != null &&
        v.virtual_machine.bootstrap_package.public_snet_key != null
      ) : true if v.virtual_machine.bootstrap_package != null
    ])
    error_message = <<-EOF
    The `private_snet_key` and `public_snet_key` are required when `bootstrap_xml_template` is set.
    EOF
  }
  validation { # interfaces.application_gateway_key & interfaces.appgw_backend_pool_id
    condition = alltrue([
      for _, v in var.vmseries : alltrue([
        for nic in v.interfaces :
        (
          (nic.application_gateway_key == null || nic.appgw_backend_pool_id == null) ||
          (nic.application_gateway_key != null && nic.appgw_backend_pool_id == null) ||
          (nic.application_gateway_key == null && nic.appgw_backend_pool_id != null)
        )
      ])
    ])
    error_message = <<-EOF
    Only one of `application_gateway_key` or `appgw_backend_pool_id` can be set under an interface, but not both.
    EOF
  }
}

# TEST INFRASTRUCTURE

variable "test_infrastructure" {
  description = <<-EOF
  A map defining test infrastructure including test VMs and Azure Bastion hosts.

  For details and defaults for available options please refer to the
  [`test_infrastructure`](../../modules/test_infrastructure/README.md) module.

  Following properties are supported:

  - `create_resource_group`  - (`bool`, optional, defaults to `true`) when set to `true`, a new Resource Group is created. When
                               set to `false`, an existing Resource Group is sourced.
  - `resource_group_name`    - (`string`, optional) name of the Resource Group to be created or sourced.
  - `vnets`                  - (`map`, required) a map defining VNETs and peerings for the test environment. The most basic
                               properties are as follows:

    - `create_virtual_network`  - (`bool`, optional, defaults to `true`) when set to `true` will create a VNET,
                                  `false` will source an existing VNET.
    - `name`                    - (`string`, required) a name of a VNET. In case `create_virtual_network = `false` this should be
                                  a full resource name, including prefixes.
    - `address_space`           - (`list(string)`, required when `create_virtual_network = `false`) a list of CIDRs for a newly
                                  created VNET.
    - `network_security_groups` - (`map`, optional) map of Network Security Groups to create, for details see
                                  [VNET module documentation](../../modules/vnet/README.md#network_security_groups).
    - `route_tables`            - (`map`, optional) map of Route Tables to create, for details see
                                  [VNET module documentation](../../modules/vnet/README.md#route_tables).
    - `subnets`                 - (`map`, optional) map of Subnets to create or source, for details see
                                  [VNET module documentation](../../modules/vnet/README.md#subnets).
    - `local_peer_config`       - (`map`, optional) a map that contains local peer configuration parameters. This value allows to 
                                  set `allow_virtual_network_access`, `allow_forwarded_traffic`, `allow_gateway_transit` and 
                                  `use_remote_gateways` parameters on the local VNet peering. 
    - `remote_peer_config`      - (`map`, optional) a map that contains remote peer configuration parameters. This value allows to
                                  set `allow_virtual_network_access`, `allow_forwarded_traffic`, `allow_gateway_transit` and 
                                  `use_remote_gateways` parameters on the remote VNet peering.  

    For all properties and their default values see [module's documentation](../../modules/test_infrastructure/README.md#vnets).

  - `load_balancers`         - (`map`, optional) a map containing configuration for all (both private and public) Load Balancers.
                               The most basic properties are as follows:

    - `name`                    - (`string`, required) a name of the Load Balancer.
    - `vnet_key`                - (`string`, optional, defaults to `null`) a key pointing to a VNET definition in the `var.vnets`
                                  map that stores the Subnet described by `subnet_key`.
    - `zones`                   - (`list`, optional, defaults to module default) a list of zones for Load Balancer's frontend IP
                                  configurations.
    - `backend_name`            - (`string`, optional) a name of the backend pool to create.
    - `health_probes`           - (`map`, optional, defaults to `null`) a map defining health probes that will be used by load
                                  balancing rules, please refer to
                                  [loadbalancer module documentation](../../modules/loadbalancer/README.md#health_probes) for
                                  more specific use cases and available properties.
    - `nsg_auto_rules_settings` - (`map`, optional, defaults to `null`) a map defining a location of an existing NSG rule that
                                  will be populated with `Allow` rules for each load balancing rule (`in_rules`), please refer to
                                  [loadbalancer module documentation](../../modules/loadbalancer/README.md#nsg_auto_rules_settings)
                                  for available properties.

    Please note that in this example two additional properties are available:

      - `nsg_vnet_key` - (`string`, optional, mutually exclusive with `nsg_name`) a key pointing to a VNET definition in the
                         `var.vnets` map that stores the NSG described by `nsg_key`.
      - `nsg_key`      - (`string`, optional, mutually exclusive with `nsg_name`) a key pointing to an NSG definition in the
                         `var.vnets` map.

    - `frontend_ips`            - (`map`, optional, defaults to `{}`) a map containing frontend IP configuration with respective
                                  `in_rules` and `out_rules`, please refer to
                                  [loadbalancer module documentation](../../modules/loadbalancer/README.md#frontend_ips) for
                                  available properties.

      **Note!** \
      In this example the `subnet_id` is not available directly, another property has been introduced instead:

      - `subnet_key` - (`string`, optional, defaults to `null`) a key pointing to a Subnet definition in the `var.vnets` map.

    For all properties and their default values see
    [module's documentation](../../modules/test_infrastructure/README.md#load_balancers).

  - `authentication`         - (`map`, optional, defaults to example defaults) authentication settings for the deployed VMs.
  - `spoke_vms`              - (`map`, required) a map defining test VMs. The most basic properties are as follows:

    - `name`              - (`string`, required) a name of the VM.
    - `vnet_key`          - (`string`, required) a key describing a VNET defined in `vnets` property.
    - `subnet_key`        - (`string`, required) a key describing a Subnet found in a VNET definition.
    - `load_balancer_key` - (`string`, optional) a key describing a Load Balancer defined in `load_balancers` property.

    For all properties and their default values see
    [module's documentation](../../modules/test_infrastructure/README.md#test_vms).

  - `bastions`               - (`map`, required) a map containing Azure Bastion definitions. The most basic properties are as
                               follows:

    - `name`       - (`string`, required) an Azure Bastion name.
    - `vnet_key`   - (`string`, required) a key describing a VNET defined in `vnets` property. This VNET should already have an
                     existing subnet called `AzureBastionSubnet` (the name is hardcoded by Microsoft).
    - `subnet_key` - (`string`, required) a key pointing to a Subnet dedicated to a Bastion deployment.

    For all properties and their default values see
    [module's documentation](../../modules/test_infrastructure/README.md#bastions).
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    create_resource_group = optional(bool, true)
    resource_group_name   = optional(string)
    vnets = map(object({
      create_virtual_network  = optional(bool, true)
      name                    = string
      address_space           = optional(list(string))
      dns_servers             = optional(list(string))
      hub_resource_group_name = optional(string)
      hub_vnet_name           = string
      network_security_groups = optional(map(object({
        name = string
        rules = optional(map(object({
          name                         = string
          priority                     = number
          direction                    = string
          access                       = string
          protocol                     = string
          source_port_range            = optional(string)
          source_port_ranges           = optional(list(string))
          destination_port_range       = optional(string)
          destination_port_ranges      = optional(list(string))
          source_address_prefix        = optional(string)
          source_address_prefixes      = optional(list(string))
          destination_address_prefix   = optional(string)
          destination_address_prefixes = optional(list(string))
        })), {})
      })), {})
      route_tables = optional(map(object({
        name                          = string
        bgp_route_propagation_enabled = optional(bool)
        routes = map(object({
          name                = string
          address_prefix      = string
          next_hop_type       = string
          next_hop_ip_address = optional(string)
        }))
      })), {})
      subnets = optional(map(object({
        create                          = optional(bool, true)
        name                            = string
        address_prefixes                = optional(list(string), [])
        network_security_group_key      = optional(string)
        route_table_key                 = optional(string)
        enable_storage_service_endpoint = optional(bool)
        enable_cloudngfw_delegation     = optional(bool)
      })), {})
      local_peer_config = optional(object({
        allow_virtual_network_access = optional(bool, true)
        allow_forwarded_traffic      = optional(bool, true)
        allow_gateway_transit        = optional(bool, false)
        use_remote_gateways          = optional(bool, false)
      }), {})
      remote_peer_config = optional(object({
        allow_virtual_network_access = optional(bool, true)
        allow_forwarded_traffic      = optional(bool, true)
        allow_gateway_transit        = optional(bool, false)
        use_remote_gateways          = optional(bool, false)
      }), {})
    }))
    load_balancers = optional(map(object({
      name         = string
      vnet_key     = optional(string)
      zones        = optional(list(string))
      backend_name = optional(string)
      health_probes = optional(map(object({
        name                = string
        protocol            = string
        port                = optional(number)
        probe_threshold     = optional(number)
        interval_in_seconds = optional(number)
        request_path        = optional(string)
      })))
      nsg_auto_rules_settings = optional(object({
        nsg_name                = optional(string)
        nsg_vnet_key            = optional(string)
        nsg_key                 = optional(string)
        nsg_resource_group_name = optional(string)
        source_ips              = list(string)
        base_priority           = optional(number)
      }))
      frontend_ips = optional(map(object({
        name                          = string
        subnet_key                    = optional(string)
        create_public_ip              = optional(bool, false)
        public_ip_name                = optional(string)
        public_ip_resource_group_name = optional(string)
        public_ip_key                 = optional(string)
        public_ip_prefix_key          = optional(string)
        private_ip_address            = optional(string)
        gwlb_key                      = optional(string)
        in_rules = optional(map(object({
          name                = string
          protocol            = string
          port                = number
          backend_port        = optional(number)
          health_probe_key    = optional(string)
          floating_ip         = optional(bool)
          session_persistence = optional(string)
          nsg_priority        = optional(number)
        })), {})
        out_rules = optional(map(object({
          name                     = string
          protocol                 = string
          allocated_outbound_ports = optional(number)
          enable_tcp_reset         = optional(bool)
          idle_timeout_in_minutes  = optional(number)
        })), {})
      })), {})
    })), {})
    authentication = optional(object({
      username = optional(string, "bitnami")
      password = optional(string)
    }), {})
    spoke_vms = map(object({
      name               = string
      interface_name     = optional(string)
      disk_name          = optional(string)
      vnet_key           = string
      subnet_key         = string
      load_balancer_key  = optional(string)
      private_ip_address = optional(string)
      size               = optional(string)
      image = optional(object({
        publisher               = optional(string)
        offer                   = optional(string)
        sku                     = optional(string)
        version                 = optional(string)
        enable_marketplace_plan = optional(bool)
      }), {})
      custom_data = optional(string)
    }))
    bastions = map(object({
      name                          = string
      create_public_ip              = optional(bool, true)
      public_ip_name                = optional(string)
      public_ip_resource_group_name = optional(string)
      public_ip_key                 = optional(string)
      vnet_key                      = string
      subnet_key                    = string
    }))
  }))
}
