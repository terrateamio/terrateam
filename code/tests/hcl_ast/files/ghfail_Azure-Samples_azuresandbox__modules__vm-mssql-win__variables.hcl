variable "adds_domain_name" {
  type        = string
  description = "The AD DS domain name."

  validation {
    condition     = length(var.adds_domain_name) <= 255
    error_message = "Must be a valid domain name with a maximum length of 255 characters."
  }
}

variable "admin_password" {
  type        = string
  description = "The password used when provisioning administrator accounts. This should be a strong password that meets Azure's complexity requirements."
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 8 && can(regex("[A-Z]", var.admin_password)) && can(regex("[a-z]", var.admin_password)) && can(regex("[0-9]", var.admin_password)) && can(regex("[!@#$%^&*()_+=\\[\\]{};':\"\\\\|,.<>/?-]", var.admin_password))
    error_message = "Password must be at least 8 characters long and include uppercase, lowercase, number, and special character."
  }
}

variable "admin_password_secret" {
  type        = string
  description = "The name of the key vault secret containing the admin password"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,127}$", var.admin_password_secret))
    error_message = "Must conform to Azure Key Vault secret naming requirements: it can only contain alphanumeric characters and hyphens, and must be between 1 and 127 characters long."
  }
}

variable "admin_username" {
  type        = string
  description = "The user name used when provisioning administrator accounts. This should conform to Windows username requirements (alphanumeric characters, periods, underscores, and hyphens, 1-20 characters)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{1,20}$", var.admin_username))
    error_message = "Must conform to Windows username requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 20 characters long."
  }
}

variable "admin_username_secret" {
  type        = string
  description = "The name of the key vault secret containing the admin username"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,127}$", var.admin_username_secret))
    error_message = "Must conform to Azure Key Vault secret naming requirements: it can only contain alphanumeric characters and hyphens, and must be between 1 and 127 characters long."
  }
}

variable "key_vault_id" {
  type        = string
  description = "The existing key vault where secrets are stored"

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.KeyVault/vaults/[a-zA-Z0-9-]+$", var.key_vault_id))
    error_message = "Must be a valid Azure Resource ID for a Key Vault. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{keyVaultName}'."
  }
}

variable "key_vault_name" {
  type        = string
  description = "The existing key vault where secrets are stored"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Must conform to Azure Key Vault naming requirements: it can only contain alphanumeric characters and hyphens, must start with a letter, and must be between 3 and 24 characters long."
  }
}

variable "location" {
  type        = string
  description = "The name of the Azure Region where resources will be provisioned."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.location))
    error_message = "Must be a valid Azure region name. It should only contain lowercase letters, numbers, and dashes (e.g., 'eastus', 'westus2', 'centralus')."
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
  description = "The ID of the existing storage account where the remote scripts are stored."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Storage/storageAccounts/[a-zA-Z0-9]{3,24}$", var.storage_account_id))
    error_message = "Must be a valid Azure Resource ID for a storage account. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}'."
  }

}

variable "storage_account_name" {
  type        = string
  description = "The name of the shared storage account."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Must conform to Azure storage account naming requirements: it can only contain lowercase letters and numbers, and must be between 3 and 24 characters long."
  }
}

variable "storage_container_name" {
  type        = string
  description = "The name of the storage container where remote scripts are stored."

  validation {
    condition     = can(regex("^[a-z0-9]{3,63}$", var.storage_container_name))
    error_message = "Must conform to Azure storage container naming requirements: it can only contain lowercase letters and numbers, and must be between 3 and 63 characters long."
  }
}

variable "storage_blob_endpoint" {
  type        = string
  description = "The endpoint for the storage blob."

  validation {
    condition     = can(regex("^https://[a-zA-Z0-9-]+\\.blob\\.core\\.windows\\.net/$", var.storage_blob_endpoint))
    error_message = "Must be a valid Azure Storage Blob endpoint. It should follow the format 'https://{storageAccountName}.blob.core.windows.net/'."
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

variable "vm_mssql_win_image_offer" {
  type        = string
  description = "The offer type of the virtual machine image used to create the database server VM"
  default     = "sql2025-ws2025"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_mssql_win_image_offer))
    error_message = "Must conform to Azure Marketplace image offer naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_mssql_win_image_publisher" {
  type        = string
  description = "The publisher for the virtual machine image used to create the database server VM"
  default     = "MicrosoftSQLServer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_mssql_win_image_publisher))
    error_message = "Must conform to Azure Marketplace image publisher naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_mssql_win_image_sku" {
  type        = string
  description = "The sku of the virtual machine image used to create the database server VM"
  default     = "entdev-gen2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_mssql_win_image_sku))
    error_message = "Must conform to Azure Marketplace image SKU naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_mssql_win_image_version" {
  type        = string
  description = "The version of the virtual machine image used to create the database server VM"
  default     = "Latest"

  validation {
    condition     = can(regex("^(Latest|[0-9]+\\.[0-9]+\\.[0-9]+)$", var.vm_mssql_win_image_version))
    error_message = "Must conform to Azure Marketplace image version naming requirements: it must be 'Latest' or in the format 'Major.Minor.Patch' (e.g., '1.0.0')."
  }
}

variable "vm_mssql_win_name" {
  type        = string
  description = "The name of the database server VM"
  default     = "mssqlwin1"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_mssql_win_name))
    error_message = "Must conform to Azure virtual machine naming conventions: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 15 characters long."
  }
}

variable "vm_mssql_win_size" {
  type        = string
  description = "The size of the virtual machine"
  default     = "Standard_D4ds_v6" # use az-vm list-skus to determine if this size is available in your region

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.vm_mssql_win_size))
    error_message = "The 'vm_mssql_win_size' must conform to Azure virtual machine size naming conventions: it can only contain alphanumeric characters and underscores (_). Examples include 'Standard_DS1_v2' or 'Standard_B2ms'."
  }
}

variable "vm_mssql_win_storage_account_type_data_disks" {
  type        = string
  description = "The storage type to be used for the VMs data disks."
  default     = "PremiumV2_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "PremiumV2_LRS", "Premium_ZRS", "StandardSSD_LRS", "UltraSSD_LRS"], var.vm_mssql_win_storage_account_type_data_disks)
    error_message = "The 'vm_mssql_win_storage_account_type_data_disks' must be one of the valid Azure storage SKUs for managed disks: 'Standard_LRS', 'StandardSSD_LRS', 'StandardSSD_ZRS', 'Premium_LRS', 'PremiumV2_LRS', 'Premium_ZRS', or 'UltraSSD_LRS'."
  }
}

variable "vm_mssql_win_storage_account_type_os_disk" {
  type        = string
  description = "The storage type to be used for the VMs OS disk"
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.vm_mssql_win_storage_account_type_os_disk)
    error_message = "The 'vm_mssql_win_storage_account_type' must be one of the valid Azure storage SKUs for managed disks: 'Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS', 'Premium_ZRS', or 'StandardSSD_ZRS'."
  }
}

variable "vm_mssql_win_zone" {
  type        = string
  description = "The availability zone for the virtual machine."
  default     = "2" # use az-vm list-skus to determine if this size is available in your region / zone

  validation {
    condition     = contains(["1", "2", "3"], var.vm_mssql_win_zone)
    error_message = "Must be a valid Azure availability zone: '1', '2', or '3'."
  }
}
