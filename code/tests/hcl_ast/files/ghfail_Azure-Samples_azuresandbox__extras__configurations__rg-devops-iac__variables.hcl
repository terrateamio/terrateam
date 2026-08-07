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
  description = "The AppId of the service principal used for authenticating with Azure. Must have a 'Contributor' role assignment."

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

variable "location" {
  type        = string
  description = "The name of the Azure Region where resources will be provisioned."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "Must be a valid Azure region name. It should only contain lowercase letters, numbers, and dashes."
  }
}

variable "storage_access_tier" {
  type        = string
  description = "The access tier for the new storage account."
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool", "Archive"], var.storage_access_tier)
    error_message = "storage_access_tier must be one of: Hot, Cool, or Archive (case-sensitive, as per Azure Blob Storage access tiers)."
  }
}

variable "storage_replication_type" {
  type        = string
  description = "The type of replication for the new storage account."
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "storage_replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS (case-sensitive, as per Azure Storage replication types)."
  }
}

variable "subnet_address_prefix" {
  type        = string
  description = "The address prefix for the miscellaneous subnet."
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet to be created in the new virtual network."
  default     = "snet-devops-01"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,64}$", var.subnet_name))
    error_message = "Must conform to Azure subnet naming standards: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 64 characters long."
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

variable "storage_container_name" {
  type        = string
  description = "The name of the storage container to be created in the new storage account."
  default     = "tfstate"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,61}[a-z0-9]$", var.storage_container_name))
    error_message = "Must conform to Azure storage container naming standards: it can only contain lowercase alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 3 and 63 characters long."
  }
}

variable "tags" {
  type        = map(any)
  description = "The tags in map format to be used when creating new resources."
  default     = { costcenter = "mycostcenter", environment = "dev", project = "devops" }

  validation {
    condition = alltrue([
      for key, value in var.tags :
      can(regex("^[a-zA-Z0-9._-]{1,512}$", key)) &&
      can(regex("^[a-zA-Z0-9._ -]{0,256}$", value))
    ])
    error_message = "Each tag key must be 1-512 characters long and consist of alphanumeric characters, periods (.), underscores (_), or hyphens (-). Each tag value must be 0-256 characters long and consist of alphanumeric characters, periods (.), underscores (_), spaces, or hyphens (-)."
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

variable "vnet_address_space" {
  type        = string
  description = "The address space in CIDR notation for the new virtual network."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "vnet_name" {
  type        = string
  description = "The name of the new virtual network to be provisioned."
  default     = "devops"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,64}$", var.vnet_name))
    error_message = "Must conform to Azure virtual network naming standards: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 64 characters long."
  }
}
