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

variable "container_registry_sku" {
  type        = string
  description = "The SKU name of the Azure Container Registry to create. Choose from: Basic, Standard, Premium. Premium is required for use with advanced features like private endpoints."
  default     = "Premium"

  validation {
    condition     = contains(["Premium"], var.container_registry_sku)
    error_message = "The container_registry_sku must be one of: Premium (case-sensitive)."
  }
}

variable "dns_server" {
  type        = string
  description = "The IP address of the DNS server. This should be the first non-reserved IP address in the subnet where the AD DS domain controller is hosted."

  validation {
    condition     = can(regex("^(10\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3}))$|^(172\\.(1[6-9]|2[0-9]|3[0-1])\\.(\\d{1,3})\\.(\\d{1,3}))$|^(192\\.168\\.(\\d{1,3})\\.(\\d{1,3}))$", var.dns_server))
    error_message = "Must be a valid RFC 1918 private IP address (e.g., 10.x.x.x, 172.16.x.x - 172.31.x.x, or 192.168.x.x)."
  }
}

variable "firewall_route_table_id" {
  type        = string
  description = "The id of the firewall route table."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Network/routeTables/[a-zA-Z0-9-_]+$", var.firewall_route_table_id))
    error_message = "Must be a valid Azure Resource ID for a route table. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}'."
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
    error_message = "Must be a valid Azure region name. It should only contain lowercase letters, numbers, and dashes."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of the Log Analytics workspace to send diagnostic logs to."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.OperationalInsights/workspaces/[a-zA-Z0-9-]+$", var.log_analytics_workspace_id))
    error_message = "Must be a valid Azure Log Analytics workspace resource ID in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}'."
  }
}

variable "private_dns_zones_vnet_shared" {
  type        = map(any)
  description = "A map of private DNS zones defined in vnet-shared module."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the existing resource group for provisioning resources."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "Must conform to Azure resource group naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), parentheses (()), and hyphens (-), and must be between 1 and 90 characters long."
  }
}

variable "storage_container_name" {
  type        = string
  description = "The name of the Azure storage container to be provisioned."
  default     = "scripts"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.storage_container_name))
    error_message = "Must conform to Azure storage container naming requirements: it can only contain lowercase letters, numbers, and hyphens (-), and must be between 3 and 63 characters long."
  }
}

variable "storage_share_name" {
  type        = string
  description = "The name of the Azure Files share to be provisioned."
  default     = "myfileshare"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,63}$", var.storage_share_name))
    error_message = "Must conform to Azure Files share naming requirements: it can only contain alphanumeric characters and hyphens (-), must be between 3 and 63 characters long, and must start and end with an alphanumeric character."
  }
}

variable "storage_share_quota_gb" {
  type        = number
  description = "The storage quota for the Azure Files share to be provisioned in GB."
  default     = 1024

  validation {
    condition     = var.storage_share_quota_gb >= 1 && var.storage_share_quota_gb <= 5120
    error_message = "Must be between 1 and 5120 GB, inclusive."
  }
}

variable "subnet_application_address_prefix" {
  type        = string
  description = "The address prefix for the application subnet."
  default     = "10.2.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_application_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_appservice_address_prefix" {
  type        = string
  description = "The address prefix for the App Service subnet."
  default     = "10.2.4.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_appservice_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_containerapps_address_prefix" {
  type        = string
  description = "The address prefix for the Azure Container Apps subnet."
  default     = "10.2.5.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_containerapps_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_database_address_prefix" {
  type        = string
  description = "The address prefix for the database subnet."
  default     = "10.2.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_database_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_misc_address_prefix" {
  type        = string
  description = "The address prefix for the MySQL subnet."
  default     = "10.2.3.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_misc_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_privatelink_address_prefix" {
  type        = string
  description = "The address prefix for the PrivateLink subnet."
  default     = "10.2.2.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_privatelink_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
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

variable "user_object_id" {
  type        = string
  description = "The object id of the user in Microsoft Entra ID."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.user_object_id))
    error_message = "Must be a valid GUID in the format 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'."
  }
}

variable "virtual_network_shared_id" {
  type        = string
  description = "The id of the existing shared services virtual network that the new spoke virtual network will be peered with."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Network/virtualNetworks/[a-zA-Z0-9-_]+$", var.virtual_network_shared_id))
    error_message = "Must be a valid Azure Resource ID for a virtual network. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}'."
  }
}

variable "virtual_network_shared_name" {
  type        = string
  description = "The name of the existing shared services virtual network that the new spoke virtual network will be peered with."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,64}$", var.virtual_network_shared_name))
    error_message = "Must conform to Azure virtual network naming standards: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 64 characters long."
  }
}


variable "vm_jumpbox_win_image_offer" {
  type        = string
  description = "The offer type of the virtual machine image used to create the VM"
  default     = "WindowsServer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_jumpbox_win_image_offer))
    error_message = "Must conform to Azure Marketplace image offer naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_jumpbox_win_image_publisher" {
  type        = string
  description = "The publisher for the virtual machine image used to create the VM"
  default     = "MicrosoftWindowsServer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_jumpbox_win_image_publisher))
    error_message = "Must conform to Azure Marketplace image publisher naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_jumpbox_win_image_sku" {
  type        = string
  description = "The sku of the virtual machine image used to create the VM"
  default     = "2025-datacenter-azure-edition"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_jumpbox_win_image_sku))
    error_message = "Must conform to Azure Marketplace image SKU naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_jumpbox_win_image_version" {
  type        = string
  description = "The version of the virtual machine image used to create the VM"
  default     = "Latest"

  validation {
    condition     = can(regex("^(Latest|[0-9]+\\.[0-9]+\\.[0-9]+)$", var.vm_jumpbox_win_image_version))
    error_message = "Must conform to Azure Marketplace image version naming requirements: it must be 'Latest' or in the format 'Major.Minor.Patch' (e.g., '1.0.0')."
  }
}

variable "vm_jumpbox_win_name" {
  type        = string
  description = "The name of the VM"
  default     = "jumpwin1"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_jumpbox_win_name))
    error_message = "Must conform to Azure virtual machine naming conventions: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 15 characters long."
  }
}

variable "vm_jumpbox_win_size" {
  type        = string
  description = "The size of the virtual machine."
  default     = "Standard_B2ls_v2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.vm_jumpbox_win_size))
    error_message = "Must conform to Azure virtual machine size naming conventions: it can only contain alphanumeric characters and underscores (_). Examples include 'Standard_DS1_v2' or 'Standard_B2ms'."
  }
}

variable "vm_jumpbox_win_storage_account_type" {
  type        = string
  description = "The storage type to be used for the VMs OS and data disks."
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.vm_jumpbox_win_storage_account_type)
    error_message = "Must be one of the valid Azure storage SKUs for managed disks: 'Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS', 'Premium_ZRS', or 'StandardSSD_ZRS'."
  }
}

variable "vnet_address_space" {
  type        = string
  description = "The address space in CIDR notation for the new application virtual network."
  default     = "10.2.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "vnet_name" {
  type        = string
  description = "The name of the application virtual network."
  default     = "app"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,64}$", var.vnet_name))
    error_message = "Must conform to Azure virtual network naming standards: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 64 characters long."
  }
}
