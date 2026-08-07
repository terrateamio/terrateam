variable "adds_domain_name" {
  type        = string
  description = "The AD DS domain name."
  default     = "myonprem.local"

  validation {
    condition     = length(var.adds_domain_name) <= 255
    error_message = "Must be a valid domain name with a maximum length of 255 characters."
  }
}

variable "adds_domain_name_cloud" {
  type        = string
  description = "The AD DS domain name for the cloud network."

  validation {
    condition     = length(var.adds_domain_name_cloud) <= 255
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

variable "dns_server_cloud" {
  type        = string
  description = "The IP address of the cloud DNS server."

  validation {
    condition     = can(regex("^(10\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3}))$|^(172\\.(1[6-9]|2[0-9]|3[0-1])\\.(\\d{1,3})\\.(\\d{1,3}))$|^(192\\.168\\.(\\d{1,3})\\.(\\d{1,3}))$", var.dns_server_cloud))
    error_message = "Must be a valid RFC 1918 private IP address (e.g., 10.x.x.x, 172.16.x.x - 172.31.x.x, or 192.168.x.x)."
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

variable "subnet_adds_address_prefix" {
  type        = string
  description = "The address prefix for the AD Domain Services subnet."
  default     = "192.168.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_adds_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_GatewaySubnet_address_prefix" {
  type        = string
  description = "The address prefix for the GatewaySubnet subnet."
  default     = "192.168.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_GatewaySubnet_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnet_misc_address_prefix" {
  type        = string
  description = "The address prefix for the miscellaneous subnet."
  default     = "192.168.2.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_misc_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "subnets_cloud" {
  type        = map(any)
  description = "The subnets in the shared services virtual network in the cloud sandbox environment."
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

variable "virtual_networks_cloud" {
  type        = map(any)
  description = "The names and resource ids of the virtual networks in the sandbox environment."
}

variable "vm_adds_image_offer" {
  type        = string
  description = "The offer type of the virtual machine image used to create the VM"
  default     = "WindowsServer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_adds_image_offer))
    error_message = "Must conform to Azure Marketplace image offer naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_adds_image_publisher" {
  type        = string
  description = "The publisher for the virtual machine image used to create the VM"
  default     = "MicrosoftWindowsServer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_adds_image_publisher))
    error_message = "Must conform to Azure Marketplace image publisher naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_adds_image_sku" {
  type        = string
  description = "The sku of the virtual machine image used to create the VM"
  default     = "2025-datacenter-azure-edition-core"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-._]{1,64}$", var.vm_adds_image_sku))
    error_message = "Must conform to Azure Marketplace image SKU naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), and hyphens (-), and must be between 1 and 64 characters long."
  }
}

variable "vm_adds_image_version" {
  type        = string
  description = "The version of the virtual machine image used to create the VM"
  default     = "Latest"

  validation {
    condition     = can(regex("^(Latest|[0-9]+\\.[0-9]+\\.[0-9]+)$", var.vm_adds_image_version))
    error_message = "Must conform to Azure Marketplace image version naming requirements: it must be 'Latest' or in the format 'Major.Minor.Patch' (e.g., '1.0.0')."
  }
}

variable "vm_adds_name" {
  type        = string
  description = "The name of the VM"
  default     = "adds2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_adds_name))
    error_message = "Must conform to Azure virtual machine naming conventions: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 15 characters long."
  }
}

variable "vm_adds_size" {
  type        = string
  description = "The size of the virtual machine."
  default     = "Standard_B2ls_v2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.vm_adds_size))
    error_message = "Must conform to Azure virtual machine size naming conventions: it can only contain alphanumeric characters and underscores (_). Examples include 'Standard_DS1_v2' or 'Standard_B2ms'."
  }
}

variable "vm_adds_storage_account_type" {
  type        = string
  description = "The storage replication type to be used for the VMs OS and data disks."
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.vm_adds_storage_account_type)
    error_message = "Must be one of the valid Azure storage SKUs for managed disks: 'Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS', 'Premium_ZRS', or 'StandardSSD_ZRS'."
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
  default     = "jumpwin2"

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
  description = "The storage replication type to be used for the VMs OS and data disks."
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.vm_jumpbox_win_storage_account_type)
    error_message = "Must be one of the valid Azure storage SKUs for managed disks: 'Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS', 'Premium_ZRS', or 'StandardSSD_ZRS'."
  }
}

variable "vnet_address_space" {
  type        = string
  description = "The address space in CIDR notation for the new virtual network."
  default     = "192.168.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "vnet_asn" {
  type        = string
  description = "The ASN for the on premises network."
  default     = "65123"

  validation {
    condition     = can(regex("^[1-9][0-9]{0,9}$", var.vnet_asn)) && tonumber(var.vnet_asn) >= 1 && tonumber(var.vnet_asn) <= 4294967295
    error_message = "ASN must be a positive integer between 1 and 4294967295."
  }
}

variable "vnet_name" {
  type        = string
  description = "The name of the new virtual network to be provisioned."
  default     = "onprem"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,64}$", var.vnet_name))
    error_message = "Must conform to Azure virtual network naming standards: it can only contain alphanumeric characters and hyphens (-), must start and end with an alphanumeric character, and must be between 1 and 64 characters long."
  }
}

variable "vwan_hub_id" {
  type        = string
  description = "The id of the virtual wan hub."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.Network/virtualHubs/[a-zA-Z0-9-_]+$", var.vwan_hub_id))
    error_message = "Must be a valid Azure Virtual WAN Hub resource ID, e.g. '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{hubName}'."
  }
}

variable "vwan_id" {
  type        = string
  description = "The id of the virtual wan."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.Network/virtualWans/[a-zA-Z0-9-_]+$", var.vwan_id))
    error_message = "Must be a valid Azure Virtual WAN resource ID, e.g. '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{wanName}'."
  }
}
