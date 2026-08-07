#
# yandex cloud coordinates
#
variable "folder_id" {
  description = <<EOF
    The ID of the Yandex Cloud Folder that the resources belongs to.

    Allows to create bucket in different folder.
    It will try to create bucket using IAM-token in provider config, not using access_key.
    If omitted, folder_id specified in provider config and access_key is used.
  EOF
  type        = string
  default     = null
}

#
# naming
#
variable "name" {
  description = "OpenSearch cluster name"
  type        = string
}

variable "description" {
  description = "OpenSearch cluster description"
  type        = string
  default     = ""
}

variable "labels" {
  description = <<EOF
    Object for setting tags (or labels) for bucket.
    For more information see https://cloud.yandex.com/en/docs/storage/concepts/tags.
  EOF
  type        = map(string)
  default     = {}
}

#
# OpenSearch common settings
#
variable "environment" {
  description = "The deployment environment of the OpenSearch cluster. PRESTABLE is for testing and development, PRODUCTION is for production workloads with higher availability and performance guarantees."
  type        = string
  validation {
    condition = contains([
      "PRESTABLE", "PRODUCTION"
    ], var.environment)
    error_message = "Available values are \"PRESTABLE\", \"PRODUCTION\" (case sensitive)."
  }
  default = "PRODUCTION"
}

variable "service_account_id" {
  description = "The ID of the service account that will be used by the OpenSearch cluster for accessing other Yandex Cloud resources. If not specified, a default service account will be used."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enables deletion protection for the OpenSearch cluster. When enabled, prevents accidental deletion of the cluster and its data."
  type        = bool
  default     = false
}

#
# OpenSearch cluster network
#
variable "network_id" {
  description = "ID of the network, to which the OpenSearch cluster belongs."
  type        = string
}

variable "security_group_ids" {
  description = "A set of ids of security groups assigned to hosts of the cluster."
  type        = list(string)
  default     = []
}

#
# OpenSearch config
#
variable "opensearch_version" {
  description = "The version of OpenSearch to deploy. If not specified, the latest available version will be used."
  type        = string
  default     = null
}

variable "generate_admin_password" {
  description = "If true, a random admin password will be generated for the OpenSearch cluster. If false, the admin_password variable must be provided."
  type        = bool
  default     = true
}
variable "admin_password" {
  description = "The password for the admin user of the OpenSearch cluster. Only used if generate_admin_password is false. Must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character."
  type        = string
  default     = null
  sensitive   = true
  validation {
    condition     = var.generate_admin_password || try(var.admin_password != null && length(var.admin_password) >= 8 && can(regex("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^a-zA-Z\\d]).{8,}$", var.admin_password)), false)
    error_message = "If generate_admin_password is false you must provide admin_password with at least 8 characters, including uppercase, lowercase, digit, and special character."
  }
}

variable "opensearch_plugins" {
  description = "A set of requested OpenSearch plugins."
  type        = list(string)
  default     = []
}

#
# OpenSearch nodes
#
variable "opensearch_nodes" {
  description = <<EOF
    A map that contains information about OpenSearch cluster nodes.
    Configuration attributes:
      resources        - (Required) Resources allocated to hosts of this OpenSearch node group.
      hosts_count      - (Required) Number of hosts in this node group. Must be at least 1.
      zones_ids        - (Required) A set of availability zones where hosts of node group may be allocated.
      subnet_ids       - (Optional) A set of the subnets, to which the hosts belongs. The subnets must be a part of the network to which the cluster belongs.
      assign_public_ip - (Optional) Sets whether the hosts should get a public IP address on creation.
      roles            - (Optional) A set of OpenSearch roles assigned to hosts.
  EOF
  nullable    = false
  type = map(object({
    resources = object({
      resource_preset_id = string
      disk_size          = string
      disk_type_id       = string
    })
    hosts_count = number
    zones_ids = optional(
      list(string), ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
    )
    subnet_ids       = optional(list(string))
    assign_public_ip = bool
    roles            = optional(list(string))
  }))
  validation {
    condition = alltrue([
      for group_name, group in var.opensearch_nodes :
      group.hosts_count >= 1 &&
      group.hosts_count <= 10 &&
      can(tonumber(group.resources.disk_size)) &&
      tonumber(group.resources.disk_size) >= 10737418240 && # 10GB minimum
      contains(["network-hdd", "network-ssd", "local-ssd", "network-ssd-nonreplicated"], group.resources.disk_type_id) &&
      alltrue([for zone in group.zones_ids : contains(["ru-central1-a", "ru-central1-b", "ru-central1-d"], zone)]) &&
      (group.roles == null || alltrue([for role in group.roles : contains(["data", "manager", "ingest", "coordinator"], role)]))
    ])
    error_message = <<EOF
Invalid OpenSearch node configuration:
- hosts_count must be between 1 and 10
- disk_size must be at least 10GB (10737418240 bytes)
- disk_type_id must be one of: network-hdd, network-ssd, local-ssd, network-ssd-nonreplicated
- zones_ids must contain valid Yandex Cloud availability zones: ru-central1-a, ru-central1-b, ru-central1-d
- roles must be one of: data, manager, ingest, coordinator
EOF
  }
  default = {}
}

