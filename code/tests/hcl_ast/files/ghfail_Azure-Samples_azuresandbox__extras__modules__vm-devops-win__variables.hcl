variable "admin_password" {
  type        = string
  description = "The password used when provisioning administrator accounts. This should be a strong password that meets Azure's complexity requirements."
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 8 && can(regex("[A-Z]", var.admin_password)) && can(regex("[a-z]", var.admin_password)) && can(regex("[0-9]", var.admin_password)) && can(regex("[!@#$%^&*()_+=\\[\\]{};':\"\\\\|,.<>/?-]", var.admin_password))
    error_message = "Password must be at least 8 characters long and include uppercase, lowercase, number, and special character."
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

variable "arm_client_secret" {
  type        = string
  description = "The password for the service principal used for authenticating with Azure. Set interactively or using an environment variable 'TF_VAR_arm_client_secret'."
  sensitive   = true

  validation {
    condition     = length(var.arm_client_secret) >= 8
    error_message = "Must be at least 8 characters long."
  }
}

variable "automation_account_name" {
  type        = string
  description = "The name of the Azure Automation Account used for state configuration (DSC)."

  validation {
    condition     = length(var.automation_account_name) <= 90
    error_message = "Must not exceed 90 characters, which is the maximum length for an Azure resource name."
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

variable "storage_blob_endpoint" {
  type        = string
  description = "The endpoint for the storage blob."

  validation {
    condition     = can(regex("^https://[a-zA-Z0-9-]+\\.blob\\.core\\.windows\\.net/$", var.storage_blob_endpoint))
    error_message = "Must be a valid Azure Storage Blob endpoint. It should follow the format 'https://{storageAccountName}.blob.core.windows.net/'."
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

variable "vm_devops_win_data_disk_size_gb" {
  type        = number
  description = "The size of the virtual machine data disk in GB"
  default     = 32

  validation {
    condition     = var.vm_devops_win_data_disk_size_gb > 4 && var.vm_devops_win_data_disk_size_gb < 32767
    error_message = "The data disk size must be greater than 4 GB and less than 32,767 GB."
  }
}

variable "vm_devops_win_image_offer" {
  type        = string
  description = "The offer type of the virtual machine image used to create the devops VM"
  default     = "WindowsServer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_devops_win_image_offer))
    error_message = "Must conform to Azure Marketplace image offer naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_devops_win_image_publisher" {
  type        = string
  description = "The publisher for the virtual machine image used to create the devops VM"
  default     = "MicrosoftWindowsServer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_devops_win_image_publisher))
    error_message = "Must conform to Azure Marketplace image publisher naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_devops_win_image_sku" {
  type        = string
  description = "The sku of the virtual machine image used to create the devops VM"
  default     = "2025-datacenter-azure-edition"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_devops_win_image_sku))
    error_message = "Must conform to Azure Marketplace image SKU naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_devops_win_image_version" {
  type        = string
  description = "The version of the virtual machine image used to create the devops VM"
  default     = "Latest"

  validation {
    condition     = can(regex("^(Latest|[0-9]+\\.[0-9]+\\.[0-9]+)$", var.vm_devops_win_image_version))
    error_message = "Must conform to Azure Marketplace image version naming requirements: it must be 'Latest' or in the format 'Major.Minor.Patch' (e.g., '1.0.0')."
  }
}

variable "vm_devops_win_instances" {
  type        = number
  description = "The number of devops agent VMs to provision."
  default     = 1

  validation {
    condition     = var.vm_devops_win_instances >= 1
    error_message = "The number of devops agent VMs to provision must be greater than or equal to 1."
  }
}

variable "vm_devops_win_license_type" {
  type        = string
  description = "The license type for the virtual machine"
  default     = "None"

  validation {
    condition     = can(regex("^(Windows_Client|Windows_Server|None)$", var.vm_devops_win_license_type))
    error_message = "Must be either 'Windows_Client' or 'Windows_Server' or 'None'."
  }
}

variable "vm_devops_win_name" {
  type        = string
  description = "The name of the devops agent VM."
  default     = "DEVOPSWIN"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_devops_win_name))
    error_message = "Must conform to Azure virtual machine naming conventions: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 15 characters long."
  }
}

variable "vm_devops_win_os_disk_size_gb" {
  type        = number
  description = "The size of the virtual machine OS disk in GB"
  default     = 127

  validation {
    condition     = var.vm_devops_win_os_disk_size_gb >= 32 && var.vm_devops_win_os_disk_size_gb <= 2048
    error_message = "The OS disk size must be between 32 GB and 2048 GB, which are the limits for managed OS disks for a Windows Server VM in Azure."
  }
}

variable "vm_devops_win_patch_mode" {
  type        = string
  description = "The patch mode for the virtual machine"
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["Manual", "AutomaticByOS", "AutomaticByPlatform"], var.vm_devops_win_patch_mode)
    error_message = "The patch mode must be one of: 'Manual', 'AutomaticByOS', or 'AutomaticByPlatform'."
  }
}

variable "vm_devops_win_size" {
  type        = string
  description = "The size of the virtual machine"
  default     = "Standard_B2ls_v2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.vm_devops_win_size))
    error_message = "Must conform to Azure virtual machine size naming conventions: it can only contain alphanumeric characters and underscores (_). Examples include 'Standard_DS1_v2' or 'Standard_B2ms'."
  }
}

variable "vm_devops_win_storage_account_type" {
  type        = string
  description = "The storage replication type to be used for the VMs OS disk"
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.vm_devops_win_storage_account_type)
    error_message = "Must be one of the valid Azure storage SKUs for managed disks: 'Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS', 'Premium_ZRS', or 'StandardSSD_ZRS'."
  }
}
