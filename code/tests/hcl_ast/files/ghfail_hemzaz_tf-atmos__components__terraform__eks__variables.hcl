variable "region" {
  type        = string
  description = "AWS region"
  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-\\d+$", var.region))
    error_message = "The region must be a valid AWS region name (e.g., us-east-1, eu-west-1)."
  }
}

variable "clusters" {
  type = map(object({
    enabled                   = optional(bool, true)
    kubernetes_version        = optional(string)
    endpoint_private_access   = optional(bool, true)
    endpoint_public_access    = optional(bool, false)
    subnet_ids                = optional(list(string))
    security_group_ids        = optional(list(string), [])
    kms_key_arn               = optional(string)
    enabled_cluster_log_types = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])
    node_groups               = optional(map(any), {})
    tags                      = optional(map(string), {})
  }))
  description = "Map of EKS cluster configurations with typed schema"
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      lookup(v, "kubernetes_version", "") == "" ||
      can(regex("^\\d+\\.(\\d+)$", lookup(v, "kubernetes_version", var.default_kubernetes_version)))
    ])
    error_message = "Kubernetes version must be valid and in the format 'X.Y' (e.g., 1.28)."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters : length(lookup(v, "enabled_cluster_log_types", [])) > 0
    ])
    error_message = "At least one cluster log type must be enabled for each cluster."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      lookup(v, "kms_key_arn", "") == "" ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", lookup(v, "kms_key_arn", "")))
    ])
    error_message = "KMS key ARN must be in a valid format (e.g., arn:aws:kms:region:account-id:key/key-id)."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      alltrue([
        for sg in lookup(v, "security_group_ids", []) :
        can(regex("^sg-[a-z0-9]+$", sg))
      ])
    ])
    error_message = "All security group IDs must be in a valid format (e.g., sg-abc123)."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      lookup(v, "endpoint_private_access", true) == true || lookup(v, "endpoint_public_access", false) == true
    ])
    error_message = "At least one of endpoint_private_access or endpoint_public_access must be enabled for the cluster."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the EKS clusters"

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for an EKS cluster for high availability."
  }

  validation {
    condition     = alltrue([for id in var.subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "All subnet IDs must be in a valid format (e.g., subnet-abc123)."
  }
}

variable "default_kubernetes_version" {
  type        = string
  description = "Default Kubernetes version for EKS clusters"
  default     = "1.28"

  validation {
    condition     = can(regex("^\\d+\\.(\\d+)$", var.default_kubernetes_version))
    error_message = "Default Kubernetes version must be in the format 'X.Y' (e.g., 1.28)."
  }
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the OIDC provider for the EKS cluster"
  default     = ""

  validation {
    condition     = var.oidc_provider_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
    error_message = "OIDC provider ARN must be in a valid format (e.g., arn:aws:iam::123456789012:oidc-provider/...)."
  }
}

variable "enable_cluster_protection" {
  type        = bool
  description = "Enable prevent_destroy lifecycle for EKS clusters in production environments"
  default     = true
}

variable "default_cluster_log_retention_days" {
  type        = number
  description = "Number of days to retain cluster logs"
  default     = 90

  # Use more maintainable validation pattern based on CloudWatch allowed values
  validation {
    # Allowed values according to CloudWatch: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    condition = (
      # Check if value is in standard retention periods (1-180 days)
      contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180], var.default_cluster_log_retention_days) ||
      # Or check if it's in extended periods (>180 days)
      contains([365, 400, 545, 731, 1827, 3653], var.default_cluster_log_retention_days)
    )
    error_message = "Log retention days must be a CloudWatch allowed value: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653 days."
  }

  # We can't reference var.tags here as it creates a circular reference,
  # so we'll provide guidance in the description instead
  # Better practice is to enforce this in module logic or via CI/CD validation
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}

  validation {
    condition     = contains(keys(var.tags), "Environment")
    error_message = "The tags map must contain an 'Environment' key."
  }
}