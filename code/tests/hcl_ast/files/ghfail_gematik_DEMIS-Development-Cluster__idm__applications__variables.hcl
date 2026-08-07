variable "target_namespace" {
  description = "The namespace to deploy the application to"
  type        = string
  default     = "demis"
}

variable "is_local_mode" {
  description = "Flag to define if the cluster is local"
  type        = bool
  default     = false
}

variable "external_chart_path" {
  description = "The path to the stage-dependent Helm Chart Values."
  type        = string
  validation {
    condition     = length(var.external_chart_path) > 0
    error_message = "The path to the stage-dependent Helm Chart Values must be defined"
  }
}

variable "deployment_information" {
  description = "Structure holding deployment information for the Helm Charts"
  type = map(object({
    chart-name          = optional(string) # Optional, uses a different Helm Chart name than the application name
    image-tag           = optional(string) # Optional, uses a different image tag for the deployment
    deployment-strategy = string
    enabled             = bool
    main = object({
      version = string
      weight  = number
    })
    canary = optional(object({
      version = optional(string)
      weight  = optional(string)
    }), {})
  }))

  validation {
    condition = alltrue([
      for service in var.deployment_information : true &&
      (!service.enabled || can(regex("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", service.main.version))
    )])
    error_message = "Service Configuration is not valid. Please recheck service versions syntax."
  }

  validation {
    condition = alltrue([
      for service in var.deployment_information : true &&
      (!service.enabled || contains(["canary", "update", "replace", "rolling"], service.deployment-strategy))
    ])
    error_message = "Service Configuration is not valid. Please recheck deployment-strategy. Only canary, update, replace and rolling is valid."
  }

  validation {
    condition = alltrue([
      for service in var.deployment_information : true &&
      (!service.enabled || service.canary.version == null || can(regex("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", service.canary.version)))
    ])

    error_message = "Service Configuration is not valid. Please recheck service canary syntax."
  }

  validation {
    condition = alltrue([
      for service in var.deployment_information : true &&
      (!service.enabled || service.canary.version == null || can(regex("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", service.canary.version)))
    ])

    error_message = "Service Configuration is not valid. Please recheck service canary syntax."
  }

  validation {
    condition = alltrue([
      for name, service in var.deployment_information : true &&
      (!service.enabled || !contains(["istio-routing"], name) || can(var.deployment_information["istio-routing"]))
    ])
    error_message = "Service Configuration is not valid. Istio routing chart is not defined."
  }

  validation {
    condition = alltrue([
      for name, service in var.deployment_information : true &&
      (!service.enabled || !contains(["keycloak", "bundid-idp"], name) || !(var.keycloak_user_import_enabled || var.bundid_idp_user_import_enabled) || can(var.deployment_information["stage-configuration-data"]))
    ])
    error_message = "Service Configuration is not valid. Stage configuration data is required for services keycloak and bund-idp if import is enabled."
  }

  validation {
    condition = alltrue([
      for name, service in var.deployment_information : true &&
      (!service.enabled || !contains(["keycloak", "bundid-idp"], name) || !(var.keycloak_user_import_enabled || var.bundid_idp_user_import_enabled) || can(length(var.deployment_information["stage-configuration-data"].chart-name) > 0))
    ])
    error_message = "Service Configuration is not valid. Stage configuration data chart-name is required for services keycloak and bund-idp if import is enabled."
  }
}

variable "resource_definitions" {
  description = "Defines a list of definition of resources that belong to a service"
  type = map(object({
    resource_block = optional(string)
    istio_proxy_resources = optional(object({
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    }))
    replicas = number
  }))
  default = {}

  validation {
    condition     = length(var.resource_definitions) > 0 ? alltrue([for key, value in var.resource_definitions : value != {}]) : true
    error_message = "Service should contain valid resource definitions. No Replicas or resource block defined"
  }
}

