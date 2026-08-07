variable "environment" {
  type        = string
  description = "Deployment environment of the Celestia Bridge being monitored. Common values include 'mainnet', 'testnet', or custom environment names. Default is set to 'testnet'."
  default     = "testnet"
}

variable "service" {
  type        = string
  description = "Type of service within the the Celestia Network that is being monitored. For instance, 'bridge' represents a node that connects the data availability layer and the consensus layer. Default is set to 'bridge'."
  default     = "validator"
}

variable "evaluation_delay" {
  description = "The delay, in seconds, before evaluating the metric to account for data ingestion latency. Helps ensure data completeness for accurate monitoring."
  default     = 300
}

variable "notify_no_data" {
  description = "Enables alerts for 'no data' events, indicating possible issues with data reporting or collection from the Sui validator."
  default     = true
}

variable "no_data_timeframe" {
  description = "Duration, in minutes, to wait before alerting on a 'no data' condition, signaling potential interruptions in data flow or metric collection."
  default     = 15
}

variable "notification_preset_name" {
  description = "Configures the detail level in monitor notifications. Options: 'show_all', 'hide_query', 'hide_handles', 'hide_all'. Tailors notifications to include essential information."
  default     = "hide_handles"
}

variable "renotify_interval" {
  description = "Interval, in minutes, between re-notifications for unresolved issues, ensuring timely follow-ups on critical Sui validator performance metrics."
  default     = 15
}

variable "renotify_occurrences" {
  description = "Specifies the maximum number of re-notification messages for unresolved alerts, controlling alert frequency on ongoing issues."
  default     = 2
}

variable "renotify_statuses" {
  type        = list(string)
  description = "Defines the alert statuses (e.g., 'alert', 'warn', 'no data') that trigger re-notifications, allowing for targeted follow-ups on specific conditions."
  default     = ["alert", "warn", "no data"]

  validation {
    condition = alltrue([
                  for status in var.renotify_statuses : 
                  contains(["alert", "warn", "no data"], status)
                ])
    error_message = "Each status in 'renotify_statuses' must be one of the following values: 'alert', 'warn', 'no data'."
  }
}

variable "notification_targets" {
  type        = map(list(string))
  default     = {}
  description = "A map specifying notification targets for different alert thresholds. It allows defining custom notification channels for 'critical' and 'warning' alerts, ensuring appropriate alert routing. Each channel should be specified with a unique identifier, prefixed with '@'. Format: {'critical': ['@channel1', '@user'], 'warning': ['@channel2']}."

  validation {
    condition = can(var.notification_targets) && alltrue([
                  can(tomap(var.notification_targets)),
                  alltrue([
                    for key, value in var.notification_targets : 
                    contains(["critical", "warning"], key) && 
                    can(toset(value)) && 
                    alltrue([
                      for target in value : regex("^@[0-9a-zA-Z-_]+$", target)
                    ])
                  ])
                ])
    error_message = "The 'notification_targets' map must include only 'critical' and 'warning' keys with lists of notification channel identifiers, each starting with '@'. Ensure the map is not empty and all identifiers are correctly formatted."
  }
}

variable "tags" {
  type        = list(string)
  description = "A list of tags to be associated with the Datadog monitors. Tags are key-value pairs that help in categorizing and filtering monitors across different environments, teams, or service types, enhancing manageability and visibility."
  default     = []

  validation {
    condition = can(var.tags) && alltrue([
      for tag in var.tags :
      regex("^[^:]+:[^:]+( [^:]+:[^:]+)*$", tag)
    ])
    error_message = "(Optional) attribute 'tags' of 'monitor' must be of the type list with string attributes, matching the format 'key:value' (e.g., 'environment:production')."
  }
}

variable "runtime_counter_is_stuck_enabled" {
  description = "Enables monitoring for the runtime counter on the bridge node."
  type        = string
  default     = "true"
}

variable "runtime_counter_is_stuck_message" {
  description = "Customizable notification message the runtime counter monitor."
  type        = string
  default     = ""
}

variable "runtime_counter_is_stuck_escalation_message" {
  description = "A message to include with a re-notification for the runtime counter monitor escalation."
  type        = string
  default     = ""
}

