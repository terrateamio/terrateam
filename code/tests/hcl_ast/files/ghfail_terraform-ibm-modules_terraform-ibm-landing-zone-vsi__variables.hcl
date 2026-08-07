##############################################################################
# Account Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of resource group to create VSI and block storage volumes. If you wish to create the block storage volumes in a different resource group, you can optionally set that directly in the 'block_storage_volumes' variable."
  type        = string
}

variable "prefix" {
  description = "The prefix to add to all resources created by this module."
  type        = string

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "tags" {
  description = "List of tags to apply to resources created by this module."
  type        = list(string)
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the VSI resources created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\". For more information, see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits."
  }
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable "vpc_id" {
  description = "ID of VPC"
  type        = string
}

variable "subnets" {
  description = "A list of subnet IDs where VSI will be deployed"
  type = list(
    object({
      name = string
      id   = string
      zone = string
      cidr = optional(string)
    })
  )
}

##############################################################################


##############################################################################
# VSI Variables
##############################################################################

variable "image_id" {
  description = "Image ID used for VSI. Run 'ibmcloud is images' to find available images in a region. Required if not passing a value for `catalog_offering`."
  type        = string
  default     = null

  validation {
    condition     = (var.image_id != null && var.catalog_offering != null) == false
    error_message = "image_id and catalog_offering are mutually exclusive, you can only use one of these options to specify an image, you must set one of these to `null`."
  }

  validation {
    condition     = var.boot_volume_snapshot_crn != null ? true : (var.image_id == null && var.catalog_offering == null) == false
    error_message = "You must specify one (and only one) of either `image_id`, `catalog_offering`, or `boot_volume_snapshot_crn` for your virtual server OS image."
  }
}

variable "catalog_offering" {
  description = "The catalog offering or offering version to use when provisioning this virtual server instance. If an offering is specified, the latest version of that offering will be used."
  type = object({
    offering_crn = optional(string)
    version_crn  = optional(string)
    plan_crn     = optional(string)
  })
  default = null

  validation {
    condition     = var.catalog_offering != null ? (var.catalog_offering.offering_crn == null && var.catalog_offering.version_crn == null) == false : true
    error_message = "Must supply either an `offering_crn` or `version_crn` for a catalog_offering."
  }

  validation {
    condition     = var.catalog_offering != null ? (var.catalog_offering.offering_crn != null && var.catalog_offering.version_crn != null) == false : true
    error_message = "`catalog_offering.offering_crn` and `catalog_offering.version_crn` of a catalog_offering are mutually exclusive. You must supply only one of these two values."
  }
}

variable "ssh_key_ids" {
  description = "ssh key ids to use in creating vsi"
  type        = list(string)
}

variable "machine_type" {
  description = "VSI machine type. Run 'ibmcloud is instance-profiles' to get a list of regional profiles"
  type        = string
}

variable "vsi_per_subnet" {
  description = "Number of VSI instances for each subnet"
  type        = number
}

variable "user_data" {
  description = "User data to initialize VSI deployment"
  type        = string
}

variable "use_boot_volume_key_as_default" {
  description = "Set to true to use the key specified in the `boot_volume_encryption_key` input as default for all volumes, overriding any key value that may be specified in the `encryption_key` option of the `block_storage_volumes` input variable. If set to `false`,  the value passed for the `encryption_key` option of the `block_storage_volumes` will be used instead."
  type        = bool
  default     = false
}

variable "boot_volume_encryption_key" {
  description = "CRN of boot volume encryption key"
  default     = null
  type        = string
}

variable "boot_volume_size" {
  description = "The capacity of the volume in gigabytes. This defaults to minimum capacity of the image and maximum to 250 GB"
  default     = null
  type        = number

  validation {
    condition     = var.boot_volume_size != null ? var.boot_volume_size >= 100 && var.boot_volume_size <= 250 : true
    error_message = "Boot Volume size must be a number between 100 and 250"
  }
}

variable "boot_volume_profile" {
  description = "The Block Volume Storage Profile to use for the boot volume of the virtual instance, defaults to `general-purpose`."
  type        = string
  default     = null

  validation {
    condition     = var.boot_volume_profile != null ? contains(["general-purpose", "sdp"], var.boot_volume_profile) : true
    error_message = "Boot Volume Profile must be `general-purpose` or `sdp`"
  }
}

variable "boot_volume_iops" {
  description = "NOTE: custom IOPS value only available for `sdp` volume profile! The custom IOPS value, in GB/s, for the `sdp` boot storage profile."
  type        = number
  default     = null

  validation {
    condition     = var.boot_volume_iops != null ? var.boot_volume_profile == "sdp" : true
    error_message = "Boot Volume IOPS can only be specified for `boot_volume_profile = sdp`."
  }

  validation {
    condition     = var.boot_volume_iops != null ? var.boot_volume_iops >= 100 && var.boot_volume_iops <= 64000 : true
    error_message = "Boot Volume IOPS for sdp profile must be between 100 and 64,000"
  }
}

variable "manage_reserved_ips" {
  description = "Set to `true` if you want this terraform module to manage the reserved IP addresses that are assigned to VSI instances. If this option is enabled, when any VSI is recreated it should retain its original IP."
  type        = bool
  default     = false
}

variable "primary_vni_additional_ip_count" {
  description = "The number of secondary reversed IPs to attach to a Virtual Network Interface (VNI). Additional IPs are created only if `manage_reserved_ips` is set to true."
  type        = number
  nullable    = false
  default     = 0
}

variable "use_static_boot_volume_name" {
  description = "Sets the boot volume name for each VSI to a static name in the format `{hostname}_boot`, instead of a random name. Set this to `true` to have a consistent boot volume name even when VSIs are recreated."
  type        = bool
  default     = false
}

variable "enable_floating_ip" {
  description = "Create a floating IP for each virtual server created"
  type        = bool
  default     = false
}

variable "allow_ip_spoofing" {
  description = "Allow IP spoofing on the primary network interface"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Create security group for VSI. If this is passed as false, the default will be used"
  type        = bool
}

variable "placement_group_id" {
  description = "Unique Identifier of the Placement Group for restricting the placement of the instance, default behaviour is placement on any host"
  type        = string
  default     = null
}

variable "security_group" {
  description = "Security group created for VSI"
  type = object({
    name = string
    rules = list(
      object({
        name       = string
        direction  = string
        source     = string
        local      = optional(string)
        ip_version = optional(string)
        tcp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        udp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        icmp = optional(
          object({
            type = number
            code = number
          })
        )
      })
    )
  })

  validation {
    error_message = "Each security group rule must have a unique name."
    condition = (
      var.security_group == null
      ? true
      : length(distinct(var.security_group.rules[*].name)) == length(var.security_group.rules[*].name)
    )
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = var.security_group == null ? true : length(
      distinct(
        flatten([
          for rule in var.security_group.rules :
          false if !contains(["inbound", "outbound"], rule.direction)
        ])
      )
    ) == 0
  }
  default = null
}

variable "security_group_ids" {
  description = "IDs of additional security groups to be added to VSI deployment primary interface. A VSI interface can have a maximum of 5 security groups."
  type        = list(string)
  default     = []

  validation {
    error_message = "Security group IDs must be unique."
    condition     = length(var.security_group_ids) == length(distinct(var.security_group_ids))
  }

  validation {
    error_message = "No more than 5 security groups can be added to a VSI deployment."
    condition     = length(var.security_group_ids) <= 5
  }
}

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that for the block storage volumes for VPC. If set to false, the data is encrypted by using randomly generated keys. For more info on encrypting block storage volumes, see https://cloud.ibm.com/docs/vpc?topic=vpc-creating-instances-byok"
  default     = false
  nullable    = false

  validation {
    condition     = !var.kms_encryption_enabled && var.boot_volume_encryption_key != null ? false : true
    error_message = "When passing values for var.boot_volume_encryption_key, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption"
  }

  validation {
    condition     = var.kms_encryption_enabled && var.boot_volume_encryption_key == null ? false : true
    error_message = "When setting var.kms_encryption_enabled to true, a value must be passed for var.boot_volume_encryption_key"
  }

  validation {
    condition     = var.kms_encryption_enabled && var.skip_iam_authorization_policy == false && var.boot_volume_encryption_key == null ? false : true
    error_message = "When var.skip_iam_authorization_policy is set to false, and var.kms_encryption_enabled to true, a value must be passed for var.boot_volume_encryption_key in order to create the auth policy."
  }
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Storage Blocks to read the encryption key from the KMS instance. If set to false, pass in a value for the boot volume encryption key in the `boot_volume_encryption_key` variable. In addition, no policy is created if var.kms_encryption_enabled is set to false."
  default     = false
}

