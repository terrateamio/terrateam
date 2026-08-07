variable "location" {
  type        = string
  description = "The name of the Azure Region where resources will be provisioned."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "The 'location' must be a valid Azure region name. It should only contain lowercase letters, numbers, and dashes (e.g., 'eastus', 'westus2', 'centralus')."
  }
}

variable "mssql_database_name" {
  type        = string
  description = "The name of the Azure SQL Database to be provisioned."
  default     = "testdb"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,128}$", var.mssql_database_name))
    error_message = "The 'mssql_database_name' must conform to Azure SQL Database naming requirements: it can only contain alphanumeric characters, underscores (_), and hyphens (-), and must be between 1 and 128 characters long."
  }
}

variable "private_dns_zone_id" {
  type        = string
  description = "The resource ID of the existing Private DNS Zone to link with the Private Endpoint."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Network/privateDnsZones/[a-zA-Z0-9._()-]+$", var.private_dns_zone_id))
    error_message = "Must be a valid Azure Resource ID for a Private DNS Zone. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{zoneName}'."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the existing resource group for provisioning resources."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "Must conform to Azure resource group naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), parentheses (()), and hyphens (-), and must be between 1 and 90 characters long."
  }
}

variable "sql_admin_login_name" {
  type        = string
  description = "The display name of the Entra ID group to be set as the SQL server administrator."

  validation {
    condition     = length(var.sql_admin_login_name) > 0 && length(var.sql_admin_login_name) <= 256
    error_message = "Must be a non-empty string with a maximum length of 256 characters."
  }
}

variable "sql_admin_object_id" {
  type        = string
  description = "The object ID of the Entra ID group to be set as the SQL server administrator."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.sql_admin_object_id))
    error_message = "Must be a valid GUID in the format 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'."
  }
}

variable "subnet_id" {
  type        = string
  description = "The ID of the existing subnet where the nic will be provisioned."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Network/virtualNetworks/[a-zA-Z0-9-_()]+/subnets/[a-zA-Z0-9-_()]+$", var.subnet_id))
    error_message = "Must be a valid Azure Resource ID for a subnet. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'."
  }
}

variable "tags" {
  type        = map(any)
  description = "The tags in map format to be used when creating new resources."

  validation {
    condition = alltrue([
      for key, value in var.tags :
      can(regex("^[a-zA-Z0-9._-]{1,512}$", key)) &&
      can(regex("^[a-zA-Z0-9._ -]{0,256}$", value))
    ])
    error_message = "Each tag key must be 1-512 characters long and consist of alphanumeric characters, periods (.), underscores (_), or hyphens (-). Each tag value must be 0-256 characters long and consist of alphanumeric characters, periods (.), underscores (_), spaces, or hyphens (-)."
  }
}

variable "unique_seed" {
  type        = string
  description = "A unique seed to be used for generating unique names for resources. This should be a string that is unique to the environment or deployment."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,64}$", var.unique_seed))
    error_message = "Must only contain alphanumeric characters and hyphens (-), and must be between 1 and 32 characters long."
  }
}