variable "runtime_counter_is_stuck_aggregator" {
  type        = string
  description = "Aggregation method for evaluating runtime counter over the specified timeframe, crucial for identifying performance trends. Valid options are 'min', 'max', 'avg'."
  default     = "avg"

  validation {
    condition     = contains(["min", "max", "avg"], var.runtime_counter_is_stuck_aggregator)
    error_message = "The 'runtime_counter_is_stuck_aggregator' must be one of the following values: 'min', 'max', 'avg'."
  }
}

variable "runtime_counter_is_stuck_timeframe" {
  type        = string
  description = "Time window for assessing runtime counter, setting the scope for performance evaluation of the bridge node. Valid options are 'last_1m', 'last_5m', 'last_10m', 'last_15m', 'last_30m', 'last_1h', 'last_2h', 'last_4h', 'last_1d'."
  default     = "last_5m"

  validation {
    condition     = contains(["last_1m", "last_5m", "last_10m", "last_15m", "last_30m", "last_1h", "last_2h", "last_4h", "last_1d"], var.runtime_counter_is_stuck_timeframe)
    error_message = "The 'runtime_counter_is_stuck_timeframe' must be one of the following values: 'last_1m', 'last_5m', 'last_10m', 'last_15m', 'last_30m', 'last_1h', 'last_2h', 'last_4h', 'last_1d'."
  }
}

variable "runtime_counter_is_stuck_threshold_critical" {
  default     = 0
  description = "Critical alert threshold for the runtime counter, beyond which the bridge node's performance is considered severely impacted."
}

variable "runtime_counter_is_stuck_threshold_critical_recovery" {
  default     = 1
  description = "Critical alert recovery threshold for the runtime counter. When the runtime counter is stuck beyond this threshold, the bridge node's performance is considered severely impacted, triggering recovery measures."
}

variable "low_header_sync_rate_enabled" {
  description = "Turns on monitoring for low headers synchronization rate."
  type        = string
  default     = "true"
}

variable "low_header_sync_rate_message" {
  description = "Allows for a custom alert message when the headers synchronization rate falls below expected levels, aiding in prompt issue identification."
  type        = string
  default     = ""
}

variable "low_header_sync_rate_escalation_message" {
  description = "A custom message to include with a re-notification for the low headers synchronization rate monitor escalation."
  type        = string
  default     = ""
}

variable "low_header_sync_rate_aggregator" {
  description = "Aggregator function (e.g., 'avg') for calculating the headers synchronization rate"
  type        = string
  default     = "avg"

  validation {
    condition     = contains(["min", "max", "avg"], var.low_header_sync_rate_aggregator)
    error_message = "The 'low_header_sync_rate_aggregator' must be one of the following values: 'min', 'max', 'avg'."
  }
}

variable "low_header_sync_rate_timeframe" {
  description = "Observation period for headers synchronization rate."
  type        = string
  default     = "last_5m"

  validation {
    condition     = contains(["last_1m", "last_5m", "last_10m", "last_15m", "last_30m", "last_1h", "last_2h", "last_4h", "last_1d"], var.low_header_sync_rate_timeframe)
    error_message = "The 'low_header_sync_rate_timeframe' must be one of the following values: 'last_1m', 'last_5m', 'last_10m', 'last_15m', 'last_30m', 'last_1h', 'last_2h', 'last_4h', 'last_1d'."
  }
}

variable "low_header_sync_rate_shift_timeframe" {
  description = "Specifies the comparison timeframe for assessing changes in the header synchronization rate, aiding in trend analysis and anomaly detection."
  type        = string
  default     = "last_10m"
}

variable "low_header_sync_rate_threshold_critical" {
  default     = 0
  description = "Critical threshold for headers synchronization rate, in certificates per second, below which the validator's activity is considered alarmingly low."
}

variable "low_header_sync_rate_threshold_critical_recovery" {
  default     = 0.1
  description = "Critical alert recovery threshold for the headers synchronization rate. When the headers synchronization rate falls below this threshold, indicating potential issues with synchronization, recovery measures are triggered to ensure optimal performance of the bridge node."
}