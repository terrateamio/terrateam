variable "aad_tenant_id" {
  type        = string
  description = "The Microsoft Entra tenant id."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.aad_tenant_id))
    error_message = "Must be a valid GUID in the format 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'."
  }
}

variable "arm_client_id" {
  type        = string
  description = "The AppId of the service principal used for authenticating with Azure. Must have an 'Owner' role assignment."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.arm_client_id))
    error_message = "Must be a valid GUID in the format 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'."
  }
}

variable "arm_client_secret" {
  type        = string
  description = "The password for the service principal used for authenticating with Azure. Set interactively or using an environment variable 'TF_VAR_arm_client_secret'."
  sensitive   = true

  validation {
    condition     = length(var.arm_client_secret) >= 8
    error_message = "Must be at least 8 characters long."
  }
}

# variable "enable_module_ai_foundry" {
#   type        = bool
#   description = "Set to true to enable the AI Foundry module, false to skip it."
#   default     = false
# }

variable "enable_module_avd" {
  type        = bool
  description = "Set to true to enable the Azure Virtual Desktop (AVD) module, false to skip it."
  default     = false
}

variable "enable_module_mssql" {
  type        = bool
  description = "Set to true to enable the Azure SQL Database (mssql) module, false to skip it."
  default     = false

}

variable "enable_module_mysql" {
  type        = bool
  description = "Set to true to enable the Azure Database for MySQL (mysql) module, false to skip it."
  default     = false

}

variable "enable_module_petstore" {
  type        = bool
  description = "Set to true to enable the petstore module, false to skip it."
  default     = false
}

# variable "enable_module_vm_devops_win" {
#   type        = bool
#   description = "Set to true to enable the vm_devops_win module, false to skip it."
#   default     = false

# }

variable "enable_module_vm_jumpbox_linux" {
  type        = bool
  description = "Set to true to enable the vm_jumpbox_linux module, false to skip it."
  default     = false
}

variable "enable_module_vm_mssql_win" {
  type        = bool
  description = "Set to true to enable the vm_mssql_win module, false to skip it."
  default     = false
}

variable "enable_module_vnet_app" {
  type        = bool
  description = "Set to true to enable the vnet_app module, false to skip it."
  default     = false
}

# variable "enable_module_vnet_onprem" {
#   type        = bool
#   description = "Set to true to enable the vnet_onprem module, false to skip it."
#   default     = false
# }

variable "enable_module_vwan" {
  type        = bool
  description = "Set to true to enable the vwan module, false to skip it."
  default     = false

}

variable "location" {
  type        = string
  description = "The name of the Azure Region where resources will be provisioned."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "Must be a valid Azure region name. It should only contain lowercase letters, numbers, and dashes."
  }
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription id used to provision resources."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Must be a valid GUID in the format 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'."
  }
}

variable "tags" {
  type        = map(any)
  description = "The tags in map format to be used when creating new resources."
  default     = { costcenter = "mycostcenter", environment = "dev", project = "sand" }

  validation {
    condition = alltrue([
      for key, value in var.tags :
      can(regex("^[a-zA-Z0-9._-]{1,512}$", key)) &&
      can(regex("^[a-zA-Z0-9._ -]{0,256}$", value))
    ])
    error_message = "Each tag key must be 1-512 characters long and consist of alphanumeric characters, periods (.), underscores (_), or hyphens (-). Each tag value must be 0-256 characters long and consist of alphanumeric characters, periods (.), underscores (_), spaces, or hyphens (-)."
  }
}

variable "user_name" {
  type        = string
  description = "The user name of the user in Microsoft Entra ID."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]@[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.user_name))
    error_message = "Must be a valid User Principal Name (UPN) format like 'user@domain.com'. The username part must start and end with alphanumeric characters and can contain periods (.), underscores (_), or hyphens (-). The domain must be a valid domain name."
  }
}

variable "user_object_id" {
  type        = string
  description = "The object id of the user in Microsoft Entra ID."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.user_object_id))
    error_message = "Must be a valid GUID in the format 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'."
  }
}
