variable "name" {
  description = "The name of the Application Gateway."
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

variable "subnet_id" {
  description = "An ID of a subnet (must be dedicated to Application Gateway v2) that will host the Application Gateway."
  type        = string
}

variable "zones" {
  description = <<-EOF
  A list of zones the Application Gateway should be available in. For non-zonal deployments this should be set to an empty list,
  as `null` will enforce the default value.

  **Note!** \
  This is also enforced on the Public IP. The Public IP object brings in some limitations as it can only be non-zonal, pinned to
  a single zone or zone-redundant (so available in all zones in a region).

  Therefore make sure that if you specify more than one zone you specify all available in a region. You can use a subset, but the
  Public IP will be created in all zones anyway. This fact will cause Terraform to recreate the IP resource during next 
  `terraform apply` as there will be difference between the state and the actual configuration.

  For details on zones currently available in a region of your choice refer to
  [Microsoft's documentation](https://docs.microsoft.com/en-us/azure/availability-zones/az-region).
  EOF
  default     = ["1", "2", "3"]
  type        = list(string)
}

variable "public_ip" {
  description = <<-EOF
  A map defining listener's public IP configuration.

  Following properties are available:
  - `create`              - (`bool`, optional, defaults to `true`) controls if the Public IP resource is created or sourced.
  - `name`                - (`string`, optional) name of the Public IP resource, required unless `public_ip` module and `id`
                            property are used.
  - `resource_group_name` - (`string`, optional, defaults to `null`) name of the Resource Group hosting the Public IP resource, 
                            used only for sourced resources.
  - `id`                  - (`string`, optional, defaults to `null`) ID of the Public IP to associate with the Listener. 
                            Property is used when Public IP is not created or sourced within this module.
  EOF
  type = object({
    create              = optional(bool, true)
    name                = optional(string)
    resource_group_name = optional(string)
    id                  = optional(string)
  })
  validation { # id, name
    condition     = var.public_ip.name != null || var.public_ip.id != null
    error_message = <<-EOF
    Either `name` or `id` property must be set.
    EOF
  }
  validation { # id, create, name
    condition = var.public_ip != null ? (
      var.public_ip.id != null ? var.public_ip.create == false && var.public_ip.name == null : true
    ) : true
    error_message = <<-EOF
    When using `id` property, `create` must be set to `false` and `name` must not be set.
    EOF
  }
}

variable "domain_name_label" {
  description = <<-EOF
  A label for the Domain Name. Will be used to make up the FQDN. 
  If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system.
  EOF
  default     = null
  type        = string
}

variable "capacity" {
  description = <<-EOF
  A map defining whether static or autoscale configuration is used.
  
  Following properties are available:
  - `static`    - (`number`, optional, defaults to `2`) static number of Application Gateway instances, takes values bewteen 1 
                  and 125.
  - `autoscale` - (`map`, optional, defaults to `null`) autoscaling configuration, when specified `static` is being ignored:
    - `min` - (`number`, required) minimum number of instances during autoscaling.
    - `max` - (`number`, required) maximum number of instances during autoscaling.
  EOF
  default     = {}
  nullable    = false
  type = object({
    static = optional(number, 2)
    autoscale = optional(object({
      min = number
      max = number
    }))
  })
  validation { # static
    condition     = var.capacity.static >= 1 && var.capacity.static <= 125
    error_message = <<-EOF
    The `capacity.static` property can take values between 1 and 125.
    EOF
  }
  validation { # autoscale
    condition = var.capacity.autoscale == null ? true : (
      (
        var.capacity.autoscale.min >= 1 && var.capacity.autoscale.min <= 125
        ) && (
        var.capacity.autoscale.max >= 1 && var.capacity.autoscale.max <= 125
        ) && (
        var.capacity.autoscale.min < var.capacity.autoscale.max
      )
    )
    error_message = <<-EOF
    The `min` and `max` properties of the `capacity.autoscale` property can take values between 1 and 125 and `min` value has to
    be lower then `max`.
    EOF
  }
}

variable "enable_http2" {
  description = "Enable HTTP2 on the Application Gateway."
  default     = false
  type        = bool
}

variable "waf" {
  description = <<-EOF
  A map defining only the SKU and providing basic WAF (Web Application Firewall) configuration for Application Gateway. This
  module does not support WAF rules configuration and advanced WAF settings.

  Following properties are available:
  - `prevention_mode`  - (`bool`, required) `true` sets WAF mode to `Prevention` mode, `false` to `Detection` mode.
  - `rule_set_type`    - (`string`, optional, defaults to `OWASP`) the type of the Rule Set used for this WAF.
  - `rule_set_version` - (`string`, optional, defaults to Azure defaults) the version of the Rule Set used for this WAF.
  EOF
  default     = null
  type = object({
    prevention_mode  = bool
    rule_set_type    = optional(string, "OWASP")
    rule_set_version = optional(string)
  })
  validation { # rule_set_type
    condition = var.waf == null ? true : contains(
      ["OWASP", "Microsoft_BotManagerRuleSet"],
      var.waf.rule_set_type
    )
    error_message = <<-EOF
    For `waf.rule_set_type` possible values are \"OWASP\" and \"Microsoft_BotManagerRuleSet\".
    EOF
  }
  validation { # rule_set_version
    condition = try(var.waf.rule_set_version, null) == null ? true : contains(
      ["0.1", "1.0", "2.2.9", "3.0", "3.1", "3.2"],
      var.waf.rule_set_version
    )
    error_message = <<-EOF
    The `waf.rule_set_version` property can be one of \"0.1\", \"1.0\", \"2.2.9\", \"3.0\", \"3.1\" or \"3.2\".
    EOF
  }
}

variable "managed_identities" {
  description = <<-EOF
  A list of existing User-Assigned Managed Identities.
  
  **Note!** \
  Application Gateway uses Managed Identities to retrieve certificates from a Key Vault. These identities have to have at least
  `GET` access to Key Vault's secrets. Otherwise Application Gateway will not be able to use certificates stored in the Vault.
  EOF
  default     = null
  type        = list(string)
}

variable "global_ssl_policy" {
  description = <<-EOF
  A map defining global SSL settings.

  Following properties are available:
  - `type`                 - (`string`, required, but defaults to `Predefined`) type of an SSL policy, possible values include:
                             `Predefined`, `Custom` or `CustomV2`.
  - `name`                 - (`string`, optional, defaults to `AppGwSslPolicy20220101S`) name of an SSL policy, supported only
                             for `type` set to `Predefined`.
    
    **Note!** \
    Normally you can set it also for `Custom` policies but the name is discarded on Azure side causing an update to Application
    Gateway each time Terraform code is run. Therefore this property is omitted in the code for `Custom` policies.

    For the `Predefined` policies, check the
    [Microsoft documentation](https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-ssl-policy-overview)
    for possible values as they tend to change over time. The default value is currently (Q1 2023) is also Microsoft's default.

  - `min_protocol_version` - (`string`, optional, defaults to `null`) minimum version of the TLS protocol for SSL Policy, 
                             required only for `type` set to `Custom`.
  - `cipher_suites`        - (`list`, optional, defaults to `[]`) a list of accepted cipher suites, required only for `type` set
                             to `Custom`. For possible values see [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#cipher_suites).
  EOF
  default     = {}
  nullable    = false
  type = object({
    type                 = optional(string, "Predefined")
    name                 = optional(string, "AppGwSslPolicy20220101S")
    min_protocol_version = optional(string)
    cipher_suites        = optional(list(string), [])
  })
  validation { # type
    condition     = contains(["Predefined", "Custom", "CustomV2"], var.global_ssl_policy.type)
    error_message = <<-EOF
    The `global_ssl_policy.type` property can be one of: \"Predefined\", \"Custom\" and \"CustomV2\".
    EOF
  }
  validation { # min_protocol_version
    condition = var.global_ssl_policy.min_protocol_version == null ? true : contains(
      ["TLSv1_0", "TLSv1_1", "TLSv1_2", "TLSv1_3"], var.global_ssl_policy.min_protocol_version
    )
    error_message = <<-EOF
    The `global_ssl_policy.min_protocol_version` property can be one of: \"TLSv1_0\", \"TLSv1_1\", \"TLSv1_2\" and \"TLSv1_3\".
    EOF
  }
  validation { # cipher_suites
    condition = length(setsubtract(var.global_ssl_policy.cipher_suites,
      [
        "TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA", "TLS_DHE_DSS_WITH_AES_128_CBC_SHA", "TLS_DHE_DSS_WITH_AES_128_CBC_SHA256",
        "TLS_DHE_DSS_WITH_AES_256_CBC_SHA", "TLS_DHE_DSS_WITH_AES_256_CBC_SHA256", "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
        "TLS_DHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_DHE_RSA_WITH_AES_256_CBC_SHA", "TLS_DHE_RSA_WITH_AES_256_GCM_SHA384",
        "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA", "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256",
        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA",
        "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
        "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA", "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
        "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA", "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384", "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
        "TLS_RSA_WITH_3DES_EDE_CBC_SHA", "TLS_RSA_WITH_AES_128_CBC_SHA", "TLS_RSA_WITH_AES_128_CBC_SHA256",
        "TLS_RSA_WITH_AES_128_GCM_SHA256", "TLS_RSA_WITH_AES_256_CBC_SHA", "TLS_RSA_WITH_AES_256_CBC_SHA256",
        "TLS_RSA_WITH_AES_256_GCM_SHA384"
      ])
    ) == 0
    error_message = <<-EOF
    For global SSL settings possible cipher suites are: \"TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA\",
    \"TLS_DHE_DSS_WITH_AES_128_CBC_SHA\", \"TLS_DHE_DSS_WITH_AES_128_CBC_SHA256\", \"TLS_DHE_DSS_WITH_AES_256_CBC_SHA\",
    \"TLS_DHE_DSS_WITH_AES_256_CBC_SHA256\", \"TLS_DHE_RSA_WITH_AES_128_CBC_SHA\", \"TLS_DHE_RSA_WITH_AES_128_GCM_SHA256\",
    \"TLS_DHE_RSA_WITH_AES_256_CBC_SHA\", \"TLS_DHE_RSA_WITH_AES_256_GCM_SHA384\", \"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA\",
    \"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256\", \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",
    \"TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA\", \"TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384\",
    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\", \"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA\",
    \"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256\", \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\", \"TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA\",
    \"TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384\", \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\", \"TLS_RSA_WITH_3DES_EDE_CBC_SHA\",
    \"TLS_RSA_WITH_AES_128_CBC_SHA\", \"TLS_RSA_WITH_AES_128_CBC_SHA256\", \"TLS_RSA_WITH_AES_128_GCM_SHA256\",
    \"TLS_RSA_WITH_AES_256_CBC_SHA\", \"TLS_RSA_WITH_AES_256_CBC_SHA256\", \"TLS_RSA_WITH_AES_256_GCM_SHA384\"."
    EOF
  }
}

variable "ssl_profiles" {
  description = <<-EOF
  A map of SSL profiles.

  SSL profiles can be later on referenced in HTTPS listeners by providing a name of the profile in the `name` property.
  For possible values check the: `ssl_policy_type`, `ssl_policy_min_protocol_version` and `ssl_policy_cipher_suites` properties
  as SSL profile is a named SSL policy - same properties apply.
  The only difference is that you cannot name an SSL policy inside an SSL profile.

  Every SSL profile contains following attributes:

  - `name`                            - (`string`, required) name of the SSL profile.
  - `ssl_policy_name`                 - (`string`, optional, defaults to `null`) name of predefined policy.
  - `ssl_policy_min_protocol_version` - (`string`, optional, defaults to `null`) the minimal TLS version.
  - `ssl_policy_cipher_suites`        - (`list`, optional, defaults to `null`) a list of accepted cipher suites.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name                            = string
    ssl_policy_name                 = optional(string)
    ssl_policy_min_protocol_version = optional(string)
    ssl_policy_cipher_suites        = optional(list(string))
  }))
  validation { # name
    condition = (length(flatten([for _, ssl_profile in var.ssl_profiles : ssl_profile.name])) ==
    length(distinct(flatten([for _, ssl_profile in var.ssl_profiles : ssl_profile.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all SSL profiles.
    EOF
  }
  validation { # ssl_policy_min_protocol_version
    condition = alltrue(flatten([
      for _, ssl_profile in var.ssl_profiles :
      contains(["TLSv1_0", "TLSv1_1", "TLSv1_2", "TLSv1_3"], ssl_profile.ssl_policy_min_protocol_version)
      if ssl_profile.ssl_policy_min_protocol_version != null
    ]))
    error_message = <<-EOF
    Possible values for `ssl_policy_min_protocol_version` are TLSv1_0, TLSv1_1, TLSv1_2 and TLSv1_3.
    EOF
  }
  validation { # ssl_policy_cipher_suites
    condition = alltrue(flatten([
      for _, ssl_profile in var.ssl_profiles :
      length(setsubtract(ssl_profile.ssl_policy_cipher_suites,
        [
          "TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA", "TLS_DHE_DSS_WITH_AES_128_CBC_SHA", "TLS_DHE_DSS_WITH_AES_128_CBC_SHA256",
          "TLS_DHE_DSS_WITH_AES_256_CBC_SHA", "TLS_DHE_DSS_WITH_AES_256_CBC_SHA256", "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
          "TLS_DHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_DHE_RSA_WITH_AES_256_CBC_SHA", "TLS_DHE_RSA_WITH_AES_256_GCM_SHA384",
          "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA", "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256",
          "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA",
          "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
          "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA", "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
          "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA", "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384", "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
          "TLS_RSA_WITH_3DES_EDE_CBC_SHA", "TLS_RSA_WITH_AES_128_CBC_SHA", "TLS_RSA_WITH_AES_128_CBC_SHA256",
          "TLS_RSA_WITH_AES_128_GCM_SHA256", "TLS_RSA_WITH_AES_256_CBC_SHA", "TLS_RSA_WITH_AES_256_CBC_SHA256",
          "TLS_RSA_WITH_AES_256_GCM_SHA384"
        ])
      ) == 0
      if ssl_profile.ssl_policy_cipher_suites != null
    ]))
    error_message = <<-EOF
    Possible values for `ssl_policy_cipher_suites` are TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA, TLS_DHE_DSS_WITH_AES_128_CBC_SHA,
    TLS_DHE_DSS_WITH_AES_128_CBC_SHA256, TLS_DHE_DSS_WITH_AES_256_CBC_SHA, TLS_DHE_DSS_WITH_AES_256_CBC_SHA256,
    TLS_DHE_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_RSA_WITH_AES_128_GCM_SHA256, TLS_DHE_RSA_WITH_AES_256_CBC_SHA,
    TLS_DHE_RSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,
    TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,
    TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384, TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,
    TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,
    TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384, TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384, TLS_RSA_WITH_3DES_EDE_CBC_SHA,
    TLS_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA256, TLS_RSA_WITH_AES_128_GCM_SHA256, TLS_RSA_WITH_AES_256_CBC_SHA,
    TLS_RSA_WITH_AES_256_CBC_SHA256 and TLS_RSA_WITH_AES_256_GCM_SHA384.
    EOF
  }
}

variable "frontend_ip_configuration_name" {
  description = "A frontend IP configuration name."
  type        = string
}

variable "listeners" {
  description = <<-EOF
  A map of listeners for the Application Gateway.

  Every listener contains attributes:

  - `name`                     - (`string`, required) the name for this Frontend Port.
  - `port`                     - (`string`, required) the port used for this Frontend Port.
  - `protocol`                 - (`string`, optional, defaults to `Https`) the Protocol to use for this HTTP Listener.
  - `host_names`               - (`list`, optional, defaults to `null`) A list of Hostname(s) should be used for this HTTP 
                                 Listener, it allows special wildcard characters.
  - `ssl_profile_name`         - (`string`, optional, defaults to `null`) the name of the associated SSL Profile which should be
                                 used for this HTTP Listener.
  - `ssl_certificate_vault_id` - (`string`, optional, defaults to `null`) Secret Id of (base-64 encoded unencrypted pfx) Secret
                                 or Certificate object stored in Azure KeyVault.
  - `ssl_certificate_path`     - (`string`, optional, defaults to `null`) Path to the file with tThe base64-encoded PFX
                                 certificate data.
  - `ssl_certificate_pass`     - (`string`, optional, defaults to `null`) Password for the pfx file specified in data.
  - `custom_error_pages`       - (`map`, optional, defaults to `{}`) Map of string, where key is HTTP status code and value is
                                 error page URL of the application gateway customer error.
  EOF
  type = map(object({
    name                     = string
    port                     = number
    protocol                 = optional(string, "Http")
    host_names               = optional(list(string))
    ssl_profile_name         = optional(string)
    ssl_certificate_vault_id = optional(string)
    ssl_certificate_path     = optional(string)
    ssl_certificate_pass     = optional(string)
    custom_error_pages       = optional(map(string), {})
  }))
  validation { # name
    condition = (length(flatten([for _, listener in var.listeners : listener.name])) ==
    length(distinct(flatten([for _, listener in var.listeners : listener.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all listeners.
    EOF
  }
  validation { # port
    condition = alltrue(flatten([
      for _, listener in var.listeners : (listener.port >= 1 && listener.port <= 65535)
    ]))
    error_message = <<-EOF
    The listener `port` should be a valid TCP port number from 1 to 65535.
    EOF
  }
  validation { # protocol
    condition = alltrue(flatten([
      for _, listener in var.listeners : [
        contains(["Http", "Https"], listener.protocol)
    ]]))
    error_message = <<-EOF
    Possible values for `protocol` are `Http` and `Https`.
    EOF
  }
  validation { # ssl_certificate_vault_id & ssl_certificate_path
    condition = alltrue(flatten([
      for _, listener in var.listeners : (listener.protocol == "Https" ?
        try(length(coalesce(listener.ssl_certificate_vault_id, listener.ssl_certificate_path)), -1) > 0
      : true)
    ]))
    error_message = <<-EOF
    If `Https` protocol is used, then SSL certificate (from file or Azure Key Vault) is required.
    EOF
  }
  validation { # ssl_certificate_pass
    condition = alltrue(flatten([
      for _, listener in var.listeners : (listener.protocol == "Https" ?
        try(length(listener.ssl_certificate_pass), -1) >= 0
      : true)
    ]))
    error_message = <<-EOF
    If `Https` protocol is used, then SSL certificate password is required.
    EOF
  }
}

variable "backend_pool" {
  description = <<-EOF
  A map defining a backend pool, when skipped will create an empty backend.
  
  Following properties are available:
  - `name`         - (`string`, optional, defaults to `vmseries`) name of the backend pool.
  - `vmseries_ips` - (`list`, optional, defaults to `[]`) IP addresses of VM-Series' interfaces that will serve as backend nodes
                     for the Application Gateway.

  EOF
  default     = {}
  nullable    = false
  type = object({
    name         = optional(string, "vmseries")
    vmseries_ips = optional(list(string), [])
  })
}

variable "backend_settings" {
  description = <<-EOF
  A map of backend settings for the Application Gateway.

  Every backend contains attributes:

  - `name`                      - (`string`, required) the name of the backend settings.
  - `port`                      - (`number`, required) the port which should be used for this Backend HTTP Settings Collection.
  - `protocol`                  - (`string`, required) the Protocol which should be used. Possible values are Http and Https.
  - `path`                      - (`string`, optional, defaults to `null`) the Path which should be used as a prefix for all HTTP
                                  requests.
  - `hostname_from_backend`     - (`bool`, optional, defaults to `false`) whether host header should be picked from the host name
                                  of the backend server.
  - `hostname`                  - (`string`, optional, defaults to `null`) host header to be sent to the backend servers.
  - `timeout`                   - (`number`, optional, defaults to `60`) the request timeout in seconds, which must be between 1
                                  and 86400 seconds.
  - `use_cookie_based_affinity` - (`bool`, optional, defaults to `true`) when set to `true` enables Cookie-Based Affinity.
  - `affinity_cookie_name`      - (`string`, optional, defaults to Azure defaults) the name of the affinity cookie.
  - `probe_key`                 - (`string`, optional, defaults to `null`) a key identifying a Probe definition in the 
                                  `var.probes`.
  - `root_certs`                - (`map`, optional, defaults to `{}`) a map of objects defining paths to trusted root 
                                  certificates (`PEM` format), each map contains 2 properties:
    - `name` - (`string`, required) a name of the certificate.
    - `path` - (`string`, required) path to a file on a local file system containing the root cert.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name                      = string
    port                      = number
    protocol                  = string
    path                      = optional(string)
    hostname_from_backend     = optional(bool, false)
    hostname                  = optional(string)
    timeout                   = optional(number, 60)
    use_cookie_based_affinity = optional(bool, true)
    affinity_cookie_name      = optional(string)
    probe_key                 = optional(string)
    root_certs = optional(map(object({
      name = string
      path = string
    })), {})
  }))
  validation { # name
    condition = (length(flatten([for _, backend in var.backend_settings : backend.name])) ==
    length(distinct(flatten([for _, backend in var.backend_settings : backend.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all backends.
    EOF
  }
  validation { # port
    condition = alltrue(flatten([
      for _, backend in var.backend_settings : (backend.port >= 1 && backend.port <= 65535)
    ]))
    error_message = <<-EOF
    The backend `port` should be a valid TCP port number from 1 to 65535.
    EOF
  }
  validation { # protocol
    condition = alltrue(flatten([
      for _, backend in var.backend_settings : [
        contains(["Http", "Https"], backend.protocol)
    ]]))
    error_message = <<-EOF
    Possible values for `protocol` are `Http` and `Https`.
    EOF
  }
  validation { # timeout
    condition = alltrue(flatten([
      for _, backend in var.backend_settings : (
        backend.timeout != null ? backend.timeout >= 1 && backend.timeout <= 86400 : true
      )
    ]))
    error_message = <<-EOF
    The backend `timeout` property should can take values between 1 and 86400 (seconds).
    EOF
  }
}

variable "probes" {
  description = <<-EOF
  A map of probes for the Application Gateway.

  Every probe contains attributes:

  - `name`       - (`string`, required) the name used for this Probe.
  - `path`       - (`string`, required) the path used for this Probe.
  - `host`       - (`string`, optional, defaults to `null`) the hostname used for this Probe.
  - `port`       - (`number`, optional, defaults to `null`) custom port which will be used for probing the backend servers, when
                   skipped a default port for `protocol` will be used.
  - `protocol`   - (`string`, optional, defaults `Http`) the protocol which should be used, possible values are `Http` or `Https`.
  - `interval`   - (`number`, optional, defaults `5`) the interval between two consecutive probes in seconds.
  - `timeout`    - (`number`, optional, defaults `30`) the timeout after which a single probe is marked unhealthy.
  - `threshold`  - (`number`, optional, defaults `2`) the unhealthy Threshold for this Probe, which indicates the amount of
                   retries which should be attempted before a node is deemed unhealthy.
  - `match_code` - (`list`, optional, defaults to `null`) custom list of allowed status codes for this Health Probe.
  - `match_body` - (`string`, optional, defaults to `null`) a custom snippet from the Response Body which must be present to 
                   treat a single probe as healthy.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name       = string
    path       = string
    host       = optional(string)
    port       = optional(number)
    protocol   = optional(string, "Http")
    interval   = optional(number, 5)
    timeout    = optional(number, 30)
    threshold  = optional(number, 2)
    match_code = optional(list(number))
    match_body = optional(string)
  }))
  validation { # name
    condition = (length(flatten([for _, probe in var.probes : probe.name])) ==
    length(distinct(flatten([for _, probe in var.probes : probe.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all probes.
    EOF
  }
  validation { # port
    condition = alltrue(flatten([
      for _, probe in var.probes : ((coalesce(probe.port, 80)) >= 1 && (coalesce(probe.port, 80)) <= 65535)
    ]))
    error_message = <<-EOF
    The probe `port` should be a valid TCP port number from 1 to 65535.
    EOF
  }
  validation { # protocol
    condition = alltrue(flatten([
      for _, probe in var.probes : [
        contains(["Http", "Https"], probe.protocol)
    ]]))
    error_message = <<-EOF
    Possible values for `protocol` are `Http` and `Https`.
    EOF
  }
  validation { # interval
    condition = alltrue(flatten([
      for _, probe in var.probes : (probe.interval != null ? probe.interval >= 1 && probe.interval <= 86400 : true)
    ]))
    error_message = <<-EOF
    The probe `interval` property should can take values between 1 and 86400 (seconds).
    EOF
  }
  validation { # timeout
    condition = alltrue(flatten([
      for _, probe in var.probes : (probe.timeout != null ? probe.timeout >= 1 && probe.timeout <= 86400 : true)
    ]))
    error_message = <<-EOF
    The probe `timeout` property should can take values between 1 and 86400 (seconds).
    EOF
  }
  validation { # threshold
    condition = alltrue(flatten([
      for _, probe in var.probes : (probe.threshold != null ? probe.threshold >= 1 && probe.threshold <= 20 : true)
    ]))
    error_message = <<-EOF
    The probe `threshold` property should can take values between 1 and 20.
    EOF
  }
}

variable "rewrites" {
  description = <<-EOF
  A map of rewrites for the Application Gateway.

  Every rewrite contains attributes:

  - `name`  - (`string`, required) Rewrite Rule Set name.
  - `rules` - (`map`, required) rewrite Rule Set defined with following attributes available:
    - `name`             - (`string`, required) Rewrite Rule name.
    - `sequence`         - (`number`, required) determines the order of rule execution in a set.
    - `conditions`       - (`map`, optional, defaults to `{}`) one or more condition blocks as defined below:
      - `pattern`     - (`string`, required) the pattern, either fixed string or regular expression, that evaluates the
                        truthfulness of the condition.
      - `ignore_case` - (`string`, optional, defaults to `false`) perform a case in-sensitive comparison.
      - `negate`      - (`bool`, optional, defaults to `false`) negate the result of the condition evaluation.
    - `request_headers`  - (`map`, optional, defaults to `{}`) map of request headers, where header name is the key, header value
                           is the value.
    - `response_headers` - (`map`, optional, defaults to `{}`) map of response header, where header name is the key, header value
                           is the value.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name = string
    rules = optional(map(object({
      name     = string
      sequence = number
      conditions = optional(map(object({
        pattern     = string
        ignore_case = optional(bool, false)
        negate      = optional(bool, false)
      })), {})
      request_headers  = optional(map(string), {})
      response_headers = optional(map(string), {})
    })), {})
  }))
  validation { # name
    condition = (length(flatten([for _, rewrite in var.rewrites : rewrite.name])) ==
    length(distinct(flatten([for _, rewrite in var.rewrites : rewrite.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all rewrites.
    EOF
  }
}

variable "redirects" {
  description = <<-EOF
  A map of redirects for the Application Gateway.

  Every redirect contains attributes:
  - `name`                 - (`string`, required) the name of redirect.
  - `type`                 - (`string`, required) the type of redirect, possible values are `Permanent`, `Temporary`, `Found` and
                             `SeeOther`.
  - `target_listener_key`  - (`string`, optional, mutually exclusive with `target_url`) a key identifying a backend config
                             defined in `var.listeners`.
  - `target_url`           - (`string`, optional, mutually exclusive with `target_listener`) the URL to redirect to.
  - `include_path`         - (`bool`, optional, defaults to Azure defaults) whether or not to include the path in the redirected
                             URL.
  - `include_query_string` - (`bool`, optional, defaults to Azure defaults) whether or not to include the query string in the
                             redirected URL.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name                 = string
    type                 = string
    target_listener_key  = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool)
    include_query_string = optional(bool)
  }))
  validation { # name
    condition = (length(flatten([for _, redirect in var.redirects : redirect.name])) ==
    length(distinct(flatten([for _, redirect in var.redirects : redirect.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all redirects.
    EOF
  }
  validation { # type
    condition = var.redirects != null ? alltrue(flatten([
      for _, redirect in var.redirects : [
        contains(["Permanent", "Temporary", "Found", "SeeOther"], coalesce(redirect.type, "Permanent"))
    ]])) : true
    error_message = <<-EOF
    Possible values for `type` are \"Permanent\", \"Temporary\", \"Found\" and \"SeeOther\".
    EOF
  }
  validation { # target_listener_key & target_url
    condition = alltrue(flatten([
      for _, r in var.redirects :
      r.target_listener_key != null && r.target_url == null || r.target_listener_key == null && r.target_url != null
    ]))
    error_message = <<-EOF
    At least one and only one property can be defined, either \"target_listener_key\" or \"target_url\".
    EOF
  }
}

variable "url_path_maps" {
  description = <<-EOF
  A map of URL path maps for the Application Gateway.

  Every URL path map contains attributes:
  - `name`         - (`string`, required) the name of redirect.
  - `backend_key`  - (`string`, required) a key identifying the default backend for redirect defined in `var.backend_settings`.
  - `path_rules`   - (`map`, optional, defaults to `{}`) the map of rules, where every object has attributes:
    - `paths`        - (`list`, required) a list of paths.
    - `backend_key`  - (`string`, optional, mutually exclusive with `redirect_key`) a key identifying a backend config defined
                       in `var.backend_settings`.
    - `redirect_key` - (`string`, optional, mutually exclusive with `backend_key`) a key identifying a redirect config defined
                       in `var.redirects`.
  EOF
  default     = {}
  nullable    = false
  type = map(object({
    name        = string
    backend_key = string
    path_rules = optional(map(object({
      paths        = list(string)
      backend_key  = optional(string)
      redirect_key = optional(string)
    })), {})
  }))
  validation { # name
    condition = (length(flatten([for _, url_path_map in var.url_path_maps : url_path_map.name])) ==
    length(distinct(flatten([for _, url_path_map in var.url_path_maps : url_path_map.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all URL path maps.
    EOF
  }
  validation { # path_rules
    condition = alltrue(flatten([
      for _, url in var.url_path_maps : [
        for _, rule in url.path_rules :
        rule.backend_key != null && rule.redirect_key == null || rule.backend_key == null && rule.redirect_key != null
      ]
    ]))
    error_message = <<-EOF
    At least one and only one property can be defined, either \"backend_key\" or \"redirect_key\".
    EOF
  }
}

variable "rules" {
  description = <<-EOF
  A map of rules for the Application Gateway. A rule combines backend's, listener's, rewrites' and redirects' configurations.

  A key is an application name that is used to prefix all components inside an Application Gateway
  that are created for this application.

  Every rule contains following attributes:

  - `name`             - (`string`, required) Rule name.
  - `priority`         - (`string`, required) Rule evaluation order can be dictated by specifying an integer value from 1 to 
                         20000 with 1 being the highest priority and 20000 being the lowest priority.
  - `listener_key`     - (`string`, required) a key identifying a listener config defined in `var.listeners`.
  - `backend_key`      - (`string`, optional, mutually exclusive with `url_path_map_key` and `redirect_key`) a key identifying a
                         backend config defined in `var.backend_settings`.
  - `rewrite_key`      - (`string`, optional, defaults to `null`) a key identifying a rewrite config defined in `var.rewrites`.
  - `url_path_map_key` - (`string`, optional, mutually exclusive with `backend_key` and `redirect_key`) a key identifying a
                         url_path_map config defined in `var.url_path_maps`.
  - `redirect_key`     - (`string`, optional, mutually exclusive with `url_path_map_key` and `backend_key`) a key identifying a
                         redirect config defined in `var.redirects`.
  EOF
  type = map(object({
    name             = string
    priority         = number
    backend_key      = optional(string)
    listener_key     = string
    rewrite_key      = optional(string)
    url_path_map_key = optional(string)
    redirect_key     = optional(string)
  }))
  validation { # name
    condition = (length(flatten([for _, rule in var.rules : rule.name])) ==
    length(distinct(flatten([for _, rule in var.rules : rule.name]))))
    error_message = <<-EOF
    The `name` property has to be unique among all rules.
    EOF
  }
  validation { # priority
    condition = alltrue(flatten([
      for _, rule in var.rules : [
        rule.priority >= 1, rule.priority <= 20000
    ]]))
    error_message = <<-EOF
    The `priority` property is an integer value from 1 to 20000.
    EOF
  }
  validation { # priority
    condition = alltrue([
      for _, v in var.rules :
      !contains(
        concat(
          slice(
            values(var.rules)[*].priority,
            0,
            index(values(var.rules)[*].priority, v.priority)
          ),
          slice(
            values(var.rules)[*].priority,
            index(values(var.rules)[*].priority, v.priority) + 1,
            length(values(var.rules))
          )
        ),
        v.priority
      )
    ])
    error_message = <<-EOF
    The `priority` property has to be unique.
    EOF
  }
  validation { # url_path_map_key
    condition = alltrue([for _, rule in var.rules :
      rule.backend_key != null && rule.redirect_key == null && rule.url_path_map_key == null ||
      rule.backend_key == null && rule.redirect_key != null && rule.url_path_map_key == null ||
      rule.backend_key == null && rule.redirect_key == null && rule.url_path_map_key != null
    ])
    error_message = <<-EOF
    Either `backend`, `redirect` or `url_path_map` is required, but not all as they are mutually exclusive.
    EOF
  }
}
