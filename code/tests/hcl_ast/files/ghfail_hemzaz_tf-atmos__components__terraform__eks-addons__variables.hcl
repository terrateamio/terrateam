variable "region" {
  type        = string
  description = "AWS region"
  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-\\d+$", var.region))
    error_message = "The region must be a valid AWS region name (e.g., us-east-1, eu-west-1)."
  }
}

variable "assume_role_arn" {
  type        = string
  description = "ARN of the IAM role to assume"
  default     = null

  validation {
    condition     = var.assume_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.assume_role_arn))
    error_message = "The assume_role_arn must be a valid IAM role ARN or null."
  }
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to all resources"
  default     = {}

  validation {
    condition     = length(var.default_tags) > 0 ? contains(keys(var.default_tags), "Environment") : true
    error_message = "If default_tags is provided, it must contain an 'Environment' key."
  }
}

variable "clusters" {
  type = map(object({
    # Required fields
    cluster_name           = string
    kubernetes_host        = string
    cluster_ca_certificate = string
    oidc_provider_arn      = string
    oidc_provider_url      = string

    # Optional fields
    service_account_token_path = optional(string)

    # Feature flags
    enable_aws_load_balancer_controller = optional(bool, true)
    enable_cluster_autoscaler           = optional(bool, true)
    enable_external_dns                 = optional(bool, true)
    enable_cert_manager                 = optional(bool, true)
    enable_metrics_server               = optional(bool, true)
    enable_aws_for_fluentbit            = optional(bool, false)
    enable_aws_cloudwatch_metrics       = optional(bool, false)
    enable_karpenter                    = optional(bool, false)
    enable_keda                         = optional(bool, false)
    enable_istio                        = optional(bool, false)
    enable_external_secrets             = optional(bool, false)

    # Configuration options
    cert_manager_letsencrypt_email = optional(string)
    external_dns_domain_filters    = optional(list(string), [])
    karpenter_provisioner_config   = optional(map(any), {})
    fluentbit_log_group_name       = optional(string)
    log_retention_days             = optional(number, 90)
    istio_config                   = optional(map(any), {})
    additional_namespaces          = optional(list(string), [])

    # Tags
    tags = optional(map(string), {})
  }))
  description = "Map of cluster configurations with addons, Helm releases, and Kubernetes manifests"
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      v.cluster_name != null &&
      v.kubernetes_host != null &&
      v.cluster_ca_certificate != null &&
      v.oidc_provider_arn != null &&
      v.oidc_provider_url != null
    ])
    error_message = "All clusters must specify cluster_name, kubernetes_host, cluster_ca_certificate, oidc_provider_arn, and oidc_provider_url."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      v.enable_cert_manager == false ||
      (v.enable_cert_manager == true && v.cert_manager_letsencrypt_email != null &&
      can(regex("^[^@]+@[^@]+\\.[^@]+$", v.cert_manager_letsencrypt_email)))
    ])
    error_message = "When cert_manager is enabled, cert_manager_letsencrypt_email must be a valid email address."
  }
}

# Deprecated variables (for backward compatibility)
variable "cluster_name" {
  type        = string
  description = "Default EKS cluster name - DEPRECATED, use clusters map instead"
  default     = ""
}

variable "host" {
  type        = string
  description = "Default Kubernetes host - DEPRECATED, use clusters map instead"
  default     = ""
}

variable "cluster_ca_certificate" {
  type        = string
  description = "Default Kubernetes cluster CA certificate - DEPRECATED, use clusters map instead"
  default     = ""
}

variable "oidc_provider_arn" {
  type        = string
  description = "Default OIDC provider ARN for the EKS cluster - DEPRECATED, use clusters map instead"
  default     = ""

  validation {
    condition     = var.oidc_provider_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
    error_message = "OIDC provider ARN must be in a valid format (e.g., arn:aws:iam::123456789012:oidc-provider/...)."
  }
}

variable "oidc_provider_url" {
  type        = string
  description = "Default OIDC provider URL for the EKS cluster - DEPRECATED, use clusters map instead"
  default     = ""

  validation {
    condition     = var.oidc_provider_url == "" || can(regex("^https://", var.oidc_provider_url))
    error_message = "OIDC provider URL must start with https://."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}

  validation {
    condition     = length(var.tags) > 0 ? contains(keys(var.tags), "Environment") : true
    error_message = "If tags is provided, it must contain an 'Environment' key."
  }
}