variable "block_storage_volumes" {
  description = "List describing the block storage volumes that will be attached to each vsi"
  type = list(
    object({
      name              = string
      profile           = string
      capacity          = optional(number)
      iops              = optional(number)
      encryption_key    = optional(string)
      resource_group_id = optional(string)
      snapshot_crn      = optional(string) # set if you would like to base volume on a snapshot. If you plan to use a snapshot from another account, make sure that the right [IAM authorizations](https://cloud.ibm.com/docs/vpc?topic=vpc-block-s2s-auth&interface=terraform#block-s2s-auth-xaccountrestore-terraform) are in place.
      tags              = optional(list(string), [])
    })
  )
  default = []

  validation {
    error_message = "Each block storage volume must have a unique name."
    condition     = length(distinct(var.block_storage_volumes[*].name)) == length(var.block_storage_volumes)
  }
}

variable "load_balancers" {
  description = "Load balancers to add to VSI"
  type = list(
    object({
      name                       = string
      type                       = string
      listener_port              = optional(number)
      listener_port_max          = optional(number)
      listener_port_min          = optional(number)
      listener_protocol          = string
      connection_limit           = optional(number)
      idle_connection_timeout    = optional(number)
      algorithm                  = string
      protocol                   = string
      health_delay               = number
      health_retries             = number
      health_timeout             = number
      health_type                = string
      pool_member_port           = string
      profile                    = optional(string)
      accept_proxy_protocol      = optional(bool)
      subnet_id_to_provision_nlb = optional(string) # Required for Network Load Balancer. If no value is provided, the first one from the VPC subnet list will be selected.
      dns = optional(
        object({
          instance_crn = string
          zone_id      = string
        })
      )
      security_group = optional(
        object({
          name = string
          rules = list(
            object({
              name      = string
              direction = string
              source    = string
              tcp = optional(
                object({
                  port_max = number
                  port_min = number
                })
              )
              udp = optional(
                object({
                  port_max = number
                  port_min = number
                })
              )
              icmp = optional(
                object({
                  type = number
                  code = number
                })
              )
            })
          )
        })
      )
    })
  )
  default = []

  validation {
    error_message = "Load balancer names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = length(distinct(
      flatten([
        # Check through rules
        for load_balancer in var.load_balancers :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", load_balancer.name))
      ])
    )) == 0
  }

  validation {
    error_message = "Load balancer idle_connection_timeout must be between 50 and 7200."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        load_balancer.idle_connection_timeout != null ?
        (load_balancer.idle_connection_timeout < 50 || load_balancer.idle_connection_timeout > 7200) ? [true] : []
        : []
      ])
    ) == 0
  }


  validation {
    error_message = "Load Balancer Pool algorithm can only be `round_robin`, `weighted_round_robin`, or `least_connections`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["round_robin", "weighted_round_robin", "least_connections"], load_balancer.algorithm)
      ])
    ) == 0
  }

  validation {
    error_message = "Load Balancer Pool Protocol can only be `http`, `https`, or `tcp`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["http", "https", "tcp"], load_balancer.protocol)
      ])
    ) == 0
  }

  validation {
    error_message = "Pool health delay must be greater than the timeout."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if load_balancer.health_delay < load_balancer.health_timeout
      ])
    ) == 0
  }

  validation {
    error_message = "Load Balancer Pool Health Check Type can only be `http`, `https`, or `tcp`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["http", "https", "tcp"], load_balancer.health_type)
      ])
    ) == 0
  }

  validation {
    error_message = "Each load balancer must have a unique name."
    condition     = length(distinct(var.load_balancers[*].name)) == length(var.load_balancers[*].name)
  }

  validation {
    error_message = "Application load balancer connection_limit can not be null."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        load_balancer.profile != "network-fixed" ?
        (load_balancer.connection_limit == null) ? [true] : []
        : []
      ])
    ) == 0
  }

  validation {
    error_message = "Application load balancer listener_port can not be null."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        load_balancer.profile != "network-fixed" ?
        (load_balancer.listener_port == null) ? [true] : []
        : []
      ])
    ) == 0
  }
}

