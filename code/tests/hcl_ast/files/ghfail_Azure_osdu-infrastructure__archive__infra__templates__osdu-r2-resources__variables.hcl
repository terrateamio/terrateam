//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

// ---- General Configuration ----

variable "prefix" {
  description = "An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 8
}

variable "resource_group_location" {
  description = "The Azure region where all resources in this template should be created."
  type        = string
}

variable "app_services" {
  description = "Descriptions of the app services to be deployed. Service level config settings can be provided with the required attribute app_settings"
  type = list(object({
    app_name         = string
    image            = string
    linux_fx_version = string
    app_command_line = string
    app_settings     = map(string)
  }))
}

variable "function_apps" {
  description = "Descriptions of the function apps to be deployed. This template supports function app containers when the image attribute for a configuration entry is provided."
  type = list(object({
    function_name = string
    app_settings  = map(string)
  }))
}

variable "app_service_settings" {
  description = "Map of app settings that will be applied across all provisioned app services."
  type        = map(string)
  default     = {}
}

variable "scaling_rules" {
  description = "The scaling rules for the app service plan. Schema defined here: https://www.terraform.io/docs/providers/azurerm/r/monitor_autoscale_setting.html#rule. Note, the appropriate resource ID will be auto-inflated by the template"
  type = list(object({
    metric_trigger = object({
      metric_name      = string
      time_grain       = string
      statistic        = string
      time_window      = string
      time_aggregation = string
      operator         = string
      threshold        = number
    })
    scale_action = object({
      direction = string
      type      = string
      cooldown  = string
      value     = number
    })
  }))
  default = [
    {
      metric_trigger = {
        metric_name      = "CpuPercentage"
        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT5M"
        time_aggregation = "Average"
        operator         = "GreaterThan"
        threshold        = 70
      }
      scale_action = {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT10M"
      }
      }, {
      metric_trigger = {
        metric_name      = "CpuPercentage"
        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT5M"
        time_aggregation = "Average"
        operator         = "LessThan"
        threshold        = 25
      }
      scale_action = {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }
  ]
}

variable "service_plan_size" {
  description = "The size of the service plan instance."
  type        = string
  default     = "P3v2"
}

variable "service_plan_tier" {
  description = "The tier under which the service plan is created."
  type        = string
  default     = "PremiumV2"
}

variable "auth_suffix" {
  description = "A name to be appended to all azure ad applications."
  type        = string
  default     = "easy-auth"
}

variable "container_registry_sku" {
  description = "The container registry SKU. ie. 'Standard' 'Premium'"
  type        = string
  default     = "Standard"
}



variable "storage_containers" {
  description = "The list of storage container names to create. Names must be unique per storage account."
  type        = list(string)
}

variable "cosmosdb_replica_location" {
  description = "The name of the Azure region to host replicated data. i.e. 'East US' 'East US 2'. More locations can be found at https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  type        = string
}

variable "cosmosdb_automatic_failover" {
  description = "Determines if automatic failover is enabled for CosmosDB."
  type        = bool
  default     = true
}

variable "cosmos_databases" {
  description = "The list of Cosmos DB SQL Databases."
  type = list(object({
    name       = string
    throughput = number
  }))
  default = []
}

variable "cosmos_sql_collections" {
  description = "The list of cosmos collection names to create. Names must be unique per cosmos instance."
  type = list(object({
    name               = string
    database_name      = string
    partition_key_path = string
    throughput         = number
  }))
  default = []
}

###
# Begin: Elasticsearch configuration
###

variable "elasticsearch_username" {
  type        = string
  description = "username for elasticsearch cluster"
}

variable "elasticsearch_password" {
  type        = string
  description = "password for elasticsearch cluster"
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "endpoint for elasticsearch cluster"
}

###
# End: Elasticsearch configuration
###

###
# Begin: Service Bus configuration
###

variable "sb_sku" {
  type        = string
  default     = "Standard"
  description = "The SKU of the namespace. The options are: `Basic`, `Standard`, `Premium`."
}

variable "sb_topics" {
  type = list(object({
    name                         = string
    default_message_ttl          = string //ISO 8601 format
    enable_partitioning          = bool
    requires_duplicate_detection = bool
    support_ordering             = bool
    authorization_rules = list(object({
      policy_name = string
      claims      = object({ listen = bool, manage = bool, send = bool })

    }))
    subscriptions = list(object({
      name                                 = string
      max_delivery_count                   = number
      lock_duration                        = string //ISO 8601 format
      forward_to                           = string //set with the topic name that will be used for forwarding. Otherwise, set to ""
      dead_lettering_on_message_expiration = bool
      filter_type                          = string // SqlFilter is the only supported type now.
      sql_filter                           = string //Required when filter_type is set to SqlFilter
      action                               = string
    }))
  }))
  default = [
    {
      name                         = "storage_topic"
      default_message_ttl          = "PT30M" //ISO 8601 format
      enable_partitioning          = true
      requires_duplicate_detection = true
      support_ordering             = true
      authorization_rules = [
        {
          policy_name = "storage_policy"
          claims = {
            listen = true
            send   = false
            manage = false
          }
        }
      ]
      subscriptions = [
        {
          name                                 = "storage_sub_1"
          max_delivery_count                   = 1
          lock_duration                        = "PT5M" //ISO 8601 format
          forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
          dead_lettering_on_message_expiration = true
          filter_type                          = "SqlFilter"     // SqlFilter is the only supported type now.
          sql_filter                           = "color = 'red'" //Required when filter_type is set to SqlFilter
          action                               = ""
        },
        {
          name                                 = "storage_sub_2"
          max_delivery_count                   = 1
          lock_duration                        = "PT5M" //ISO 8601 format
          forward_to                           = ""     //set with the topic name that will be used for forwarding. Otherwise, set to ""
          dead_lettering_on_message_expiration = true
          filter_type                          = "SqlFilter"      // SqlFilter is the only supported type now.
          sql_filter                           = "color = 'blue'" //Required when filter_type is set to SqlFilter
          action                               = ""
        }
      ]
    }
  ]
}

###
# End: Service Bus configuration
###
