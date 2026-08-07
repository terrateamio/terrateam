# Variables for IDP Platform Infrastructure Component

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|[3-9][0-9])$", var.cluster_version))
    error_message = "Cluster version must be 1.24 or higher."
  }
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Enable public API server endpoint"
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDR blocks that can access the public API server endpoint"
  default     = [] # Require explicit CIDR configuration - no default public access

  validation {
    condition = alltrue([
      for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "domain_name" {
  type        = string
  description = "Primary domain name for the IDP platform"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid DNS domain."
  }
}

variable "database_engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "15.4"

  validation {
    condition     = can(regex("^1[2-9]\\.[0-9]+$", var.database_engine_version))
    error_message = "Database engine version must be PostgreSQL 12 or higher."
  }
}

variable "database_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.r6g.large"

  validation {
    condition = contains([
      "db.t4g.micro", "db.t4g.small", "db.t4g.medium", "db.t4g.large",
      "db.r6g.large", "db.r6g.xlarge", "db.r6g.2xlarge", "db.r6g.4xlarge",
      "db.r6i.large", "db.r6i.xlarge", "db.r6i.2xlarge", "db.r6i.4xlarge"
    ], var.database_instance_class)
    error_message = "Database instance class must be a supported RDS instance type."
  }
}

variable "database_allocated_storage" {
  type        = number
  description = "Initial allocated storage in GB"
  default     = 100

  validation {
    condition     = var.database_allocated_storage >= 20 && var.database_allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "database_max_allocated_storage" {
  type        = number
  description = "Maximum allocated storage in GB for autoscaling"
  default     = 1000

  validation {
    condition     = var.database_max_allocated_storage >= var.database_allocated_storage
    error_message = "Maximum allocated storage must be greater than or equal to allocated storage."
  }
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node type"
  default     = "cache.r7g.large"

  validation {
    condition = contains([
      "cache.t4g.micro", "cache.t4g.small", "cache.t4g.medium",
      "cache.r7g.large", "cache.r7g.xlarge", "cache.r7g.2xlarge",
      "cache.r6g.large", "cache.r6g.xlarge", "cache.r6g.2xlarge"
    ], var.redis_node_type)
    error_message = "Redis node type must be a supported ElastiCache instance type."
  }
}

variable "redis_num_cache_clusters" {
  type        = number
  description = "Number of Redis cache clusters for high availability"
  default     = 2

  validation {
    condition     = var.redis_num_cache_clusters >= 1 && var.redis_num_cache_clusters <= 6
    error_message = "Number of cache clusters must be between 1 and 6."
  }
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable comprehensive monitoring and logging"
  default     = true
}

variable "enable_backup" {
  type        = bool
  description = "Enable automated backup solutions"
  default     = true
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain backups"
  default     = 30

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention days must be between 1 and 365."
  }
}

variable "enable_disaster_recovery" {
  type        = bool
  description = "Enable disaster recovery setup"
  default     = false
}

variable "dr_region" {
  type        = string
  description = "Disaster recovery region"
  default     = "us-west-2"

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
      "ap-northeast-1", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2"
    ], var.dr_region)
    error_message = "DR region must be a valid AWS region."
  }
}

variable "enable_cost_optimization" {
  type        = bool
  description = "Enable cost optimization features like Spot instances"
  default     = true
}

variable "enable_security_scanning" {
  type        = bool
  description = "Enable security scanning and compliance checks"
  default     = true
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access the platform"
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All values must be valid CIDR blocks."
  }
}

variable "notification_endpoints" {
  type = object({
    email = optional(list(string), [])
    slack = optional(string, "")
    teams = optional(string, "")
  })
  description = "Notification endpoints for alerts and events"
  default = {
    email = []
    slack = ""
    teams = ""
  }
}

variable "feature_flags" {
  type = object({
    enable_argocd_integration    = optional(bool, true)
    enable_cost_analysis         = optional(bool, true)
    enable_compliance_checking   = optional(bool, true)
    enable_drift_detection       = optional(bool, true)
    enable_auto_scaling          = optional(bool, true)
    enable_blue_green_deployment = optional(bool, false)
    enable_canary_deployment     = optional(bool, false)
  })
  description = "Feature flags to enable/disable platform capabilities"
  default = {
    enable_argocd_integration    = true
    enable_cost_analysis         = true
    enable_compliance_checking   = true
    enable_drift_detection       = true
    enable_auto_scaling          = true
    enable_blue_green_deployment = false
    enable_canary_deployment     = false
  }
}

variable "resource_tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.resource_tags :
      can(regex("^[a-zA-Z0-9+\\-=._:/@]{1,128}$", tag_key)) &&
      can(regex("^[a-zA-Z0-9+\\-=._:/@\\s]{0,256}$", tag_value))
    ])
    error_message = "Tag keys and values must comply with AWS tagging requirements."
  }
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention period in days"
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "performance_insights_retention_period" {
  type        = number
  description = "RDS Performance Insights retention period in days"
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention period must be either 7 or 731 days."
  }
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for critical resources"
  default     = null # Will be determined based on environment
}

variable "maintenance_window" {
  type = object({
    database = optional(string, "sun:04:00-sun:05:00")
    redis    = optional(string, "sun:05:00-sun:07:00")
    eks      = optional(string, "sun:02:00-sun:03:00")
  })
  description = "Maintenance windows for different services"
  default = {
    database = "sun:04:00-sun:05:00"
    redis    = "sun:05:00-sun:07:00"
    eks      = "sun:02:00-sun:03:00"
  }

  validation {
    condition = alltrue([
      for window in values(var.maintenance_window) :
      can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", window))
    ])
    error_message = "Maintenance windows must be in the format 'ddd:hh:mm-ddd:hh:mm'."
  }
}

variable "backup_window" {
  type        = string
  description = "Database backup window"
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.backup_window))
    error_message = "Backup window must be in the format 'hh:mm-hh:mm'."
  }
}