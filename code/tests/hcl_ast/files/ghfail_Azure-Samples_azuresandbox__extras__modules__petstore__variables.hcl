variable "arm_client_secret" {
  type        = string
  description = "The password for the service principal used for authenticating with Azure. Set interactively or using an environment variable 'TF_VAR_arm_client_secret'."
  sensitive   = true

  validation {
    condition     = length(var.arm_client_secret) >= 8
    error_message = "Must be at least 8 characters long."
  }
}

variable "container_apps_subnet_id" {
  type        = string
  description = "The resource ID of the subnet for Container Apps infrastructure."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.Network/virtualNetworks/[a-zA-Z0-9-]+/subnets/[a-zA-Z0-9-]+$", var.container_apps_subnet_id))
    error_message = "Must be a valid Azure subnet resource ID."
  }
}

variable "container_registry_id" {
  type        = string
  description = "The ID of an existing Azure Container Registry to use."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.ContainerRegistry/registries/[a-zA-Z0-9-]+$", var.container_registry_id))
    error_message = "Must be a valid Azure Container Registry resource ID in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}'."
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
  description = "The resource ID of the Log Analytics workspace for Container Apps Environment."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.OperationalInsights/workspaces/[a-zA-Z0-9-]+$", var.log_analytics_workspace_id))
    error_message = "Must be a valid Azure Log Analytics workspace resource ID."
  }
}

variable "private_dns_zone_id" {
  type        = string
  description = "The resource ID of the private DNS zone for Container Apps Environment."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.Network/privateDnsZones/[a-zA-Z0-9.-]+$", var.private_dns_zone_id))
    error_message = "Must be a valid Azure private DNS zone resource ID."
  }
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The resource ID of the subnet for private endpoints."

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F-]+/resourceGroups/[a-zA-Z0-9._()-]+/providers/Microsoft.Network/virtualNetworks/[a-zA-Z0-9-]+/subnets/[a-zA-Z0-9-]+$", var.private_endpoint_subnet_id))
    error_message = "Must be a valid Azure subnet resource ID."
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

variable "source_container_image" {
  type        = string
  description = "The name of the container image to import."
  default     = "swaggerapi/petstore31:latest"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+$", var.source_container_image))
    error_message = "Must be a valid Docker image name in the format 'repository/image:tag'."
  }
}

variable "source_container_registry" {
  type        = string
  description = "The name of the source container registry."
  default     = "docker.io"

  validation {
    condition     = can(regex("^([a-zA-Z0-9-]+\\.)*[a-zA-Z0-9-]+\\.[a-zA-Z]{2,}$", var.source_container_registry))
    error_message = "Must be a valid domain name (e.g., 'docker.io', 'registry.example.com')."
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