# -------------------------------------------------------------------------
# Service Mesh Configuration Variables (DEPRECATED)
# -------------------------------------------------------------------------
# MIGRATION GUIDE:
# 1. Replace 'istio_enabled' with 'clusters["your-cluster"].enable_istio_service_mesh'
# 2. Replace 'istio_enable_tracing' with 'clusters["your-cluster"].enable_distributed_tracing'
# 3. Replace 'kiali_enabled' with 'clusters["your-cluster"].enable_service_mesh_visualization'
# 4. Replace 'jaeger_enabled' with 'clusters["your-cluster"].enable_jaeger_tracing_storage'
#
# Example of new configuration:
# clusters = {
#   main = {
#     ...
#     enable_istio_service_mesh = true
#     enable_distributed_tracing = true
#     enable_service_mesh_visualization = true
#     ...
#   }
# }
# -------------------------------------------------------------------------

variable "istio_enabled" {
  type        = bool
  description = "Whether to enable Istio service mesh - DEPRECATED, use clusters[*].enable_istio_service_mesh instead"
  default     = false
}

variable "istio_enable_tracing" {
  type        = bool
  description = "Whether to enable distributed tracing in Istio - DEPRECATED, use clusters[*].enable_distributed_tracing instead"
  default     = true
}

variable "istio_gateway_min_replicas" {
  type        = number
  description = "Minimum replicas for Istio gateway - DEPRECATED, use clusters[*].istio_config instead"
  default     = 2

  validation {
    condition     = var.istio_gateway_min_replicas >= 2
    error_message = "Istio gateway minimum replicas should be at least 2 for high availability."
  }
}

variable "istio_gateway_max_replicas" {
  type        = number
  description = "Maximum replicas for Istio gateway - DEPRECATED, use clusters[*].istio_config instead"
  default     = 5

  validation {
    condition     = var.istio_gateway_max_replicas >= var.istio_gateway_min_replicas
    error_message = "Maximum replicas must be greater than or equal to minimum replicas."
  }
}

variable "kiali_enabled" {
  type        = bool
  description = "Whether to enable Kiali visualization for Istio - DEPRECATED, use clusters[*].istio_config instead"
  default     = false
}

variable "jaeger_enabled" {
  type        = bool
  description = "Whether to enable Jaeger tracing for Istio - DEPRECATED, use clusters[*].istio_config instead"
  default     = false
}

variable "jaeger_storage_type" {
  type        = string
  description = "Storage type for Jaeger (memory, elasticsearch, cassandra) - DEPRECATED, use clusters[*].istio_config instead"
  default     = "memory"
  validation {
    condition     = contains(["memory", "elasticsearch", "cassandra"], var.jaeger_storage_type)
    error_message = "Allowed values for jaeger_storage_type are 'memory', 'elasticsearch', or 'cassandra'."
  }
}

# Certificate management variables
variable "domain_name" {
  type        = string
  description = "Domain name for certificates and DNS records - DEPRECATED, use clusters[*].cert_manager_config instead"
  default     = "example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "The domain_name must be a valid domain (e.g., example.com)."
  }
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for DNS validation - DEPRECATED, use clusters[*].cert_manager_config instead"
  default     = ""

  validation {
    condition     = var.hosted_zone_id == "" || can(regex("^Z[A-Z0-9]{1,32}$", var.hosted_zone_id))
    error_message = "The hosted_zone_id must be a valid Route53 Zone ID (e.g., Z00000000000000000000)."
  }
}

# ACM Integration
variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate to use for Istio gateway"
  default     = ""
}

variable "acm_certificate_crt" {
  type        = string
  description = "Certificate content from ACM"
  default     = ""
  sensitive   = true
}

variable "acm_certificate_key" {
  type        = string
  description = "Private key content from ACM"
  default     = ""
  sensitive   = true
}

# Secrets Manager Integration
variable "secrets_manager_secret_path" {
  type        = string
  description = "Path to the secret in AWS Secrets Manager containing the TLS certificate"
  default     = ""
}

variable "use_external_secrets" {
  type        = bool
  description = "Whether to use external-secrets operator to retrieve certificates from Secrets Manager"
  default     = true
}