variable "istio_proxy_default_resources" {
  description = "Default values for istio proxy resource requests and limits"
  type = object({
    limits = object({
      cpu    = optional(string)
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
}

variable "pull_secrets" {
  type        = list(string)
  description = "The list of pull secrets to be used for downloading Docker Images"
  default     = []
}

variable "docker_registry" {
  description = "The docker registry to use for the application"
  type        = string
}

variable "helm_repository" {
  description = "The helm repository to use for the application"
  type        = string
}

variable "helm_repository_username" {
  description = "The username for the helm repository"
  type        = string
  default     = ""
}

variable "helm_repository_password" {
  description = "The password for the helm repository"
  type        = string
  sensitive   = true
  default     = ""
}

variable "istio_enabled" {
  description = "Enable istio for the application"
  type        = bool
  default     = true
}


# Feature Flags

variable "feature_flags" {
  type        = map(map(bool))
  description = "Defines a list of feature flags to be bound in services"
  default     = {}
}

# Operational Flags

variable "config_options" {
  type        = map(map(string))
  description = "Defines a list of ops flags to be bound in services"
  default     = {}
}

variable "timeout_retry_overrides" {
  description = "Defines retry and timeout configurations per service. Each definition must include a service name and can optionally include timeout and retry settings."
  type = list(object({
    service = string
    timeout = optional(string)
    retries = optional(object({
      enable        = optional(bool)
      attempts      = optional(number)
      perTryTimeout = optional(string)
      retryOn       = optional(string)
    }))
  }))
  default = []

  validation {
    condition     = length(var.timeout_retry_overrides) > 0 ? alltrue([for conf in var.timeout_retry_overrides : length(conf.service) > 0]) : true
    error_message = "Service name must not be empty"
  }
}

#########################
# Endpoints
#########################

# No explicit validation, as it is same as domain name
variable "core_hostname" {
  type        = string
  description = "The URL to access the DEMIS Core API"
  default     = ""
}

variable "bundid_idp_hostname" {
  type        = string
  description = "The BundID IDP Issuer URL to be used for the JSON Web Token (JWT) validation"
  default     = ""
}

variable "auth_hostname" {
  type        = string
  description = "The Keycloak Issuer URL to be used for the JSON Web Token (JWT) validation"
  default     = "auth"
  validation {
    condition     = length(var.auth_hostname) > 0
    error_message = "The Keycloak Issuer hostname must be defined"
  }
}

# No explicit validation, it is only available in local and dev environments
variable "ti_idp_hostname" {
  type        = string
  description = "The Portal URL to access the DEMIS Notification Portal"
  default     = ""
}

variable "cluster_gateway" {
  type        = string
  description = "Defines the Istio Cluster Gateway to be used"
  default     = "mesh/demis-core-gateway"
  nullable    = true
  validation {
    condition     = var.cluster_gateway != null ? length(var.cluster_gateway) > 0 : true
    error_message = "Istio Cluster Gateway Name must be a valid string"
  }
}

#########################
# Application Configuration
#########################

# Debugging 
variable "debug_enabled" {
  type        = bool
  description = "Defines if the backend Java Services must be started in Debug Mode"
  default     = false
}

# PGBouncer Database Host
variable "database_target_host" {
  type        = string
  description = "Defines the Hostname of the Database Server"
  validation {
    condition     = length(var.database_target_host) > 0
    error_message = "The Database Hostname must be defined"
  }
}

variable "certificate_update_service_suspend" {
  type        = bool
  description = "Defines if the certificate-update-service is suspended."
  default     = false
}

# Certificate Update Service Cron Schedule
variable "certificate_update_cron_schedule" {
  type        = string
  description = "Defines the Cron Schedule for the Certificate Update Service"
  validation {
    condition     = length(var.certificate_update_cron_schedule) > 0
    error_message = "The Certificate Update Service Cron Schedule must be defined"
  }
}

variable "keycloak_user_purger_suspend" {
  type        = bool
  description = "Defines if the keycloak-user-purger is suspended."
  default     = false
}

# Keycloak-User-Purger Cron Schedule
variable "keycloak_user_purger_cron_schedule" {
  type        = string
  description = "Defines the Cron Schedule for the Keycloak-User-Purger"
  validation {
    condition     = length(var.keycloak_user_purger_cron_schedule) > 0
    error_message = "The Keycloak-User-Purger Cron Schedule must be defined"
  }
}

# Server url of TI IDP Mock
variable "ti_idp_server_url" {
  type        = string
  description = "The server url for DEMIS Notification Portal over the Telematikinfrastruktur (TI)"
  default     = ""
}

# Client name of TI IDP Mock
variable "ti_idp_client_name" {
  type        = string
  description = "The client name for access the DEMIS Notification Portal over the Telematikinfrastruktur (TI)"
  default     = ""
}

# Redirect Uri of TI IDP Mock
variable "ti_idp_redirect_uri" {
  type        = string
  description = "The redirect uri to access the DEMIS Notification Portal over the Telematikinfrastruktur (TI)"
  default     = ""
}

# Activation of return sso token of TI IDP Mock
variable "ti_idp_return_sso_token" {
  type        = bool
  description = "Activate return sso token for access the DEMIS Notification Portal over the Telematikinfrastruktur (TI)"
  default     = true
}

# Activation of Keycloak user import
variable "keycloak_user_import_enabled" {
  type        = bool
  description = "Activate Keycloak user import"
}

# Tsl download endpoint for keycloak
variable "tsl_download_endpoint" {
  type        = string
  description = "Defines the TSL download endpoint for keycloak"
  default     = ""
}

# Activation of BundID IDP user import
variable "bundid_idp_user_import_enabled" {
  type        = bool
  description = "Activate BundID IDP user import"
}

variable "reset_values" {
  type        = bool
  description = "Reset the values to the ones built into the chart. This will override any custom values and reuse_values settings."
  default     = false
}

variable "project_feature_flags" {
  type        = map(bool)
  description = "Map of feature flags to enable or disable specific features in the DEMIS deployment. The keys are the names of the feature flags, and the values are booleans indicating whether the feature is enabled (true) or disabled (false)."
  default     = {}
}
