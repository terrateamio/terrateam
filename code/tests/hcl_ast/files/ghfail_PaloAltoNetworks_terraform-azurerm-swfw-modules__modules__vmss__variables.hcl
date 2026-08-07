variable "name" {
  description = "The name of the Azure Virtual Machine Scale Set."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group to use."
  type        = string
}

variable "region" {
  description = "The name of the Azure region to deploy the resources in."
  type        = string
}

variable "tags" {
  description = "The map of tags to assign to all created resources."
  default     = {}
  type        = map(string)
}
variable "authentication" {
  description = <<-EOF
  A map defining authentication settings (including username and password).

  Following properties are available:

  - `username`                        - (`string`, optional, defaults to `panadmin`) the initial administrative VM-Series
                                        username.
  - `password`                        - (`string`, optional, defaults to `null`) the initial administrative VM-Series password.
  - `disable_password_authentication` - (`bool`, optional, defaults to `true`) disables password-based authentication.
  - `ssh_keys`                        - (`list`, optional, defaults to `[]`) a list of initial administrative SSH public keys.

  **Important!** \
  The `password` property is required when `ssh_keys` is not specified. You can have both, password and key authentication.

  **Important!** \
  `ssh_keys` property is a list of strings, so each item should be the actual public key value.
  If you would like to load them from files use the `file` function, for example: `[ file("/path/to/public/keys/key_1.pub") ]`.
  EOF
  type = object({
    username                        = optional(string, "panadmin")
    password                        = optional(string)
    disable_password_authentication = optional(bool, true)
    ssh_keys                        = optional(list(string), [])
  })
  validation { # password, disable_password_authentication & ssh_keys
    condition = !(
      var.authentication.password == null &&
      !var.authentication.disable_password_authentication && length(var.authentication.ssh_keys) == 0
    )
    error_message = <<-EOF
    At least `password` or `ssh_keys` property has to be set when `disable_password_authentication` is `false`.
    EOF
  }
  validation { # disable_password_authentication & ssh_keys
    condition = !(
      var.authentication.disable_password_authentication && length(var.authentication.ssh_keys) == 0
    )
    error_message = <<-EOF
    The `ssh_keys` property has to be set when `disable_password_authentication` is `true`.
    EOF
  }
}

variable "image" {
  description = <<-EOF
  Basic Azure VM configuration.

  Following properties are available:

  - `use_airs`                - (`bool`, optional, defaults to `false`) when set to `true`, the AI Runtime Security VM image is
                                used instead of the one passed to the module and version for `airs-flex` offer must be provided.
  - `version`                 - (`string`, optional, defaults to `null`) VM-Series PAN-OS version; list available with 
                                `az vm image list -o table --publisher paloaltonetworks --offer vmseries-flex --all`.
  - `publisher`               - (`string`, optional, defaults to `paloaltonetworks`) the Azure Publisher identifier for an image
                                which should be deployed.
  - `offer`                   - (`string`, optional, defaults to `vmseries-flex`) the Azure Offer identifier corresponding to a
                                published image.
  - `sku`                     - (`string`, optional, defaults to `byol`) VM-Series SKU, list available with
                                `az vm image list -o table --all --publisher paloaltonetworks`.
  - `enable_marketplace_plan` - (`bool`, optional, defaults to `true`) when set to `true` accepts the license for an offer/plan
                                on Azure Market Place.
  - `custom_id`               - (`string`, optional, defaults to `null`) absolute ID of your own custom PAN-OS image to be used
                                for creating new Virtual Machines.

  **Important!** \
  `custom_id` and `version` properties are mutually exclusive.
  EOF
  type = object({
    use_airs                = optional(bool, false)
    version                 = optional(string)
    publisher               = optional(string, "paloaltonetworks")
    offer                   = optional(string, "vmseries-flex")
    sku                     = optional(string, "byol")
    enable_marketplace_plan = optional(bool, true)
    custom_id               = optional(string)
  })
  validation { # version & custom_id
    condition = (var.image.custom_id != null && var.image.version == null
      ) || (
      var.image.custom_id == null && var.image.version != null
    )
    error_message = <<-EOF
    Either `custom_id` or `version` has to be defined.
    EOF
  }
}

