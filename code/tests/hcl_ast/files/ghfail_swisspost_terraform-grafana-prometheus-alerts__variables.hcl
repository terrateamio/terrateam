variable "prometheus_alerts_file_path" {
  description = "Path to the Prometheus Alerting rules file"
  type        = string
}

variable "folder_uid" {
  description = "The UID of the Grafana folder that the alerts belongs to."
  type        = string
}

variable "datasource_uid" {
  description = "The UID of the Grafana datasource being queried with the expressions inside the Alerting rule file"
  type        = string
}

variable "overrides" {
  description = "Overrides per Alert rule"
  type = map(object({
    alert_threshold = optional(number)
    exec_err_state  = optional(string)
    expr            = optional(string)
    is_paused       = optional(bool)
    no_data_state   = optional(string)
    labels          = optional(map(string))
    annotations     = optional(map(string))
    for             = optional(string)
  }))
  default = {}
}

variable "default_evaluation_interval_duration" {
  description = "How often is the rule evaluated by default. (When not defined inside your Alerting rules file)"
  type        = string
  default     = "5m"
}

variable "org_id" {
  description = "The Organization ID of of the Grafana Alerting rule groups. (Only supported with basic auth, API keys are already org-scoped)"
  type        = string
  default     = null
}

variable "disable_provenance" {
  description = "Allow modifying the rule group from other sources than Terraform or the Grafana API."
  type        = bool
  default     = false
}

variable "alert_relative_time_range_from" {
  description = "Relative time range (seconds) for alert evaluation window"
  type        = number
  default     = 600
}