variable "custom_vsi_volume_names" {
  description = "A map of subnets, VSI names, and storage volume names. Subnet names should correspond to existing subnets, while VSI and storage volume names are used for resource creation. Example format: { 'subnet_name_1': { 'vsi_name_1': [ 'storage_volume_name_1', 'storage_volume_name_2' ] } }. If the 'custom_vsi_volume_names' input variable is not set, VSI and volume names are automatically determined using a prefix, the first 4 digits of the subnet_id, and number padding. In addition, for volume names, the name from the 'block_storage_volumes' input variable is also used."
  type        = map(map(list(string)))
  default     = {}
  nullable    = false

  # Validation to ensure the map has the same number of volumes as the number of block storage volumes defined in 'block_storage_volumes'
  validation {
    condition = alltrue([
      for subnet_key, subnet_value in coalesce(var.custom_vsi_volume_names, {}) : alltrue([
        for vsi_key, volumes in subnet_value : length(volumes) == length(var.block_storage_volumes)
      ])
    ])
    error_message = "The number of storage volume names must be the same as the number of block storage volumes defined in 'block_storage_volumes' input variable."
  }

  # Validation to ensure that volume names are unique
  validation {
    condition = alltrue([
      for subnet, vsi_map in var.custom_vsi_volume_names :
      alltrue([
        for vsi_name, volumes in vsi_map :
        length(volumes) == length(distinct(volumes))
      ])
    ])
    error_message = "Each member of a list of storage volume names for a vsi_name must be unique."
  }

  # Validation to ensure that number of subnets is not higher than the number of subnets defined in var.subnets
  validation {
    condition     = length(keys(var.custom_vsi_volume_names)) <= length(var.subnets)
    error_message = "The number of subnets defined in the custom_vsi_volume_names input variable should not exceed the number of subnets defined in the subnets input variable."
  }

  # Validation to ensure that number of VSIs is not higher then the number defined in vsi_per_subnet
  validation {
    condition     = length(var.custom_vsi_volume_names) > 0 ? sort([for subnet, vsis in var.custom_vsi_volume_names : length(keys(vsis))])[length([for subnet, vsis in var.custom_vsi_volume_names : length(keys(vsis))]) - 1] <= var.vsi_per_subnet : true
    error_message = "The number of VSIs defined in the custom_vsi_volume_names input variable should not exceed the number specified in the vsi_per_subnet input variable."
  }

  # Validation to ensure the VSI names are unique across different subnets
  validation {
    condition = length(distinct(flatten([
      for subnet, vsi_map in var.custom_vsi_volume_names : [
        for vsi_name, _ in vsi_map : vsi_name
      ]
      ]))) == length(flatten([
      for subnet, vsi_map in var.custom_vsi_volume_names : [
        for vsi_name, _ in vsi_map : vsi_name
      ]
    ]))
    error_message = "VSI names must be unique across all subnets."
  }
}

