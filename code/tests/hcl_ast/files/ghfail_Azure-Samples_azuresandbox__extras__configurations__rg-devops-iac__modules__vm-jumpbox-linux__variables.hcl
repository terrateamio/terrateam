variable "admin_username" {
  type        = string
  description = "The administrator username for the virtual machine"
  default     = "devopsbootstrapadmin"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{1,64}$", var.admin_username))
    error_message = "Must conform to Azure VM admin username requirements: it can only contain alphanumeric characters and must be between 1 and 64 characters long."
  }
}

variable "admin_username_secret" {
  type        = string
  description = "The name of the key vault secret containing the admin username"
  default     = "adminuser"
}

variable "enable_public_access" {
  type        = bool
  description = "Set to true to enable public access to the VM, false to disable it."
  default     = false
}


variable "key_vault_id" {
  type        = string
  description = "The existing key vault where secrets are stored"

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.KeyVault/vaults/[a-zA-Z0-9-]+$", var.key_vault_id))
    error_message = "Must be a valid Azure Resource ID for a Key Vault. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{keyVaultName}'."
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

variable "resource_group_name" {
  type        = string
  description = "The name of the existing resource group for provisioning resources."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "Must conform to Azure resource group naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), parentheses (()), and hyphens (-), and must be between 1 and 90 characters long."
  }
}

variable "storage_account_id" {
  type        = string
  description = "The ID of the existing storage account with the blob storage container to be used for Terraform state files."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Storage/storageAccounts/[a-zA-Z0-9]{3,24}$", var.storage_account_id))
    error_message = "Must be a valid Azure Resource ID for a storage account. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}'."
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

variable "vm_jumpbox_linux_image_offer" {
  type        = string
  description = "The offer type of the virtual machine image used to create the VM"
  default     = "ubuntu-24_04-lts"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_jumpbox_linux_image_offer))
    error_message = "Must conform to Azure Marketplace image offer naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_jumpbox_linux_image_publisher" {
  type        = string
  description = "The publisher for the virtual machine image used to create the VM"
  default     = "Canonical"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_jumpbox_linux_image_publisher))
    error_message = "Must conform to Azure Marketplace image publisher naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_jumpbox_linux_image_sku" {
  type        = string
  description = "The sku of the virtual machine image used to create the VM"
  default     = "server"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_jumpbox_linux_image_sku))
    error_message = "Must conform to Azure Marketplace image SKU naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_jumpbox_linux_image_version" {
  type        = string
  description = "The version of the virtual machine image used to create the VM"
  default     = "Latest"

  validation {
    condition     = can(regex("^(Latest|[0-9]+\\.[0-9]+\\.[0-9]+)$", var.vm_jumpbox_linux_image_version))
    error_message = "Must conform to Azure Marketplace image version naming requirements: it must be 'Latest' or in the format 'Major.Minor.Patch' (e.g., '1.0.0')."
  }
}

variable "vm_jumpbox_linux_name" {
  type        = string
  description = "The name of the VM"
  default     = "jumplinux2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_jumpbox_linux_name))
    error_message = "Must conform to Azure virtual machine naming conventions: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 15 characters long."
  }
}

variable "vm_jumpbox_linux_size" {
  type        = string
  description = "The size of the virtual machine"
  default     = "Standard_B2ls_v2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.vm_jumpbox_linux_size))
    error_message = "The 'vm_jumpbox_linux_size' must conform to Azure virtual machine size naming conventions: it can only contain alphanumeric characters and underscores (_). Examples include 'Standard_DS1_v2' or 'Standard_B2ms'."
  }
}

variable "vm_jumpbox_linux_storage_account_type" {
  type        = string
  description = "The storage type to be used for the VMs OS and data disks"
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.vm_jumpbox_linux_storage_account_type)
    error_message = "The 'vm_adds_storage_account_type' must be one of the valid Azure storage SKUs for managed disks: 'Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS', 'Premium_ZRS', or 'StandardSSD_ZRS'."
  }
}
