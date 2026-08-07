# Deployment specific Information
variable "deployment_information" {
  type = object({
    main = object({
      version  = string
      weight   = number
      profiles = optional(list(string), [])
    })
    canary = optional(object({
      version  = optional(string)
      weight   = optional(string)
      profiles = optional(list(string))
    }), {})
  })
  description = "Deployment information for managing the main and optional canary version of the application"

  validation {
    condition     = can(regex("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", var.deployment_information.main.version)) == true
    error_message = "Service Configuration is not valid. Please recheck service versions syntax."
  }

  validation {
    condition     = !can(length(var.deployment_information.main.profiles)) || can([for v in var.deployment_information.main.profiles : regex("^(([a-zA-Z]*-)*)?(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", v)])
    error_message = "Service Configuration is not valid. Please recheck versions for profiles syntax in main."
  }
  validation {
    condition     = !can(length(var.deployment_information.canary.profiles)) || can([for v in var.deployment_information.canary.profiles : regex("^(([a-zA-Z]*-)*)?(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", v)])
    error_message = "Service Configuration is not valid. Please recheck service canary syntax."
  }

  validation {
    condition = alltrue([
      for name, service in var.deployment_information : true &&
      (!can(length(service.canary.profiles)) || (can(length(service.canary.version) > 0) || !can(service.canary.weight >= 0 && service.canary.weight <= 100)))
    ])
    error_message = "Service Configuration is not valid. Please recheck versions for profiles syntax in validation-service-core. Canary needs to be defined with a version and weight."
  }
}

variable "profile_type" {
  description = "Profile types for the validation services. Allowed values are: fhir-profile-snapshots, igs-profile-snapshots, ars-profile-snapshots, are-profile-snapshots"
  type        = string
  validation {
    condition     = contains(["fhir-profile-snapshots", "igs-profile-snapshots", "ars-profile-snapshots", "are-profile-snapshots"], var.profile_type)
    error_message = "The profile type must be one of the following: fhir-profile-snapshots, igs-profile-snapshots, ars-profile-snapshots, are-profile-snapshots"
  }
}

variable "default_profile_snapshots" {
  description = "The version of the FHIR Profile Snapshots to use for fallback"
  type        = string
  validation {
    condition     = can(regex("^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$", var.default_profile_snapshots)) == true
    error_message = "The FHIR Profile Snapshots version must be in the format X.Y.Z[-suffix][+build]"
  }
}

variable "provisioning_mode" {
  description = "Provisioning mode for the FHIR Profiles Metadata. Allowed values are: dedicated, distributed, combined"
  type        = string
  nullable    = false
  default     = "dedicated"
  validation {
    condition     = contains(["dedicated", "distributed", "combined"], var.provisioning_mode)
    error_message = "The provisioning mode must be one of the following: dedicated, distributed, combined"
  }
}