##############################################################################

##############################################################################
# Secondary Interface Variables
##############################################################################

variable "secondary_subnets" {
  description = "List of secondary network interfaces to add to vsi secondary subnets must be in the same zone as VSI. This is only recommended for use with a deployment of 1 VSI."
  type = list(
    object({
      name = string
      id   = string
      zone = string
      cidr = optional(string)
    })
  )
  default = []
}

variable "secondary_use_vsi_security_group" {
  description = "Use the security group created by this module in the secondary interface"
  type        = bool
  default     = false
}

variable "secondary_security_groups" {
  description = "The security group IDs to add to the VSI deployment secondary interfaces (5 maximum). Use the same value for interface_name as for name in secondary_subnets to avoid applying the default VPC security group on the secondary network interface."
  type = list(
    object({
      security_group_id = string
      interface_name    = string
    })
  )
  default = []

  validation {
    error_message = "Security group IDs must be unique."
    condition     = length(var.secondary_security_groups) == length(distinct(var.secondary_security_groups))
  }
}

variable "secondary_floating_ips" {
  description = "List of secondary interfaces to add floating ips"
  type        = list(string)
  default     = []

  validation {
    error_message = "Secondary floating IPs must contain a unique list of interfaces."
    condition     = length(var.secondary_floating_ips) == length(distinct(var.secondary_floating_ips))
  }
}

