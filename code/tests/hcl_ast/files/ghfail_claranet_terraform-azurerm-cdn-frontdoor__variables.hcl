#---------
# Common
variable "client_name" {
  description = "Client name/account used in naming."
  type        = string
}

variable "environment" {
  description = "Project environment."
  type        = string
}

variable "stack" {
  description = "Project stack name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

# ------------------
# CDN FrontDoor Profile
variable "sku_name" {
  description = "Specifies the SKU for this Azure CDN FrontDoor profile. Possible values include `Standard_AzureFrontDoor` and `Premium_AzureFrontDoor`."
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "response_timeout_seconds" {
  description = "Specifies the maximum response timeout in seconds. Possible values are between `16` and `240` seconds (inclusive)."
  type        = number
  default     = 120
}

variable "identity" {
  description = "Managed identity configuration. SystemAssigned or UserAssigned or Both."
  type = object({
    type         = optional(string, "SystemAssigned")
    identity_ids = optional(list(string))
  })
  default = {}
}

# ------------------
# CDN FrontDoor Endpoint
variable "endpoints" {
  description = "Azure CDN FrontDoor endpoints configurations."
  type = list(object({
    name                 = string
    prefix               = optional(string)
    custom_resource_name = optional(string)
    enabled              = optional(bool, true)
  }))
  default = []
}

# ------------------
# CDN FrontDoor Origin Groups
variable "origin_groups" {
  description = "Azure CDN FrontDoor origin groups configurations."
  type = list(object({
    name                                                      = string
    custom_resource_name                                      = optional(string)
    session_affinity_enabled                                  = optional(bool, true)
    restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)
    health_probe = optional(object({
      interval_in_seconds = number
      path                = string
      protocol            = string
      request_type        = string
    }))
    load_balancing = optional(object({
      additional_latency_in_milliseconds = optional(number, 50)
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
    }), {})
  }))
  default = []
}

# ------------------
# CDN FrontDoor Origins
variable "origins" {
  description = "Azure CDN FrontDoor origins configurations."
  type = list(object({
    name                           = string
    custom_resource_name           = optional(string)
    origin_group_name              = string
    enabled                        = optional(bool, true)
    certificate_name_check_enabled = optional(bool, true)

    host_name          = string
    http_port          = optional(number, 80)
    https_port         = optional(number, 443)
    origin_host_header = optional(string)
    priority           = optional(number, 1)
    weight             = optional(number, 1)

    private_link = optional(object({
      request_message        = optional(string)
      target_type            = optional(string)
      location               = string
      private_link_target_id = string
    }))
  }))
  default = []
}

# ------------------
# CDN FrontDoor Custom Domains
variable "custom_domains" {
  description = "Azure CDN FrontDoor custom domains configurations."
  type = list(object({
    name                 = string
    custom_resource_name = optional(string)
    host_name            = string
    dns_zone_id          = optional(string)
    tls = optional(object({
      certificate_type         = optional(string, "ManagedCertificate")
      minimum_tls_version      = optional(string, "TLS12")
      cdn_frontdoor_secret_id  = optional(string)
      key_vault_certificate_id = optional(string)
    }), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for custom_domain in var.custom_domains :
      can(regex("^[a-zA-Z0-9][0-9A-Za-z-]*[a-zA-Z0-9]$", custom_domain.name)) &&
      length(custom_domain.name) >= 2 &&
      length(custom_domain.name) <= 260
    ])
    error_message = "Custom domain names must be between 2 and 260 characters in length, must begin with a letter or number, end with a letter or number and contain only letters, numbers and hyphens."
  }
}

# ------------------
# CDN FrontDoor Routes
variable "routes" {
  description = "Azure CDN FrontDoor routes configurations."
  type = list(object({
    name                 = string
    custom_resource_name = optional(string)
    enabled              = optional(bool, true)

    endpoint_name     = string
    origin_group_name = string
    origins_names     = list(string)

    forwarding_protocol = optional(string, "HttpsOnly")
    patterns_to_match   = optional(list(string), ["/*"])
    supported_protocols = optional(list(string), ["Http", "Https"])
    cache = optional(object({
      query_string_caching_behavior = optional(string, "IgnoreQueryString")
      query_strings                 = optional(list(string))
      compression_enabled           = optional(bool, false)
      content_types_to_compress     = optional(list(string))
    }))

    custom_domains_names = optional(list(string), [])
    origin_path          = optional(string, "/")
    rule_sets_names      = optional(list(string), [])

    https_redirect_enabled = optional(bool, true)
    link_to_default_domain = optional(bool, true)
  }))
  default = []
}

# ------------------
# CDN FrontDoor Rule Sets + Rules
variable "rule_sets" {
  description = "Azure CDN FrontDoor rule sets and associated rules configurations."
  type = list(object({
    name                 = string
    custom_resource_name = optional(string)
    rules = optional(list(object({
      name                 = string
      custom_resource_name = optional(string)
      order                = number
      behavior_on_match    = optional(string, "Continue")

      actions = object({
        url_rewrite_actions = optional(list(object({
          source_pattern          = optional(string)
          destination             = optional(string)
          preserve_unmatched_path = optional(bool, false)
        })), [])
        url_redirect_actions = optional(list(object({
          redirect_type        = string
          destination_hostname = string
          redirect_protocol    = optional(string, "MatchRequest")
          destination_path     = optional(string, "")
          query_string         = optional(string, "")
          destination_fragment = optional(string, "")
        })), [])
        route_configuration_override_actions = optional(list(object({
          cache_duration                  = optional(string)
          cdn_frontdoor_origin_group_id   = optional(string)
          cdn_frontdoor_origin_group_name = optional(string)
          forwarding_protocol             = optional(string, "MatchRequest")
          query_string_caching_behavior   = optional(string)
          query_string_parameters         = optional(list(string))
          compression_enabled             = optional(bool, false)
          cache_behavior                  = optional(string)
        })), [])
        request_header_actions = optional(list(object({
          header_action = string
          header_name   = string
          value         = optional(string)
        })), [])
        response_header_actions = optional(list(object({
          header_action = string
          header_name   = string
          value         = optional(string)
        })), [])
      })

      conditions = optional(object({
        remote_address_conditions = optional(list(object({
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
        })), [])
        request_method_conditions = optional(list(object({
          match_values     = list(string)
          operator         = optional(string, "Equal")
          negate_condition = optional(bool, false)
        })), [])
        query_string_conditions = optional(list(object({
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        post_args_conditions = optional(list(object({
          post_args_name   = string
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        request_uri_conditions = optional(list(object({
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        request_header_conditions = optional(list(object({
          header_name      = string
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        request_body_conditions = optional(list(object({
          operator         = string
          match_values     = list(string)
          negate_condition = optional(bool, false)
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        request_scheme_conditions = optional(list(object({
          operator         = optional(string, "Equal")
          negate_condition = optional(bool, false)
          match_values     = optional(string, "HTTP")
        })), [])
        url_path_conditions = optional(list(object({
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        url_file_extension_conditions = optional(list(object({
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = list(string)
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        url_filename_conditions = optional(list(object({
          operator         = string
          match_values     = list(string)
          negate_condition = optional(bool, false)
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        http_version_conditions = optional(list(object({
          match_values     = list(string)
          operator         = optional(string, "Equal")
          negate_condition = optional(bool, false)
        })), [])
        cookies_conditions = optional(list(object({
          cookie_name      = string
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
          transforms       = optional(list(string), ["Lowercase"])
        })), [])
        is_device_conditions = optional(list(object({
          operator         = optional(string, "Equal")
          negate_condition = optional(bool, false)
          match_values     = optional(list(string), ["Mobile"])
        })), [])
        socket_address_conditions = optional(list(object({
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
        })), [])
        client_port_conditions = optional(list(object({
          operator         = string
          negate_condition = optional(bool, false)
          match_values     = optional(list(string))
        })), [])
        server_port_conditions = optional(list(object({
          operator         = string
          match_values     = list(string)
          negate_condition = optional(bool, false)
        })), [])
        host_name_conditions = optional(list(object({
          operator     = string
          match_values = optional(list(string))
          transforms   = optional(list(string), ["Lowercase"])
        })), [])
        ssl_protocol_conditions = optional(list(object({
          match_values     = list(string)
          operator         = optional(string, "Equal")
          negate_condition = optional(bool, false)
        })), [])
      }), null)
    })), [])
  }))
  default = []
}

# ------------------
# CDN FrontDoor Firewall Policies
variable "firewall_policies" {
  description = "Azure CDN Frontdoor firewall policies configurations."
  type = list(object({
    name                              = string
    custom_resource_name              = optional(string)
    enabled                           = optional(bool, true)
    mode                              = optional(string, "Prevention")
    redirect_url                      = optional(string)
    custom_block_response_status_code = optional(number)
    custom_block_response_body        = optional(string)
    custom_rules = optional(list(object({
      name                           = string
      action                         = string
      enabled                        = optional(bool, true)
      priority                       = number
      type                           = string
      rate_limit_duration_in_minutes = optional(number, 1)
      rate_limit_threshold           = optional(number, 10)
      match_conditions = list(object({
        match_variable   = string
        match_values     = list(string)
        operator         = string
        selector         = optional(string)
        negate_condition = optional(bool)
        transforms       = optional(list(string), [])
      }))
    })), [])
    managed_rules = optional(list(object({
      type    = string
      version = optional(string, "1.0")
      action  = string
      exclusions = optional(list(object({
        match_variable = string
        operator       = string
        selector       = string
      })), [])
      overrides = optional(list(object({
        rule_group_name = string
        exclusions = optional(list(object({
          match_variable = string
          operator       = string
          selector       = string
        })), [])
        rules = optional(list(object({
          rule_id = string
          action  = string
          enabled = optional(bool, true)
          exclusions = optional(list(object({
            match_variable = string
            operator       = string
            selector       = string
        })), []) })), [])
      })), [])
    })), [])
  }))
  default = []
}

# ------------------
# CDN FrontDoor Security Policies
variable "security_policies" {
  description = "Azure CDN FrontDoor security policies configurations."
  type = list(object({
    name                 = string
    custom_resource_name = optional(string)
    firewall_policy_name = string
    patterns_to_match    = optional(list(string), ["/*"])
    custom_domain_names  = optional(list(string), [])
    endpoint_names       = optional(list(string), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for security_policy in var.security_policies :
      security_policy.custom_domain_names != null ||
      security_policy.endpoint_names != null
    ])
    error_message = "At least one custom domain name or endpoint name must be provided for all the security policies."
  }
}