variable "virtual_machine_scale_set" {
  description = <<-EOF
  Scale set parameters configuration.

  This map contains basic, as well as some optional Virtual Machine Scale Set parameters. Both types contain sane defaults.
  Nevertheless they should be at least reviewed to meet deployment requirements.

  List of either required or important properties: 

  - `orchestration_type` - (`string`, optional, defaults to `Uniform`) this variable is used to select between the Uniform or
                           Flexible Scale Set orchestration modes. Possible values are `Uniform` and `Flexible`.
  - `size`               - (`string`, optional, defaults to `Standard_D3_v2`) Azure VM size (type). Consult the *VM-Series
                           Deployment Guide* as only few selected sizes are supported. The default one is a VM-300 equivalent.
  - `zones`              - (`list`, optional, defaults to `null`) a list of Availability Zones in which VMs from this Scale Set
                           will be created. Zone balance is available from at least 2 zones.
  - `disk_type`          - (`string`, optional, defaults to `StandardSSD_LRS`) type of Managed Disk which should be created,
                           possible values are `Standard_LRS`, `StandardSSD_LRS` or `Premium_LRS` (works only for selected `size`
                           values).
  - `bootstrap_options`  - (`string`, optional) bootstrap options to pass to VM-Series instance.

      Proper syntax is a string of semicolon separated properties, for example:

      ```hcl
      bootstrap_options = "type=dhcp-client;panorama-server=1.2.3.4"
      ```

      For more details on bootstrapping [see documentation](https://docs.paloaltonetworks.com/vm-series/10-2/vm-series-deployment/bootstrap-the-vm-series-firewall/create-the-init-cfgtxt-file/init-cfgtxt-file-components).

  List of other, optional properties:

  - `accelerated_networking`        - (`bool`, optional, defaults to `true`) when set to `true` enables Azure accelerated
                                      networking (SR-IOV) for all dataplane network interfaces, this does not affect the
                                      management interface (always disabled).
  - `allow_extension_operations`    - (`bool`, optional, defaults to `false`) should Extension Operations be allowed on this VM.
  - `disk_encryption_set_id`        - (`string`, optional, defaults to `null`) the ID of the Disk Encryption Set which should be
                                      used to encrypt this VM's disk.
  - `encryption_at_host_enabled`    - (`bool`, optional, defaults to Azure defaults) should all of disks be encrypted by enabling
                                      Encryption at Host.
  - `overprovision`                 - (`bool`, optional, defaults to `true`) controls whether Azure should over-provision Virtual
                                      Machines in the Scale Set for improved deployment time and provisioning success rate.
  - `platform_fault_domain_count`   - (`number`, optional, defaults to `5`) specifies the number of fault domains that are used
                                      by this Virtual Machine Scale Set. The Flexible orchestration mode requires this parameter
                                      to be set.
  - `single_placement_group`        - (`bool`, optional, defaults to Azure defaults) when `true` this Virtual Machine Scale Set
                                      will be limited to a Single Placement Group, which means the number of instances will be
                                      capped at 100 Virtual Machines.
  - `capacity_reservation_group_id` - (`string`, optional, defaults to `null`) specifies the ID of the Capacity Reservation Group
                                      which the Virtual Machine Scale Set should be allocated to.
  - `enable_boot_diagnostics`       - (`bool`, optional, defaults to `false`) enables boot diagnostics for a VM.
  - `boot_diagnostics_storage_uri`  - (`string`, optional, defaults to `null`) Storage Account's Blob endpoint to hold diagnostic
                                      files, when skipped a managed Storage Account will be used (preferred).
  - `identity_type`                 - (`string`, optional, defaults to `SystemAssigned`) type of Managed Service Identity that
                                      should be configured on this VM. Can be one of "SystemAssigned", "UserAssigned" or
                                      "SystemAssigned, UserAssigned". For the Flexible orchestration mode this parameter must be
                                      configured to "UserAssigned".
  - `identity_ids`                  - (`list`, optional, defaults to `[]`) a list of User Assigned Managed Identity IDs to be 
                                      assigned to this VM. Required only if `identity_type` is not "SystemAssigned".
  EOF
  default     = {}
  nullable    = false
  type = object({
    orchestration_type            = optional(string, "Uniform")
    size                          = optional(string, "Standard_D3_v2")
    bootstrap_options             = optional(string)
    zones                         = optional(list(string))
    disk_type                     = optional(string, "StandardSSD_LRS")
    accelerated_networking        = optional(bool, true)
    allow_extension_operations    = optional(bool, false)
    encryption_at_host_enabled    = optional(bool)
    overprovision                 = optional(bool, true)
    platform_fault_domain_count   = optional(number, 5)
    single_placement_group        = optional(bool)
    capacity_reservation_group_id = optional(string)
    disk_encryption_set_id        = optional(string)
    enable_boot_diagnostics       = optional(bool, false)
    boot_diagnostics_storage_uri  = optional(string)
    identity_type                 = optional(string, "SystemAssigned")
    identity_ids                  = optional(list(string), [])
  })
  validation { # orchestration_type
    condition     = contains(["Flexible", "Uniform"], var.virtual_machine_scale_set.orchestration_type)
    error_message = <<-EOF
    The orchestration type must be Flexible or Uniform, it can't have any other value assigned
    EOF
  }
  validation { # disk_type
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.virtual_machine_scale_set.disk_type)
    error_message = <<-EOF
    The `disk_type` property can be one of: `Standard_LRS`, `StandardSSD_LRS` or `Premium_LRS`.
    EOF
  }
  validation { # single_placement_group, capacity_reservation_group_id
    condition = var.virtual_machine_scale_set.capacity_reservation_group_id != null ? (
      var.virtual_machine_scale_set.single_placement_group == false
    ) : true
    error_message = <<-EOF
    When `capacity_reservation_group_id` value is set, the `single_placement_group` value must equal to false.
    EOF
  }
  validation { # identity_type
    condition = contains(
      ["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"],
      var.virtual_machine_scale_set.identity_type
    )
    error_message = <<-EOF
    The `identity_type` property can be one of \"SystemAssigned\", \"UserAssigned\" or \"SystemAssigned, UserAssigned\".
    EOF
  }
  validation { # identity_type & identity_ids
    condition = var.virtual_machine_scale_set.identity_type == "SystemAssigned" ? (
      length(var.virtual_machine_scale_set.identity_ids) == 0
    ) : length(var.virtual_machine_scale_set.identity_ids) >= 0
    error_message = <<-EOF
    The `identity_ids` property is required when `identity_type` is not \"SystemAssigned\".
    EOF
  }
}