variable "secondary_allow_ip_spoofing" {
  description = "Allow IP spoofing on additional network interfaces"
  type        = bool
  default     = false
}

##############################################################################

##############################################################################
# Snapshot Restore Variables
##############################################################################

variable "boot_volume_snapshot_crn" {
  description = "The snapshot CRN of the volume to be used for creating boot volume attachment (if specified, the `image_id` parameter will not be used). If you plan to use a snapshot from another account, make sure that the right [IAM authorizations](https://cloud.ibm.com/docs/vpc?topic=vpc-block-s2s-auth&interface=terraform#block-s2s-auth-xaccountrestore-terraform) are in place."
  type        = string
  default     = null
}

variable "snapshot_consistency_group_id" {
  description = "The snapshot consistency group id. If supplied, the group will be queried for snapshots that are matched with both boot volume and attached (attached are matched based on name suffix). You can override specific snapshot CRNs by setting the appropriate input variables as well."
  type        = string
  default     = null
}

##############################################################################

variable "use_legacy_network_interface" {
  description = "Set this to true to use legacy network interface for the created instances."
  type        = bool
  nullable    = false
  default     = false
}

##############################################################################
# Dedicated Host Variables
##############################################################################

variable "enable_dedicated_host" {
  type        = bool
  default     = false
  nullable    = false
  description = "Enabling this option will activate dedicated hosts for the VSIs. When enabled, the dedicated_host_id input is required. The default value is set to false. Refer [Understanding Dedicated Hosts](https://cloud.ibm.com/docs/vpc?topic=vpc-creating-dedicated-hosts-instances&interface=ui#about-dedicated-hosts) for more details"
}

variable "dedicated_host_id" {
  type        = string
  default     = null
  description = "ID of the dedicated host for hosting the VSI's. The enable_dedicated_host input should be set to true if passing a dedicated host ID"

  validation {
    condition     = var.enable_dedicated_host == false || (var.enable_dedicated_host == true && var.dedicated_host_id != null)
    error_message = "When enable_dedicated_host is set to true, provide a valid dedicated_host_id."
  }
}

##############################################################################
# Logging Agent Variables
##############################################################################

