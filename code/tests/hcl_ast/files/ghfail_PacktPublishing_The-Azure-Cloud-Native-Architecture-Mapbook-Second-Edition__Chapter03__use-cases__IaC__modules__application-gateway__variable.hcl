variable "resource_group_name" {
  type        = string
  description = "The name for the resource group"
}

variable "resource_group_location" {
  type        = string
  description = "The location of the resource group"
}

variable "application_gateway_name" {
  type        = string
  description = "The name of the application gateway"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
}

variable "frontend_ports" {
  type = list(object
    (
      {
        name = string
        port = number
      }
    )
  )
  description = "Name and port number of the frontend port"
  default     = null
}

variable "frontend_ip_configurations" {
  description = "The frontend ip configurations"
  type = list(object(
    {
      name                          = string
      public_ip_address_id          = string
      subnet_id                     = string
      private_ip_address            = string
      private_ip_address_allocation = string
    }
  ))
}

variable "backend_addresses" {
  type = list(object
    (
      {
        name      = string
        addresses = optional(list(string))
        fqdns = optional(list(string))
      }
    )
  )
  description = "Name and IP address of the backend pool"
  default     = null
}

variable "backend_settings" {
  type = list(object
    (
      {
        name                   = string
        cookie_based_affinity  = string
        port                   = number
        protocol               = string
        request_timeout        = number
        probe                  = string
        hostname               = string
        root_certificate_names = optional(list(string))
      }
    )
  )
  description = "Settings of the backend http"
  default     = null
}

variable "probes" {
  type = list(object
    (
      {
        name     = string
        protocol = string
        path = string
      }
    )
  )
  description = "The backend health check probe"
  default     = []
}

variable "http_listeners" {
  type = list(object(
    {
      name                      = string
      frontend_ip_configuration = string
      frontend_port_name        = string
      protocol                  = string
      hostname                  = optional(string)
      ssl_certificate_name      = optional(string)
      firewall_policy_id        = optional(string)
    }
    )
  )
  description = "Http listener settings"
  default     = []
}

variable "routing_rules" {
  type = list(object
    (
      {
        name                       = string
        rule_type                  = string
        priority                   = number
        #url_path_map_name          = string
        http_listener_name         = string
        backend_address_pool_name  = string
        backend_http_settings_name = string
        url_path_map_name          = optional(string)
      }
    )
  )
  description = "Routing rules settings"
  default     = []
}

variable "path_maps" {
  default = []
  type = list(object
    (
      {
        name        = string
        backend     = string
        backend_set = string
        upm = list(object
          (
            {
              name_rule   = string
              paths       = list(string)
              backend     = string
              backend_set = string
            }
          )
        )
      }
    )
  )
  description = "URL path map settings"
}

# variable "http_setting_name" {
#   type        = string
#   default     = "myHTTPsetting"
#   description = "Name of the HTTP settings"
# }

# variable "listener_name" {
#   type        = string
#   default     = "myListener"
#   description = "Name of the listener"
# }

# variable "request_routing_rule_name" {
#   type        = string
#   default     = "myRoutingRule"
#   description = "Name of the routing rule"
# }




# variable "ssl_certificate_name" {
#   type        = string
#   description = "Name of the SSL certificate"
# }

# variable "key_vault_private_certificate_id" {
#   type        = string
#   description = "ID of the private certificate for SSL"
# }

# variable "trusted_root_certificate_name" {
#   type        = string
#   description = "Name of the trusted root certificate"
# }

# variable "trusted_root_certificate_data" {
#   type        = string
#   description = "Data in the trusted root certificate"
# }

# variable "min_capacity" {
#   type        = number
#   description = "The AGW minimum capacity."
# }

# variable "max_capacity" {
#   type        = number
#   description = "The AGW maximum capacity."
# }

variable "tags" {
  description = "Tags to apply to the resource."
  type        = map(string)
  default     = {}
}