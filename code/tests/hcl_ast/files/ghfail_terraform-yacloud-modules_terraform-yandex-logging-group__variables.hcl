variable "name" {
  description = "Name for the Yandex Cloud Logging group"
  type        = string
  default     = null

  validation {
    condition     = var.name == null || (can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.name)) && length(var.name) <= 63)
    error_message = "Name must be 1-63 characters long, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and cannot end with a hyphen."
  }
}

variable "folder_id" {
  description = "ID of the folder that the Yandex Cloud Logging group belongs to"
  type        = string
  default     = null

  validation {
    condition     = var.folder_id == null || can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.folder_id))
    error_message = "Folder ID must be a valid Yandex Cloud folder identifier format."
  }
}

variable "retention_period" {
  description = "Log entries retention period for the Yandex Cloud Logging group"
  type        = string
  default     = null

  validation {
    condition     = var.retention_period == null || can(regex("^[1-9][0-9]*[smh]$", var.retention_period))
    error_message = "Retention period must be a string in format like '3600s', '60m', '1h' etc. with positive duration."
  }
}

variable "description" {
  description = "A description for the Yandex Cloud Logging group"
  type        = string
  default     = null

  validation {
    condition     = var.description == null || length(var.description) <= 256
    error_message = "Description cannot be longer than 256 characters."
  }
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the Yandex Cloud Logging group"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.labels :
      can(regex("^[a-z][a-z0-9-_]{0,61}[a-z0-9]$", k)) &&
      length(k) <= 63 &&
      length(v) <= 63
    ])
    error_message = "Label keys must be 1-63 characters long, start with a lowercase letter, contain only lowercase letters, numbers, hyphens, and underscores. Values must be up to 63 characters."
  }
}


variable "timeouts" {
  description = "Timeout settings for logging group operations (create, read, update, delete)"
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null

  validation {
    condition = var.timeouts == null || alltrue([
      for k, v in var.timeouts :
      v == null || can(regex("^[1-9][0-9]*[smh]$", v))
    ])
    error_message = "Timeout values must be positive durations in format like '30m', '1h', '3600s' etc."
  }
}

variable "data_stream" {
  description = "Data Stream associated with the logging group"
  type        = string
  default     = null

  validation {
    condition     = var.data_stream == null || can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.data_stream))
    error_message = "Data stream must be a valid Yandex Cloud resource identifier format."
  }
}