variable "install_logging_agent" {
  type        = bool
  default     = false
  description = "Set to true to enable installing the logging agent into your VSI at time of creation. If true, values must be passed for `logging_target_host` and either `logging_api_key` or `logging_trusted_profile_id`. Installation logs can be found on the VSI in /run/monitoring-agent/monitoring-agent-install.log."

  validation {
    condition     = var.install_logging_agent ? var.image_id != null : true
    error_message = "When 'install_logging_agent' is true, a value for 'image_id' must be provided. Logging agent installations are not supported if provisioning using the 'catalog_offering' option."
  }

  validation {
    condition     = var.install_logging_agent ? var.logging_agent_version != null && var.logging_agent_version != "" : true
    error_message = "When 'install_logging_agent' is true, a value for 'logging_agent_version' must be provided."
  }

  validation {
    condition     = var.install_logging_agent ? local.package_name != "" : true
    error_message = "The module currently does not support installing the Logging agent on ${local.os_image}. Currently only supports debian, ubuntu and redhat."
  }

  validation {
    condition     = var.install_logging_agent ? var.logging_target_port != null && var.logging_target_port != "" : true
    error_message = "If 'install_logging_agent' is true, a value for 'logging_target_port' must be provided."
  }

  validation {
    condition     = var.install_logging_agent ? var.logging_target_host != null && var.logging_target_host != "" : true
    error_message = "If 'install_logging_agent' is true, a value for 'logging_target_host' must be provided."
  }

}

variable "logging_agent_version" {
  type        = string
  default     = "1.8.0" # datasource: icr.io/ibm-observe/logs-agent-helm
  description = "Version of the logging agent to install. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-release-notes-agent for list of versions. Only applies if `install_logging_agent` is true."
}

variable "logging_target_host" {
  type        = string
  default     = null
  description = "Ingestion endpoint that corresponds to the IBM Cloud Logs instance the logging agent connects to."
}

variable "logging_target_port" {
  type        = number
  default     = 443
  description = "Port the logging agent targets when sending logs, defaults to `443` for sending logs to an IBM Cloud Logs instance."
}

variable "logging_target_path" {
  type        = string
  default     = "/logs/v1/singles"
  description = "Path the logging agent targets when sending logs, defaults to `/logs/v1/singles` for sending logs to an IBM Cloud Logs instance."

  validation {
    condition     = var.install_logging_agent ? var.logging_target_path != null && var.logging_target_path != "" : true
    error_message = "If 'install_logging_agent' is true, a value for 'logging_target_path' must be provided."
  }
}

variable "logging_auth_mode" {
  type        = string
  default     = "IAMAPIKey"
  description = "Authentication mode the logging agent to use to authenticate with IBM Cloud, must be either `IAMAPIKey` or `VSITrustedProfile`."

  validation {
    condition     = length(regex("IAMAPIKey|VSITrustedProfile", var.logging_auth_mode)) > 0
    error_message = "Value for `logging_auth_mode` must be either `IAMAPIKey` or `VSITrustedProfile`."
  }
}

variable "logging_api_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "API key used by the logging agent to authenticate with IBM Cloud, must be provided if `logging_auth_mode` is set to `IAMAPIKey`. For more information on creating an API key for the logging agent, see https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-iam-ingestion-serviceid-api-key."

  validation {
    condition     = var.install_logging_agent && var.logging_auth_mode == "IAMAPIKey" ? var.logging_api_key != null : true
    error_message = "Value for `logging_api_key` must be provided when `logging_auth_mode` is set to `IAMAPIKey`."
  }
}

variable "logging_trusted_profile_id" {
  type        = string
  default     = null
  description = "Trusted Profile used by the logging agent to access the IBM Cloud Logs instance, must be provided if `logging_auth_mode` is set to `VSITrustedProfile`."

  validation {
    condition     = var.install_logging_agent && var.logging_auth_mode == "VSITrustedProfile" ? var.logging_trusted_profile_id != null : true
    error_message = "Value for `logging_trusted_profile_id` must be provided when `logging_auth_mode` is set to `VSITrustedProfile`."
  }
}

