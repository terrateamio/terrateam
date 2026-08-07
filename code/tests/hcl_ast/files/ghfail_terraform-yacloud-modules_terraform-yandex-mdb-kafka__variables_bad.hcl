variable "cluster_name" {
  description = "Name of the Kafka cluster"
  type        = string
}

variable "cluster_description" {
  description = "Description of the Kafka cluster"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "The ID of the folder that the resource belongs to"
  type        = string
  default     = null
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the Kafka cluster"
  type        = map(string)
  default     = {}
}

variable "network_id" {
  description = "ID of the network, to which the Kafka cluster belongs"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets, to which the Kafka cluster belongs"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Deployment environment of the Kafka cluster"
  type        = string
  default     = "PRODUCTION"
}

variable "kafka_version" {
  description = "Version of the Kafka server"
  type        = string
  validation {
    condition     = contains(["3.7", "3.8", "3.9", "4.0"], var.kafka_version)
    error_message = "The Kafka server version must be one of: 3.7, 3.8, 3.9, 4.0"
  }
}

variable "brokers_count" {
  description = "Count of brokers per availability zone"
  type        = number
  default     = 1
  validation {
    condition     = var.brokers_count >= 1 && var.brokers_count <= 10
    error_message = "Brokers count must be between 1 and 10 per zone"
  }
}

variable "zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Determines whether each broker will be assigned a public IP address"
  type        = bool
  default     = false
}

variable "schema_registry" {
  description = "Enables managed schema registry on cluster"
  type        = bool
  default     = false
}

variable "unmanaged_topics" {
  description = "Enables unmanaged topics (topics created via yandex_mdb_kafka_topic)"
  type        = bool
  default     = false
}

variable "kafka_resource_preset_id" {
  description = "The ID of the preset for computational resources available to a Kafka host"
  type        = string
}

variable "kafka_disk_size" {
  description = "Volume of the storage available to a Kafka host, in gigabytes"
  type        = number
  validation {
    condition     = var.kafka_disk_size >= 10 && var.kafka_disk_size <= 4096
    error_message = "Kafka disk size must be between 10GB and 4096GB"
  }
}

variable "kafka_disk_type_id" {
  description = "Type of the storage of Kafka hosts"
  type        = string
}

variable "kafka_compression_type" {
  description = "Kafka server compression type"
  type        = string
  default     = null
}

variable "kafka_log_flush_interval_messages" {
  description = "Kafka server log flush interval messages"
  type        = number
  default     = null
}

variable "kafka_log_flush_interval_ms" {
  description = "Kafka server log flush interval milliseconds"
  type        = number
  default     = null
}

variable "kafka_log_flush_scheduler_interval_ms" {
  description = "Kafka server log flush scheduler interval milliseconds"
  type        = number
  default     = null
}

variable "kafka_log_retention_bytes" {
  description = "Kafka server log retention bytes"
  type        = number
  default     = null
}

variable "kafka_log_retention_hours" {
  description = "Kafka server log retention hours"
  type        = number
  default     = null
}

variable "kafka_log_retention_minutes" {
  description = "Kafka server log retention minutes"
  type        = number
  default     = null
}

variable "kafka_log_retention_ms" {
  description = "Kafka server log retention milliseconds"
  type        = number
  default     = null
}

variable "kafka_log_segment_bytes" {
  description = "Kafka server log segment bytes"
  type        = number
  default     = null
}

variable "kafka_log_preallocate" {
  description = "Should pre allocate file when create new segment?"
  type        = bool
  default     = false
}

variable "kafka_num_partitions" {
  description = "Kafka server number of partitions"
  type        = number
  default     = null
}

variable "kafka_default_replication_factor" {
  description = "Kafka server default replication factor"
  type        = number
  default     = null
}

variable "kafka_message_max_bytes" {
  description = "Kafka server message max bytes"
  type        = number
  default     = null
}

variable "kafka_replica_fetch_max_bytes" {
  description = "Kafka server replica fetch max bytes"
  type        = number
  default     = null
}

variable "kafka_ssl_cipher_suites" {
  description = "Kafka server SSL cipher suites"
  type        = list(string)
  default     = null
}

variable "kafka_offsets_retention_minutes" {
  description = "Kafka server offsets retention minutes"
  type        = number
  default     = null
}

variable "kafka_sasl_enabled_mechanisms" {
  description = "Kafka server SASL enabled mechanisms"
  type        = list(string)
  default     = null
}

variable "kraft_resource_preset_id" {
  description = "The ID of the preset for computational resources available to a KRaft host"
  type        = string
  default     = null
}

variable "kraft_disk_size" {
  description = "Volume of the storage available to a KRaft host, in gigabytes"
  type        = number
  default     = null
  validation {
    condition     = var.kraft_disk_size == null ? true : var.kraft_disk_size >= 10
    error_message = "KRaft disk size must be at least 10GB if specified"
  }
}

variable "kraft_disk_type_id" {
  description = "Type of the storage of KRaft hosts"
  type        = string
  default     = null
}

variable "rest_api_enabled" {
  description = "Enable REST API for Kafka cluster"
  type        = bool
  default     = false
}

variable "kafka_ui_enabled" {
  description = "Enable Kafka UI for cluster"
  type        = bool
  default     = false
}

