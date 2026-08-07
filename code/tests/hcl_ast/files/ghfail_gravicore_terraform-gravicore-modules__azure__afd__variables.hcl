# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = "afd"
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/azure/afd"
  description = "The owner and name of the Terraform module"
}

variable "afd_region" {
  type        = string
  default     = "global"
  description = "The Azure region to deploy module into"
}

variable "az_region" {
  type        = string
  default     = "global"
  description = "The Azure region to deploy module into"
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the Azure resource group"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

# Recommended

variable "namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. Gravicore 'grv', HashiCorp 'hc')"
}

variable "environment" {
  type        = string
  default     = ""
  description = "The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`)"
}

variable "stage" {
  type        = string
  default     = ""
  description = "The development stage (i.e. `dev`, `stg`, `prd`)"
}

variable "application" {
  type        = string
  default     = ""
  description = "The application name (i.e. `apex`, `portal`)"
}

variable "repository" {
  type        = string
  default     = ""
  description = "The repository where the code referencing the module is stored"
}

# Optional

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional map of tags (e.g. business_unit, cost_center)"
}

variable "desc_prefix" {
  type        = string
  default     = "Grvc:"
  description = "The prefix to add to any descriptions attached to resources"
}

variable "environment_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace` and `environment`"
}

variable "stage_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment` and `stage`"
}

variable "module_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment`, `stage` and `name`"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name`"
}

locals {
  environment_prefix = coalesce(var.environment_prefix, join(var.delimiter, compact([var.namespace, var.environment])))
  stage_prefix       = coalesce(var.stage_prefix, join(var.delimiter, compact([local.environment_prefix, var.stage])))
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.application, var.afd_region, var.name])))

  business_tags = {
    namespace          = var.namespace
    environment        = var.environment
    environment_prefix = local.environment_prefix
  }
  technical_tags = {
    stage      = var.stage
    module     = var.name
    repository = var.repository
    region     = var.afd_region
  }
  automation_tags = {
    terraform_module = var.terraform_module
    stage_prefix     = local.stage_prefix
    module_prefix    = local.module_prefix
  }
  security_tags = {}

  tags = merge(
    local.business_tags,
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    var.tags
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Variables
# ----------------------------------------------------------------------------------------------------------------------

# ------------------
# CDN FrontDoor Profile

variable "sku_name" {
  description = "Specifies the SKU for this CDN FrontDoor Profile. Possible values include `Standard_AzureFrontDoor` and `Premium_AzureFrontDoor`."
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "response_timeout_seconds" {
  description = "Specifies the maximum response timeout in seconds. Possible values are between `16` and `240` seconds (inclusive)."
  type        = number
  default     = 120
}

# ------------------
# CDN FrontDoor Endpoint
variable "endpoints" {
  description = "CDN FrontDoor Endpoints configurations."
  type = list(object({
    name    = string
    enabled = optional(bool, true)
  }))
  default = []
}

# ------------------
# CDN FrontDoor Origin Groups
variable "origin_groups" {
  description = "CDN FrontDoor Origin Groups configurations."
  type = list(object({
    name                                                      = string
    session_affinity_enabled                                  = optional(bool, true)
    restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)
    health_probe = optional(object({
      interval_in_seconds = optional(number, 10)
      path                = string
      protocol            = optional(string, "Https")
      request_type        = optional(string, "GET")
    }))
    load_balancing = optional(object({
      additional_latency_in_milliseconds = optional(number, 50)
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
    }))
  }))
  default = []
}

# ------------------
# CDN FrontDoor Origins
variable "origins" {
  description = "CDN FrontDoor Origins configurations."
  type = list(object({
    name                           = string
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
      request_message        = optional(string, "Request access for Private Link Origin CDN Frontdoor")
      target_type            = optional(string)
      location               = string
      private_link_target_id = string
    }))
  }))
  default = []
}

locals {
  private_link_ids = [for origin in var.origins : origin.private_link != null ? origin.private_link.private_link_target_id : ""]
}

# ------------------
# CDN FrontDoor Custom Domains
variable "custom_domains" {
  description = "CDN FrontDoor Custom Domains configurations."
  type = list(object({
    name        = string
    host_name   = string
    dns_zone_id = optional(string)
    tls = optional(object({
      certificate_type        = optional(string, "ManagedCertificate")
      minimum_tls_version     = optional(string, "TLS12")
      cdn_frontdoor_secret_id = optional(string)
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
  description = "CDN FrontDoor Routes configurations."
  type = list(object({
    name    = string
    enabled = optional(bool, true)

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
  description = "CDN FrontDoor Rule Sets and associated Rules configurations."
  type = list(object({
    name = string
    rules = optional(list(object({
      name              = string
      order             = number
      behavior_on_match = optional(string, "Continue")

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
          cache_duration                = optional(string, "1.12:00:00")
          cdn_frontdoor_origin_group_id = optional(string)
          forwarding_protocol           = optional(string, "MatchRequest")
          query_string_caching_behavior = optional(string, "IgnoreQueryString")
          query_string_parameters       = optional(list(string))
          compression_enabled           = optional(bool, false)
          cache_behavior                = optional(string, "HonorOrigin")
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
# CDN FrontDoor logging
variable "logs_destinations_ids" {
  type        = list(string)
  default     = []
  description = "List of destination resources IDs for logs diagnostic destination."
}

# ------------------
# CDN FrontDoor Firewall Policies
variable "firewall_policies" {
  description = "CDN Frontdoor Firewall Policies configurations."
  type = list(object({
    name                              = string
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
        match_variable     = string
        match_values       = list(string)
        operator           = string
        selector           = optional(string)
        negation_condition = optional(bool)
        transforms         = optional(list(string), [])
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
  description = "CDN FrontDoor Security policies configurations."
  type = list(object({
    name                 = string
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

locals {
  origins_names_per_route = {
    for route in var.routes : route.name => [
      for origin in route.origins_names : azurerm_cdn_frontdoor_origin.default[origin].id
    ]
  }

  custom_domains_per_route = {
    for route in var.routes : route.name => [
      for cd in route.custom_domains_names : azurerm_cdn_frontdoor_custom_domain.default[cd].id
    ]
  }

  rule_sets_per_route = {
    for route in var.routes : route.name => [
      for rs in route.rule_sets_names : azurerm_cdn_frontdoor_rule_set.default[rs].id
    ]
  }

  rules_per_rule_set = flatten([
    for rule_set in var.rule_sets : [
      for rule in rule_set.rules : merge({ rule_set_name = rule_set.name }, rule)
    ]
  ])
}


variable "metric_alerts" {
  description = "List of metric alerts to create"
  type        = any
  default     = {}
}

variable "activity_log_alerts" {
  description = "List of activity log alerts to create"
  type        = any
  default     = {}
}

variable "action_group" {
  description = "Action group to use for alerts"
  type        = any
  default     = {}
}

variable "scheduled_query_rules_alerts" {
  description = "List of scheduled query rules alerts to create"
  type        = any
  default     = {}
}