variable "logging_use_private_endpoint" {
  type        = bool
  default     = true
  description = "Specifies whether a public or private endpoint is used by the logging agent for IAM authentication."
}

variable "logging_secure_access_enabled" {
  type        = bool
  default     = false
  description = "Set this to true if you have secure access enabled in your VSI. Only applies if 'install_logging_agent' is true."
}

variable "logging_application_name" {
  type        = bool
  default     = null
  description = "The application name defines the environment that produces and sends logs to IBM Cloud Logs. If not provided, the value defaults to `$HOSTNAME`."
}

variable "logging_subsystem_name" {
  type        = bool
  default     = null
  description = "The subsystem name is the service or application that produces and sends logs to IBM Cloud Logs. If not provided, the value defaults to `not-found`."
}

########################################################################################################################
# Monitoring Agent Variables
########################################################################################################################

variable "install_monitoring_agent" {
  type        = bool
  default     = false
  description = "Set to true to install the IBM Cloud Monitoring agent on the provisioned VSI to gather both metrics and security and compliance data. If set to true, values must be passed for `monitoring_access_key`, `monitoring_collector_endpoint` and `monitoring_collector_port`. Installation logs can be found on the VSI in /run/logging-agent/logs-agent-install.log"

  validation {
    condition     = var.install_monitoring_agent ? var.image_id != null : true
    error_message = "When 'install_monitoring_agent' is true, a value for 'image_id' must be provided. Monitoring agent installations are not supported if provisioning using the 'catalog_offering' option."
  }

  validation {
    condition     = var.install_monitoring_agent ? local.monitoring_kernel_header_install_cmd != "" : true
    error_message = "This module currently does not support installing the Monitoring agent on ${local.os_image}. Currently only supports centos, federo, debian, ubuntu and redhat."
  }
}

variable "monitoring_agent_version" {
  type        = string
  default     = "14.5.0" # datasource: icr.io/ext/sysdig/agent-slim
  description = "Version of the monitoring agent to install. See https://docs.sysdig.com/en/release-notes/linux-host-shield-release-notes for list of versions. Only applies if `install_monitoring_agent` is true. Pass `null` to use latest."
}

variable "monitoring_access_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Access key used by the IBM Cloud Monitoring agent to successfully forward data to your IBM Cloud Monitoring and SCC Workload Protection instance. Required if `install_monitoring_agent` is true. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-access_key)."

  validation {
    condition     = var.install_monitoring_agent ? var.monitoring_access_key != null && var.monitoring_access_key != "" : true
    error_message = "Value for `monitoring_access_key` must be provided when `install_monitoring_agent` is true."
  }
}

variable "monitoring_collector_endpoint" {
  type        = string
  default     = null
  description = "Endpoint that the IBM Cloud Monitoring agent will forward data to. Required if `install_monitoring_agent` is true. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-endpoints#endpoints_ingestion)."

  validation {
    condition     = var.install_monitoring_agent ? var.monitoring_collector_endpoint != null && var.monitoring_collector_endpoint != "" : true
    error_message = "Value for `monitoring_collector_endpoint` must be provided when `install_monitoring_agent` is true."
  }
}

variable "monitoring_collector_port" {
  type        = number
  default     = 6443
  description = "Port the agent targets when sending metrics or compliance data, defaults to `6443`."

  validation {
    condition     = var.install_monitoring_agent ? var.monitoring_collector_port != null && var.monitoring_collector_port != "" : true
    error_message = "Value for `monitoring_collector_port` must be provided when `install_monitoring_agent` is true."
  }
}

variable "monitoring_tags" {
  type        = list(string)
  default     = []
  description = "A list of tags in the form of `TAG_NAME:TAG_VALUE` to associate with the agent."
}

########################################################################################################################