variable "interfaces" {
  description = <<-EOF
  List of the network interfaces specifications.

  **Note!** \
  The ORDER in which you specify the interfaces DOES MATTER.

  Interfaces will be attached to VM in the order you define here, therefore:

  - the first should be the management interface, which does not participate in data filtering
  - the remaining ones are the dataplane interfaces.
  
  Following configuration options are available:

  - `name`                           - (`string`, required) the interface name.
  - `subnet_id`                      - (`string`, required) ID of an existing subnet to create the interface in.
  - `ip_configurations`              - (`map`, required) A map that contains the IP configurations for the interface.
    - `name`                           - (`string`, optional, defaults to `primary`) the name of the interface IP configuration.
    - `primary`                        - (`bool`, optional, defaults to `true`) sets the current IP configuration as the primary
                                         one.
    - `create_public_ip`               - (`bool`, optional, defaults to `false`) if `true`, create a public IP for the interface.
    - `pip_domain_name_label`          - (`string`, optional, defaults to `null`) the Prefix which should be used for the Domain
                                         Name Label for each Virtual Machine Instance.
    - `pip_idle_timeout_in_minutes`    - (`number`, optional, defaults to Azure default) the Idle Timeout in minutes for the 
                                         Public IP Address, possible values are in the range from 4 to 32.
    - `pip_prefix_name`                - (`string`, optional) the name of an existing Public IP Address Prefix from where Public
                                         IP Addresses should be allocated.
    - `pip_prefix_resource_group_name` - (`string`, optional, defaults to the VMSS's RG) name of a Resource Group hosting an 
                                         existing Public IP Prefix resource.
    - `pip_prefix_id`                  - (`string`, optional) you can specify Public IP Prefix ID as an alternative to the
                                         properties above (name and resource group), in case you want to avoid using a data
                                         source block.
  - `lb_backend_pool_ids`            - (`list`, optional, defaults to `[]`) a list of identifiers of existing Load Balancer
                                       backend pools to associate the interface with. Only applied to primary IP configuration.
  - `appgw_backend_pool_ids`         - (`list`, optional, defaults to `[]`) a list of identifier of Application Gateway's backend
                                       pools to associate the interface with. Only applied to primary IP configuration.

  Example:

  ```hcl
  [
    {
      name       = "management"
      subnet_id  = azurerm_subnet.my_mgmt_subnet.id
      ip_configurations = {
          primary-ip = {
            name             = "primary-ip"
            primary          = true
            create_public_ip = true
      }
    },
    {
      name      = "private"
      subnet_id = azurerm_subnet.my_priv_subnet.id
      ip_configurations = {
          primary-ip = {
            name             = "primary-ip"
            primary          = true
            create_public_ip = false
      }
    },
    {
      name                = "public"
      subnet_id           = azurerm_subnet.my_pub_subnet.id
      lb_backend_pool_ids = [azurerm_lb_backend_address_pool.lb_backend.id]
      ip_configurations = {
          primary-ip = {
            name             = "primary-ip"
            primary          = true
            create_public_ip = true
      }
    }
  ]
  ```
  EOF
  type = list(object({
    name      = string
    subnet_id = string
    ip_configurations = map(object({
      name                           = optional(string, "primary")
      primary                        = optional(bool, true)
      create_public_ip               = optional(bool, false)
      pip_domain_name_label          = optional(string)
      pip_idle_timeout_in_minutes    = optional(number)
      pip_prefix_name                = optional(string)
      pip_prefix_resource_group_name = optional(string)
      pip_prefix_id                  = optional(string)
    }))
    lb_backend_pool_ids    = optional(list(string), [])
    appgw_backend_pool_ids = optional(list(string), [])
  }))
  validation { # lb_backend_pool_ids & appgw_backend_pool_ids
    condition     = length(var.interfaces[0].lb_backend_pool_ids) == 0 && length(var.interfaces[0].appgw_backend_pool_ids) == 0
    error_message = <<-EOF
    The `lb_backend_pool_ids` and `appgw_backend_pool_ids` properties are not acceptable for the 1st (management) interface.
    EOF
  }
  validation { # primary_ip
    condition = alltrue(flatten([
      for interface in var.interfaces : [
        length([
          for config_key, config in interface.ip_configurations : config_key
          if config.primary == true
        ]) == 1
      ]
    ]))
    error_message = <<-EOF
    Each interface must have exactly one IP configuration with `primary = true`.
    EOF
  }
  validation { # pip_idle_timeout_in_minutes
    condition = alltrue(flatten([
      for interface in var.interfaces : [
        for ip_config_name, ip_config in coalesce(interface.ip_configurations, {}) :
        (ip_config.pip_idle_timeout_in_minutes >= 4 && ip_config.pip_idle_timeout_in_minutes <= 32)
        if ip_config.pip_idle_timeout_in_minutes != null
      ]
    ]))
    error_message = <<-EOF
    The `pip_idle_timeout_in_minutes` value must be a number between 4 and 32.
    EOF
  }
}

variable "autoscaling_configuration" {
  description = <<-EOF
  Autoscaling configuration common to all policies.

  Following properties are available:

  - `application_insights_id` - (`string`, optional, defaults to `null`) an ID of Application Insights instance that should
                                be used to provide metrics for autoscaling; to **avoid false positives** this should be an
                                instance **dedicated to this Scale Set**.
  - `default_count`           - (`number`, optional, defaults to `2`) minimum number of instances that should be present
                                in the scale set when the autoscaling engine cannot read the metrics or is otherwise unable
                                to compare the metrics to the thresholds.
  - `scale_in_policy`         - (`string`, optional, defaults to Azure default) controls which VMs are chosen for removal
                                during a scale-in, can be one of: `Default`, `NewestVM`, `OldestVM`.
  - `scale_in_force_deletion` - (`bool`, optional, defaults to `false`) when `true` will **force delete** machines during a 
                                scale-in operation.
  - `notification_emails`     - (`list`, optional, defaults to `[]`) list of email addresses to notify about autoscaling
                                events.
  - `webhooks_uris`           - (`map`, optional, defaults to `{}`) the URIs that receive autoscaling events; a map where keys
                                are just arbitrary identifiers and the values are the webhook URIs.
  EOF
  default     = {}
  nullable    = false
  type = object({
    application_insights_id = optional(string)
    default_count           = optional(number, 2)
    scale_in_policy         = optional(string)
    scale_in_force_deletion = optional(bool, false)
    notification_emails     = optional(list(string), [])
    webhooks_uris           = optional(map(string), {})
  })
  validation { # scale_in_policy
    condition = var.autoscaling_configuration.scale_in_policy != null ? contains(
      ["Default", "NewestVM", "OldestVM"], var.autoscaling_configuration.scale_in_policy
    ) : true
    error_message = <<-EOF
    The `scale_in_policy` property can be one of: `Default`, `NewestVM`, `OldestVM`.
    EOF
  }
}

variable "autoscaling_profiles" {
  description = <<-EOF
  A list defining autoscaling profiles.

  **Note!** \
  The order does matter. The 1<sup>st</sup> profile becomes the default one.

  There are some considerations when creating autoscaling configuration:

  1. the 1<sup>st</sup> profile created will become the default one, it cannot contain any schedule.
  2. all other profiles should contain schedules.
  3. the scaling rules are optional, if you skip them you will create a profile with a set number of VM instances 
    (in such case the `minimum_count` and `maximum_count` properties are skipped).

  Following properties are available:

  - `name`          - (`string`, required) the name of the profile.
  - `default_count` - (`number`, required) the default number of VMs.
  - `minimum_count` - (`number`, optional, defaults to `default_count`) minimum number of VMs when scaling in.
  - `maximum_count` - (`number`, optional, defaults to `default_count`) maximum number of VMs when you scale out.
  - `recurrence`    - (`map`, required for rules beside the 1st one) a map defining time schedule for the profile to apply:
    - `timezone`   - (`string`, optional, defaults to Azure default (UTC)) timezone for the time schedule, supported list can
                     be found [here](https://learn.microsoft.com/en-us/rest/api/monitor/autoscale-settings/create-or-update?view=rest-monitor-2022-10-01&tabs=HTTP#:~:text=takes%20effect%20at.-,timeZone,-string).
    - `days`       - (`list`, required) list of days of the week during which the profile is applicable, case sensitive, possible
                     values are "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" and "Sunday".
    - `start_time` - (`string`, required) profile start time in RFC3339 format.
    - `end_time`   - (`string`, required) profile end time in RFC3339 format.
  - `scale_rules`   - (`list`, optional, defaults to `[]`) a list of maps defining metrics and rules for autoscaling. 

      **Note!** \
      By default all VMSS built-in metrics are available. These do not differentiate between management and data planes.
      For more accuracy please use NGFW metrics.

      Each metric definition is a map with 3 properties:

      - `name`             - (`string`, required) name of the rule.
      - `scale_out_config` - (`map`, required) definition of the rule used to scale-out.
      - `scale_in_config`  - (`map`, required) definition of the rule used to scale-in.

          Both `scale_out_config` and `scale_in_config` maps contain the same properties. The ones that are required for
          scale-out but optional for scale-in, when skipped in the latter configuration, default to scale-out values:
          
          - `threshold`                  - (`number`, required) the threshold of a metric that triggers the scale action.
          - `operator`                   - (`string`, optional, defaults to `>=` or `<=` for scale-out and scale-in respectively)
                                           the metric vs. threshold comparison operator, can be one of: `>`, `>=`, `<`, `<=`,
                                           `==` or `!=`.
          - `grain_window_minutes`       - (`number`, required for scale-out, optional for scale-in) granularity of metrics that
                                           the rule monitors, between 1 minute and 12 hours (specified in minutes).
          - `grain_aggregation_type`     - (`string`, optional, defaults to "Average") method used to combine data from 
                                           `grain_window`, can be one of `Average`, `Max`, `Min` or `Sum`.
          - `aggregation_window_minutes` - (`number`, required for scale-out, optional for scale-in) time window used to analyze
                                           metrics, between 5 minutes and 12 hours (specified in minutes), must be greater than
                                           `grain_window_minutes`.
          - `aggregation_window_type`    - (`string`, optional, defaults to "Average") method used to combine data from
                                           `aggregation_window`, can be one of `Average`, `Maximum`, `Minimum`, `Count`, `Last`
                                           or `Total`.
          - `cooldown_window_minutes`    - (`number`, required) the amount of time to wait after a scale action, between 1 minute
                                           and 1 week (specified in minutes).
          - `change_count_by`            - (`number`, optional, default to `1`) a number of VM instances by which the total count
                                           of instances in a Scale Set will be changed during a scale action.

  Example:

  ```hcl
  # defining one profile
  autoscaling_profiles = [
    {
      name          = "default_profile"
      default_count = 2
      minimum_count = 2
      maximum_count = 4
      scale_rules = [
        {
          name = "DataPlaneCPUUtilizationPct"
          scale_out_config = {
            threshold                  = 85
            grain_window_minutes       = 1
            aggregation_window_minutes = 25
            cooldown_window_minutes    = 60
          }
          scale_in_config = {
            threshold               = 60
            cooldown_window_minutes = 120
          }
        }
      ]
    }
  ]

  # defining a profile with a rule scaling to 1 NGFW, used when no other rule is applicable
  # and a second rule used for autoscaling during 'office hours'
  autoscaling_profiles = [
    {
      name          = "default_profile"
      default_count = 1
    },
    {
      name          = "weekday_profile"
      default_count = 2
      minimum_count = 2
      maximum_count = 10
      recurrence = {
        days       = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        start_time = "07:30"
        end_time   = "17:00"
      }
      scale_rules = [
        {
          name = "Percentage CPU"
          scale_out_config = {
            threshold                  = 70
            grain_window_minutes       = 5
            aggregation_window_minutes = 30
            cooldown_window_minutes    = 60
          }
          scale_in_config = {
            threshold               = 40
            cooldown_window_minutes = 120
          }
        },
        {
          name = "Outbound Flows"
          scale_out_config = {
            threshold                  = 500
            grain_window_minutes       = 5
            aggregation_window_minutes = 30
            cooldown_window_minutes    = 60
          }
          scale_in_config = {
            threshold               = 400
            cooldown_window_minutes = 60
          }
        }
      ]
    },
  ]
  ```
  EOF
  default     = []
  nullable    = false
  type = list(object({
    name          = string
    minimum_count = optional(number)
    default_count = number
    maximum_count = optional(number)
    recurrence = optional(object({
      timezone   = optional(string)
      days       = list(string)
      start_time = string
      end_time   = string
    }))
    scale_rules = optional(list(object({
      name = string
      scale_out_config = object({
        threshold                  = number
        operator                   = optional(string, ">=")
        grain_window_minutes       = number
        grain_aggregation_type     = optional(string, "Average")
        aggregation_window_minutes = number
        aggregation_window_type    = optional(string, "Average")
        cooldown_window_minutes    = number
        change_count_by            = optional(number, 1)
      })
      scale_in_config = object({
        threshold                  = number
        operator                   = optional(string, "<=")
        grain_window_minutes       = optional(number)
        grain_aggregation_type     = optional(string, "Average")
        aggregation_window_minutes = optional(number)
        aggregation_window_type    = optional(string, "Average")
        cooldown_window_minutes    = number
        change_count_by            = optional(number, 1)
      })
    })), [])
  }))
  validation { # autoscaling_profiles
    condition     = length(var.autoscaling_profiles) <= 20
    error_message = <<-EOF
    Azure supports up to 20 autoscaling profiles.
    EOF
  }
  validation { # recurrence
    condition     = length(var.autoscaling_profiles) > 0 ? var.autoscaling_profiles[0].recurrence == null : true
    error_message = <<-EOF
    The `autoscaling_profiles->recurrence` property is not allowed in the 1st profile definition.
    EOF
  }
  validation { # recurrence
    condition = length(var.autoscaling_profiles) > 0 ? alltrue([
      for v in slice(var.autoscaling_profiles, 1, length(var.autoscaling_profiles)) : v.recurrence != null
    ]) : true
    error_message = <<-EOF
    The `autoscaling_profiles->recurrence` property is required in all profiles except the 1st one.
    EOF
  }
  validation { # recurrence.days
    condition = length(var.autoscaling_profiles) > 0 ? alltrue(flatten(
      [for v in slice(var.autoscaling_profiles, 1, length(var.autoscaling_profiles)) :
        [for day in v.recurrence.days :
          contains(
            ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
            day
          )
        ]
      ]
    )) : true
    error_message = <<-EOF
    The `autoscaling_profiles->recurrence.days` property can be one of: `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`,
    `Saturday` or `Sunday`.
    EOF
  }
  validation { # recurrence.start_time
    condition = length(var.autoscaling_profiles) > 0 ? alltrue([
      for v in slice(var.autoscaling_profiles, 1, length(var.autoscaling_profiles)) :
      can(regex("^(([0,1][0-9])|(2[0-3])):([0-5][0-9])$", v.recurrence.start_time))
    ]) : true
    error_message = <<-EOF
    The `autoscaling_profiles->recurrence.start_time` property has to be a time in RFC3339 format.
    EOF
  }
  validation { # recurrence.end_time
    condition = length(var.autoscaling_profiles) > 0 ? alltrue([
      for v in slice(var.autoscaling_profiles, 1, length(var.autoscaling_profiles)) :
      can(regex("^(([0,1][0-9])|(2[0-3])):([0-5][0-9])$", v.recurrence.end_time))
    ]) : true
    error_message = <<-EOF
    The `autoscaling_profiles->recurrence.end_time` property has to be a time in RFC3339 format.
    EOF
  }
  validation { # scale_rules
    condition     = alltrue([for profile in var.autoscaling_profiles : length(profile.scale_rules) <= 10])
    error_message = <<-EOF
    Azure supports up to 10 scale rules per autoscaling profile.
    EOF
  }
  validation { # scale_rules.scale_in/out_config.operator
    condition = alltrue(flatten([
      for profile in var.autoscaling_profiles : [
        for rule in profile.scale_rules : [
          for config in ["scale_out_config", "scale_in_config"] :
          contains([">", ">=", "<", "<=", "==", "!="], rule[config].operator)
        ]
      ]
    ]))
    error_message = <<-EOF
    The `operator` property can be one of: `>`, `>=`, `<`, `<=`, `==` or `!=`.
    EOF
  }
  validation { # scale_rules.scale_in/out_config.grain_window_minutes
    condition = alltrue(flatten([
      for profile in var.autoscaling_profiles : [
        for rule in profile.scale_rules : [
          for config in ["scale_out_config", "scale_in_config"] :
          rule[config].grain_window_minutes >= 1 && rule[config].grain_window_minutes <= 720
          if rule[config].grain_window_minutes != null
        ]
      ]
    ]))
    error_message = <<-EOF
    The `grain_window_minutes` property has to be between 1 minute and 12 hours.
    EOF
  }
  validation { # scale_rules.scale_in/out_config.grain_aggregation_type
    condition = alltrue(flatten([
      for profile in var.autoscaling_profiles : [
        for rule in profile.scale_rules : [
          for config in ["scale_out_config", "scale_in_config"] :
          contains(["Average", "Max", "Min", "Sum"], rule[config].grain_aggregation_type)
        ]
      ]
    ]))
    error_message = <<-EOF
    The `grain_aggregation_type` property can be one of: `Average`, `Max`, `Min` or `Sum`.
    EOF
  }
  validation { # scale_rules.scale_in/out_config.aggregation_window_minutes
    condition = alltrue(flatten([
      for profile in var.autoscaling_profiles : [
        for rule in profile.scale_rules : [
          for config in ["scale_out_config", "scale_in_config"] :
          rule[config].aggregation_window_minutes >= 5 &&
          rule[config].aggregation_window_minutes <= 720 &&
          rule[config].aggregation_window_minutes > rule[config].grain_window_minutes
          if rule[config].aggregation_window_minutes != null
        ]
      ]
    ]))
    error_message = <<-EOF
    The `aggregation_window_minutes` property has to be between 5 minute and 12 hours and should be longer than
    `grain_window_minutes`.
    EOF
  }
  validation { # scale_rules.scale_in/out_config.aggregation_window_type
    condition = alltrue(flatten([
      for profile in var.autoscaling_profiles : [
        for rule in profile.scale_rules : [
          for config in ["scale_out_config", "scale_in_config"] :
          contains(["Average", "Maximum", "Minimum", "Total", "Count", "Last"], rule[config].aggregation_window_type)
        ]
      ]
    ]))
    error_message = <<-EOF
    The `aggregation_window_type` property can be one of: `Average`, `Maximum`, `Minimum`, `Count`, `Last` or `Total`.
    EOF
  }
  validation { # scale_rules.scale_in/out_config.cooldown_window_minutes
    condition = alltrue(flatten([
      for profile in var.autoscaling_profiles : [
        for rule in profile.scale_rules : [
          for config in ["scale_out_config", "scale_in_config"] :
          rule[config].cooldown_window_minutes >= 1 && rule[config].cooldown_window_minutes <= 10080
        ]
      ]
    ]))
    error_message = <<-EOF
    The `cooldown_window_minutes` property has to be between 1 minute and 1 week.
    EOF
  }
}
