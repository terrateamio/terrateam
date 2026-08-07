variable "ai_search_sku" {
  type        = string
  description = "The sku name of the Azure AI Search service to create. Choose from: Free, Basic, Standard, StorageOptimized. See https://docs.microsoft.com/en-us/azure/search/search-sku-tier"
  default     = "basic"

  validation {
    condition     = contains(["free", "basic", "standard", "storageoptimized"], lower(var.ai_search_sku))
    error_message = "The ai_search_sku must be one of: Free, Basic, Standard, StorageOptimized (case-insensitive)."
  }
}

variable "ai_services_sku" {
  type        = string
  description = "The sku name of the AI Services sku. Choose from: S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10. See https://docs.microsoft.com/en-us/azure/cognitive-services/cognitive-services-apis-create-account-cli?tabs=multiservice%2Cwindows"
  default     = "S0"

  validation {
    condition     = contains(["s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10"], lower(var.ai_services_sku))
    error_message = "The ai_services_sku must be one of: S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10 (case-insensitive)."
  }
}

variable "container_registry_sku" {
  type        = string
  description = "The sku name of the Azure Container Registry to create. Choose from: Basic, Standard, Premium. Premium is required for use with AI Studio hubs."
  default     = "Premium"

  validation {
    condition     = contains(["basic", "standard", "premium"], lower(var.container_registry_sku))
    error_message = "The container_registry_sku must be one of: Basic, Standard, Premium (case-insensitive)."
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

variable "private_dns_zones" {
  type        = map(any)
  description = "The existing private dns zones defined in the application virtual network."
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
  description = "The id of the shared storage account."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9-_()]+/providers/Microsoft.Storage/storageAccounts/[a-zA-Z0-9]{3,24}$", var.storage_account_id))
    error_message = "Must be a valid Azure Resource ID for a storage account. It should follow the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}'."
  }
}

variable "storage_file_endpoint" {
  type        = string
  description = "The endpoint of the Azure Files share."

  validation {
    condition     = can(regex("^https://[a-zA-Z0-9-]+\\.file\\.core\\.windows\\.net/$", var.storage_file_endpoint))
    error_message = "Must be a valid Azure Storage File endpoint. It should follow the format 'https://{storageAccountName}.file.core.windows.net/'."
  }
}

variable "storage_share_name" {
  type        = string
  description = "The name of the Azure Files share."

  validation {
    condition     = can(regex("^[a-z0-9]{3,63}$", var.storage_share_name))
    error_message = "The storage_share_name must be between 3 and 63 characters, and can only contain lowercase letters and numbers."
  }
}

variable "subnets" {
  type        = map(any)
  description = "The existing subnets defined in the application virtual network."
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
  description = "The object id of the interactive user."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.user_object_id))
    error_message = "The user_object_id must be a valid Entra ID (Azure AD) object ID in GUID format."
  }
}