variable "disk_size_autoscaling" {
  description = "Disk size autoscaling configuration"
  type = object({
    disk_size_limit           = number
    planned_usage_threshold   = optional(number)
    emergency_usage_threshold = optional(number)
  })
  default = null
  validation {
    condition = var.disk_size_autoscaling == null ? true : (
      var.disk_size_autoscaling.disk_size_limit >= 10 &&
      (var.disk_size_autoscaling.planned_usage_threshold == null ? true : var.disk_size_autoscaling.planned_usage_threshold >= 0 && var.disk_size_autoscaling.planned_usage_threshold <= 100) &&
      (var.disk_size_autoscaling.emergency_usage_threshold == null ? true : var.disk_size_autoscaling.emergency_usage_threshold >= 0 && var.disk_size_autoscaling.emergency_usage_threshold <= 100)
    )
    error_message = "Disk size autoscaling validation failed: disk_size_limit must be >= 10GB, thresholds must be between 0 and 100"
  }
}

variable "zookeeper_resource_preset_id" {
  description = "The ID of the preset for computational resources available to a ZooKeeper host"
  type        = string
  default     = null
}

variable "zookeeper_disk_size" {
  description = "Volume of the storage available to a ZooKeeper host, in gigabytes"
  type        = number
  default     = null
}

variable "zookeeper_disk_type_id" {
  description = "Type of the storage of ZooKeeper hosts"
  type        = string
  default     = null
}

variable "data_transfer_access" {
  description = "Allow access for DataTransfer"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Security group ids, to which the Kafka cluster belongs"
  type        = list(string)
  default     = []
}

variable "host_group_ids" {
  description = "A list of IDs of the host groups to place VMs of the cluster on"
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "Inhibits deletion of the cluster"
  type        = bool
  default     = false
}

variable "maintenance_window_type" {
  description = "Type of maintenance window"
  type        = string
}

variable "maintenance_window_day" {
  description = "Day of the week for maintenance window"
  type        = string
  default     = null
  validation {
    condition     = var.maintenance_window_day == null ? true : contains(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], var.maintenance_window_day)
    error_message = "Maintenance window day must be one of: MON, TUE, WED, THU, FRI, SAT, SUN"
  }
}

variable "maintenance_window_hour" {
  description = "Hour of the day in UTC for maintenance window"
  type        = number
  default     = null
  validation {
    condition     = var.maintenance_window_hour == null ? true : var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23"
  }
}

variable "topics" {
  description = <<EOF
    (Required) This is a list of Kafka topics to create.

    Required values:
      - name               - The name of the topic.
      - partitions         - The number of partitions for the topic.
      - replication_factor - The replication factor for the topic.

    Optional values:
      - config             - Configuration settings for the topic. The list is documented below.
        - cleanup_policy        - (Optional) The cleanup policy for the topic. Allowed values: `CLEANUP_POLICY_DELETE`, `CLEANUP_POLICY_COMPACT`, `CLEANUP_POLICY_COMPACT_AND_DELETE`.
        - compression_type      - (Optional) The compression type for the topic. Allowed values: `COMPRESSION_TYPE_SNAPPY`, `COMPRESSION_TYPE_GZIP`, `COMPRESSION_TYPE_PRODUCER`, `COMPRESSION_TYPE_UNCOMPRESSED`, `COMPRESSION_TYPE_ZSTD`, `COMPRESSION_TYPE_LZ4`.
        - delete_retention_ms   - (Optional) The time to retain delete tombstone markers for log compacted topics.
        - file_delete_delay_ms  - (Optional) The time to wait before deleting a file from the filesystem.
        - flush_messages        - (Optional) The number of messages accumulated on a log partition before messages are flushed to disk.
        - flush_ms              - (Optional) The maximum time in milliseconds that a message in any topic is kept in memory before flushed to disk.
        - min_compaction_lag_ms - (Optional) The minimum time a message will remain uncompacted in the log.
        - retention_bytes       - (Optional) The maximum size a partition can grow to before Kafka will discard old log segments to free up space.
        - retention_ms          - (Optional) The maximum time Kafka will retain messages in a topic.
        - max_message_bytes     - (Optional) The largest record batch size allowed by Kafka.
        - min_insync_replicas   - (Optional) The minimum number of replicas that must acknowledge a write for the write to be considered successful.
        - segment_bytes         - (Optional) The maximum size of a single log file.
        - preallocate           - (Optional) Whether to preallocate the file on disk.
        - message_timestamp_type - (Optional) Timestamp type. Allowed values: `MESSAGE_TIMESTAMP_TYPE_CREATE_TIME`, `MESSAGE_TIMESTAMP_TYPE_LOG_APPEND_TIME`.
  EOF

  type = list(object({
    name               = string
    partitions         = number
    replication_factor = number
    config = optional(object({
      cleanup_policy         = optional(string, "CLEANUP_POLICY_DELETE")
      compression_type       = optional(string, "COMPRESSION_TYPE_PRODUCER")
      delete_retention_ms    = optional(number, 86400000)
      file_delete_delay_ms   = optional(number, 60000)
      flush_messages         = optional(number, 9223372036854775807)
      flush_ms               = optional(number, 9223372036854775807)
      min_compaction_lag_ms  = optional(number, 0)
      retention_bytes        = optional(number, -1)
      retention_ms           = optional(number, 604800000)
      max_message_bytes      = optional(number, 1048588)
      min_insync_replicas    = optional(number, 1)
      segment_bytes          = optional(number, 1073741824)
      preallocate            = optional(bool, false)
      message_timestamp_type = optional(string, "MESSAGE_TIMESTAMP_TYPE_CREATE_TIME")
    }), null)
  }))
  default = []
}

variable "users" {
  description = "List of Kafka users to create"
  type = list(object({
    name     = string
    password = string
    permissions = list(object({
      topic_name  = string
      role        = string
      allow_hosts = list(string)
    }))
  }))
  default = []
}


variable "timeouts" {
  description = "Timeout settings for cluster operations"
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = null
}
