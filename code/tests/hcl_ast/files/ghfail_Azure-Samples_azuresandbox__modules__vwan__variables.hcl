variable "client_address_pool" {
  type        = string
  description = "The client address pool for the point to site VPN gateway."
  default     = "10.4.0.0/16"

  validation {
    condition     = can(cidrhost(var.client_address_pool, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "dns_server" {
  type        = string
  description = "The IP address for the DNS server."

  validation {
    condition     = can(regex("^(10\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3}))$|^(172\\.(1[6-9]|2[0-9]|3[0-1])\\.(\\d{1,3})\\.(\\d{1,3}))$|^(192\\.168\\.(\\d{1,3})\\.(\\d{1,3}))$", var.dns_server))
    error_message = "Must be a valid RFC 1918 private IP address (e.g., 10.x.x.x, 172.16.x.x - 172.31.x.x, or 192.168.x.x)."
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
  description = "The name of the existing resource group."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "Must conform to Azure resource group naming requirements: it can only contain alphanumeric characters, periods (.), underscores (_), parentheses (()), and hyphens (-), and must be between 1 and 90 characters long."
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

variable "virtual_networks" {
  type        = map(any)
  description = "The virtual networks to be connected to the vwan hub."

  # default = { MyHubVNetId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroupName/providers/Microsoft.Network/virtualNetworks/MyHubVNetName", MySpokeVnetId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroupName/providers/Microsoft.Network/virtualNetworks/MySpokeVNetName" } 
}

variable "vwan_hub_address_prefix" {
  type        = string
  description = "The address prefix in CIDR notation for the new spoke virtual wan hub."
  default     = "10.3.0.0/16"

  validation {
    condition     = can(cidrhost(var.vwan_hub_address_prefix, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}
