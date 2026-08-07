variable "admin_password" {
  type        = string
  description = "The password for the local administrator account on the virtual machine"
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12 && length(var.admin_password) <= 123
    error_message = "Must be between 12 and 123 characters long."
  }
}

variable "admin_username" {
  type        = string
  description = "The username for the local administrator account on the virtual machine"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,20}$", var.admin_username))
    error_message = "Must be 1-20 characters and contain only alphanumeric characters, underscores, or hyphens."
  }
}

variable "configuration_zip_url" {
  type        = string
  description = "The URL of the configuration zip file used to install the agent"
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02790.438.zip"

  validation {
    condition     = can(regex("^https?://.*\\.zip$", var.configuration_zip_url))
    error_message = "Must be a valid HTTP or HTTPS URL ending with .zip."
  }
}

variable "location" {
  type        = string
  description = "Region where the resources will be created"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "Must be a valid Azure region name. It should only contain lowercase letters, numbers, and dashes (e.g., 'eastus', 'westus2', 'centralus')."
  }
}

variable "resource_group_id" {
  type        = string
  description = "ID of the resource group"

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+$", var.resource_group_id))
    error_message = "Must be a valid Azure Resource ID for a resource group. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}'."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "Must conform to Azure resource group naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), parentheses (()), and hyphens (-), and must be between 1 and 90 characters long."
  }
}

variable "security_principal_object_ids" {
  type        = list(string)
  description = "The object IDs of the Security Principals to assign to AVD Application groups"

  validation {
    condition = alltrue([
      for id in var.security_principal_object_ids :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))
    ])
    error_message = "All object IDs must be valid GUIDs in the format 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'."
  }
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet for the session host network interface"

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Network/virtualNetworks/[a-zA-Z0-9-_]+/subnets/[a-zA-Z0-9-_]+$", var.subnet_id))
    error_message = "Must be a valid Azure Resource ID for a subnet. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"

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

variable "vm_image_sku" {
  type        = string
  description = "Gallery image SKU for the session host VMs"
  default     = "win11-24h2-avd-m365"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_image_sku))
    error_message = "Must conform to Azure Marketplace image SKU naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_name_personal" {
  type        = string
  description = "Name of the personal desktop session host virtual machine"
  default     = "sessionhost1"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_name_personal))
    error_message = "Must be 1-15 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "vm_name_remoteapp" {
  type        = string
  description = "Name of the RemoteApp session host virtual machine"
  default     = "sessionhost2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_name_remoteapp))
    error_message = "Must be 1-15 characters and contain only alphanumeric characters and hyphens."
  }
}

variable "vm_size" {
  type        = string
  description = "The size of the session host VMs"
  default     = "Standard_D4ds_v4"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.vm_size))
    error_message = "Must conform to Azure virtual machine size naming conventions: it can only contain alphanumeric characters and underscores (_). Examples include 'Standard_DS1_v2' or 'Standard_B2ms'."
  }
}