#
# Dashboard nodes
#
variable "dashboard_nodes" {
  description = <<EOF
    A map that contains information about OpenSearch dashboard nodes.
    Configuration attributes:
      resources        - (Required) Resources allocated to hosts of this OpenSearch node group.
      hosts_count      - (Required) Number of hosts in this node group. Must be at least 1.
      zones_ids        - (Required) A set of availability zones where hosts of node group may be allocated.
      subnet_ids       - (Optional) A set of the subnets, to which the hosts belongs. The subnets must be a part of the network to which the cluster belongs.
      assign_public_ip - (Optional) Sets whether the hosts should get a public IP address on creation.
      roles            - (Optional) A set of OpenSearch roles assigned to hosts.
  EOF
  nullable    = false
  type = map(object({
    resources = object({
      resource_preset_id = string
      disk_size          = string
      disk_type_id       = string
    })
    hosts_count = number
    zones_ids = optional(
      list(string), ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
    )
    subnet_ids       = optional(list(string), [])
    assign_public_ip = bool
  }))
  validation {
    condition = alltrue([
      for group_name, group in var.dashboard_nodes :
      group.hosts_count >= 1 &&
      group.hosts_count <= 5 &&
      can(tonumber(group.resources.disk_size)) &&
      tonumber(group.resources.disk_size) >= 10737418240 && # 10GB minimum
      contains(["network-hdd", "network-ssd", "local-ssd", "network-ssd-nonreplicated"], group.resources.disk_type_id) &&
      alltrue([for zone in group.zones_ids : contains(["ru-central1-a", "ru-central1-b", "ru-central1-d"], zone)])
    ])
    error_message = <<EOF
Invalid Dashboard node configuration:
- hosts_count must be between 1 and 5
- disk_size must be at least 10GB (10737418240 bytes)
- disk_type_id must be one of: network-hdd, network-ssd, local-ssd, network-ssd-nonreplicated
- zones_ids must contain valid Yandex Cloud availability zones: ru-central1-a, ru-central1-b, ru-central1-d
EOF
  }
  default = {}
}

#
# OpenSearch authentication and encryption
#
variable "disk_encryption_key_id" {
  description = "ID of the KMS key for cluster disk encryption. If not specified, encryption will be disabled."
  type        = string
  default     = null
}

#
# OpenSearch maintenance
#
variable "maintenance_window_type" {
  description = "The type of maintenance window for the OpenSearch cluster. ANYTIME allows maintenance at any time, WEEKLY requires specifying a specific day and hour."
  type        = string
  validation {
    condition = contains([
      "ANYTIME", "WEEKLY"
    ], var.maintenance_window_type)
    error_message = "Available values are \"ANYTIME\", \"WEEKLY\" (case sensitive)."
  }
  default = "ANYTIME"
}

variable "maintenance_window_hour" {
  description = "The hour of day in UTC time zone (0-24) for the weekly maintenance window. Only used when maintenance_window_type is WEEKLY."
  type        = number
  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 24
    error_message = "The variable must be a number between 0 and 24 (inclusive)."
  }
  default = null
}

variable "maintenance_window_day" {
  description = "The day of the week for the weekly maintenance window. Only used when maintenance_window_type is WEEKLY."
  type        = string
  validation {
    condition = contains([
      "MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"
    ], var.maintenance_window_day)
    error_message = "Available values are \"MON\", \"TUE\", \"WED\", \"THU\", \"FRI\", \"SAT\", \"SUN\" (case sensitive)."
  }
  default = null
}


variable "timeouts" {
  description = "Timeout settings for cluster operations"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
