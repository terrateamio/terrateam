#
# AWS Backup vault
#
variable "vault_name" {
  description = "Name of the backup vault to create. If not given, AWS use default"
  type        = string
  default     = null

  validation {
    condition     = var.vault_name == null ? true : can(regex("^[0-9A-Za-z-_]{2,50}$", var.vault_name))
    error_message = "The vault_name must be between 2 and 50 characters, contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "vault_name_validation_bypass" {
  description = "Bypass the vault name word validation (test, temp, delete, remove, default). Set to true for existing vaults with these words. Only disables word validation, format validation remains active."
  type        = bool
  default     = false
}

variable "vault_kms_key_arn" {
  description = "The server-side encryption key that is used to protect your backups"
  type        = string
  default     = null

  validation {
    condition = var.vault_kms_key_arn == null ? true : (
      can(regex("^arn:aws:kms:", var.vault_kms_key_arn)) &&
      !can(regex("alias/aws/", var.vault_kms_key_arn)) # Prevent AWS managed keys
    )
    error_message = "The vault_kms_key_arn must be a valid customer-managed KMS key ARN. AWS managed keys (alias/aws/*) are not recommended for security reasons."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "vault_force_destroy" {
  description = "A boolean that indicates that all recovery points stored in the vault are deleted so that the vault can be destroyed without error"
  type        = bool
  default     = false
}

variable "vault_type" {
  description = "Type of backup vault to create. Valid values are 'standard' (default) or 'logically_air_gapped'"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "logically_air_gapped"], var.vault_type)
    error_message = "The vault_type must be either 'standard' or 'logically_air_gapped'."
  }
}

#
# AWS Backup vault policy configuration
#
variable "vault_policy" {
  description = "IAM policy document for the backup vault access control. Enables cross-account backup access, resource-specific permissions, and compliance controls. Must be valid JSON. Leave null to disable vault policy."
  type        = string
  default     = null

  validation {
    condition     = var.vault_policy == null ? true : can(jsondecode(var.vault_policy))
    error_message = "The vault_policy must be a valid JSON policy document."
  }

  validation {
    condition = var.vault_policy == null ? true : (
      can(jsondecode(var.vault_policy)) ?
      can(lookup(jsondecode(var.vault_policy), "Version", null)) : false
    )
    error_message = "The vault_policy must include a Version field (typically '2012-10-17')."
  }

}

#
# AWS Backup vault lock configuration
#
variable "locked" {
  description = "Change to true to add a lock configuration for the backup vault"
  type        = bool
  default     = false
}

variable "changeable_for_days" {
  description = "The number of days before the lock date. If omitted creates a vault lock in governance mode, otherwise it will create a vault lock in compliance mode"
  type        = number
  default     = null

  validation {
    condition     = var.changeable_for_days == null ? true : var.changeable_for_days >= 3 && var.changeable_for_days <= 365
    error_message = "changeable_for_days must be between 3 and 365 days. This parameter controls the vault lock compliance period - the number of days before the lock becomes immutable."
  }
}

variable "max_retention_days" {
  description = "The maximum retention period that the vault retains its recovery points. Required when vault_type is 'logically_air_gapped'"
  type        = number
  default     = null

  validation {
    condition     = var.max_retention_days == null ? true : (var.max_retention_days >= 1 && var.max_retention_days <= 2555)
    error_message = "The max_retention_days must be between 1 and 2555 days (7 years maximum for compliance)."
  }


}

variable "min_retention_days" {
  description = "The minimum retention period that the vault retains its recovery points. Required when vault_type is 'logically_air_gapped'"
  type        = number
  default     = null

  validation {
    condition     = var.min_retention_days == null ? true : (var.min_retention_days >= 7 && var.min_retention_days <= 2555)
    error_message = "The min_retention_days must be between 7 and 2555 days (minimum 7 days for compliance requirements)."
  }

}

#
# AWS Backup plan
#
variable "plan_name" {
  description = "The display name of a backup plan"
  type        = string
  default     = null
}

variable "plans" {
  description = "A map of backup plans to create. Each key is the plan name and each value is a map of plan configuration."
  type = map(object({
    name = optional(string)
    rules = list(object({
      name                         = string
      target_vault_name            = optional(string)
      schedule                     = optional(string)
      schedule_expression_timezone = optional(string)
      start_window                 = optional(number)
      completion_window            = optional(number)
      enable_continuous_backup     = optional(bool)
      lifecycle = optional(object({
        cold_storage_after                        = optional(number)
        delete_after                              = number
        opt_in_to_archive_for_supported_resources = optional(bool)
      }))
      recovery_point_tags = optional(map(string))
      copy_actions = optional(list(object({
        destination_vault_arn = string
        lifecycle = optional(object({
          cold_storage_after                        = optional(number)
          delete_after                              = number
          opt_in_to_archive_for_supported_resources = optional(bool)
        }))
      })), [])
    }))
    selections = optional(map(object({
      resources     = optional(list(string))
      not_resources = optional(list(string))
      conditions = optional(object({
        string_equals     = optional(map(string))
        string_not_equals = optional(map(string))
        string_like       = optional(map(string))
        string_not_like   = optional(map(string))
      }))
      selection_tags = optional(list(object({
        type  = string
        key   = string
        value = string
      })))
    })), {})
  }))
  default = {}


  validation {
    condition = alltrue([
      for plan_name, plan in var.plans : alltrue([
        for rule in plan.rules : alltrue([
          # Validate main rule lifecycle delete_after
          try(rule.lifecycle.delete_after, 90) >= 1,
          # Validate copy actions lifecycle delete_after
          alltrue([
            for copy_action in rule.copy_actions :
            try(copy_action.lifecycle.delete_after, 90) >= 1
          ])
        ])
      ])
    ])
    error_message = "Plans validation failed: delete_after must be ≥ 1 day. This applies to both main rule lifecycle and copy action lifecycle."
  }

  validation {
    condition = alltrue([
      for plan_name, plan in var.plans : alltrue([
        for rule in plan.rules : rule.schedule == null || can(regex("^(cron\\([^)]+\\)|rate\\([1-9][0-9]* (minute|hour|day)s?\\))$", rule.schedule))
      ])
    ])
    error_message = "Plans validation failed: Schedule must be a valid cron expression (e.g., 'cron(0 12 * * ? *)') or rate expression (e.g., 'rate(1 day)'). AWS Backup uses 6-field cron format."
  }

  validation {
    condition = alltrue([
      for plan_name, plan in var.plans : alltrue([
        for rule in plan.rules :
        try(rule.start_window, null) != null && try(rule.completion_window, null) != null ?
        rule.completion_window >= rule.start_window + 60 : true
      ])
    ])
    error_message = "Plans validation failed: completion_window must be at least 60 minutes longer than start_window."
  }



}

# Default rule
variable "rule_name" {
  description = "An display name for a backup rule"
  type        = string
  default     = null
}

variable "rule_schedule" {
  description = "A CRON expression specifying when AWS Backup initiates a backup job"
  type        = string
  default     = null

  validation {
    condition     = var.rule_schedule == null ? true : can(regex("^(cron\\([^)]+\\)|rate\\([1-9][0-9]* (minute|hour|day)s?\\))$", var.rule_schedule))
    error_message = "Schedule must be a valid cron expression (e.g., 'cron(0 12 * * ? *)') or rate expression (e.g., 'rate(1 day)'). AWS Backup uses 6-field cron format."
  }

  validation {
    condition = var.rule_schedule == null ? true : (
      can(regex("^rate\\(", var.rule_schedule)) ?
      !can(regex("rate\\(([1-9]|1[0-4])\\s+minutes?\\)", var.rule_schedule)) : true
    )
    error_message = "Rate expressions should not be more frequent than every 15 minutes for backup operations. Use 'rate(15 minutes)' or higher intervals."
  }
}

variable "rule_schedule_expression_timezone" {
  description = "The timezone in which the schedule expression is set for the backup rule. Default is 'Etc/UTC'. Valid values are IANA timezone strings (e.g., 'America/New_York', 'Europe/London', 'Asia/Tokyo')."
  type        = string
  default     = null

  validation {
    condition     = var.rule_schedule_expression_timezone == null ? true : can(regex("^[A-Za-z_]+(/[A-Za-z0-9_+-]+)+$", var.rule_schedule_expression_timezone))
    error_message = "The schedule_expression_timezone must be a valid IANA timezone string (e.g., 'America/New_York', 'Europe/London', 'America/Argentina/Buenos_Aires')."
  }
}

variable "rule_start_window" {
  description = "The amount of time in minutes before beginning a backup"
  type        = number
  default     = null

  validation {
    condition     = var.rule_start_window == null || try(var.rule_start_window >= 60 && var.rule_start_window <= 43200, false)
    error_message = "The rule_start_window must be between 60 minutes (1 hour) and 43200 minutes (30 days)."
  }
}

variable "rule_completion_window" {
  description = "The amount of time AWS Backup attempts a backup before canceling the job and returning an error"
  type        = number
  default     = null

  validation {
    condition     = var.rule_completion_window == null || try(var.rule_completion_window >= 120 && var.rule_completion_window <= 43200, false)
    error_message = "The rule_completion_window must be between 120 minutes (2 hours) and 43200 minutes (30 days)."
  }
}

variable "rule_recovery_point_tags" {
  description = "Metadata that you can assign to help organize the resources that you create"
  type        = map(string)
  default     = {}
}

# Rule lifecycle
variable "rule_lifecycle_cold_storage_after" {
  description = "Specifies the number of days after creation that a recovery point is moved to cold storage"
  type        = number
  default     = null

  validation {
    condition     = var.rule_lifecycle_cold_storage_after == null || try(var.rule_lifecycle_cold_storage_after == 0 || var.rule_lifecycle_cold_storage_after >= 30, false)
    error_message = "The rule_lifecycle_cold_storage_after must be 0 (disabled) or at least 30 days (AWS minimum requirement). To disable cold storage, set to null or 0."
  }
}

variable "rule_lifecycle_delete_after" {
  description = "Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than `cold_storage_after`"
  type        = number
  default     = null

  validation {
    condition     = var.rule_lifecycle_delete_after == null || try(var.rule_lifecycle_delete_after >= 1, false)
    error_message = "The rule_lifecycle_delete_after must be at least 1 day."
  }
}

variable "rule_lifecycle_opt_in_to_archive" {
  description = "Enable automatic archive tier transitioning for supported resources according to lifecycle settings. This reduces storage costs for long-term retention by up to 80-90%."
  type        = bool
  default     = null
}

variable "rule_enable_continuous_backup" {
  description = "Enable continuous backups for supported resources."
  type        = bool
  default     = false
}

# Rules
variable "rules" {
  description = "A list of rule maps"
  type = list(object({
    name                         = string
    target_vault_name            = optional(string)
    schedule                     = optional(string)
    schedule_expression_timezone = optional(string)
    start_window                 = optional(number)
    completion_window            = optional(number)
    enable_continuous_backup     = optional(bool)
    lifecycle = optional(object({
      cold_storage_after                        = optional(number)
      delete_after                              = number
      opt_in_to_archive_for_supported_resources = optional(bool)
    }))
    recovery_point_tags = optional(map(string))
    copy_actions = optional(list(object({
      destination_vault_arn = string
      lifecycle = optional(object({
        cold_storage_after                        = optional(number)
        delete_after                              = number
        opt_in_to_archive_for_supported_resources = optional(bool)
      }))
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.rules : rule.schedule == null || can(regex("^(cron\\([^)]+\\)|rate\\([1-9][0-9]* (minute|hour|day)s?\\))$", rule.schedule))
    ])
    error_message = "Schedule must be a valid cron expression (e.g., 'cron(0 12 * * ? *)') or rate expression (e.g., 'rate(1 day)'). AWS Backup uses 6-field cron format."
  }

  validation {
    condition = alltrue([
      for rule in var.rules :
      (rule.start_window == null || rule.completion_window == null) ?
      true :
      (rule.completion_window >= rule.start_window + 60)
    ])
    error_message = "The completion_window must be at least 60 minutes longer than start_window."
  }

  validation {
    condition = alltrue([
      for rule in var.rules :
      try(rule.lifecycle.delete_after, 90) >= 1
    ])
    error_message = "Lifecycle validation failed: delete_after must be ≥ 1 day."
  }



}

# Selection
variable "selection_name" {
  description = "The display name of a resource selection document"
  type        = string
  default     = null
}

variable "selection_resources" {
  description = "An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to assign to a backup plan"
  type        = list(any)
  default     = []
}

variable "selection_not_resources" {
  description = "An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to exclude from a backup plan."
  type        = list(any)
  default     = []
}

variable "selection_conditions" {
  description = "A map of conditions that you define to assign resources to your backup plans using tags."
  type = object({
    string_equals     = optional(map(string))
    string_not_equals = optional(map(string))
    string_like       = optional(map(string))
    string_not_like   = optional(map(string))
  })
  default = {}
}

variable "selection_tags" {
  description = "List of tags for `selection_name` var, when using variable definition."
  type        = list(any)
  default     = []
}

# Selection
variable "selections" {
  description = "A list or map of backup selections. If passing a list, each selection must have a name attribute."
  type        = any
  default     = []

  validation {
    condition = can(tomap(var.selections)) || can([
      for s in var.selections : regex("^[a-zA-Z0-9-_]+$", s.name)
    ])
    error_message = "The selections must be either a map with valid keys or a list of objects with valid name attributes."
  }
}

variable "enabled" {
  description = "Change to false to avoid deploying any AWS Backup resources"
  type        = bool
  default     = true
}

# Windows Backup parameter
variable "windows_vss_backup" {
  description = "Enable Windows VSS backup option and create a VSS Windows backup"
  type        = bool
  default     = false
}

#
# Notifications
#
variable "notifications" {
  description = "Notification block which defines backup vault events and the SNS Topic ARN to send AWS Backup notifications to. Leave it empty to disable notifications"
  type        = any
  default     = {}
}

variable "notifications_disable_sns_policy" {
  description = "Disable the creation of the SNS policy. Enable if you need to manage the policy elsewhere."
  type        = bool
  default     = false
}

#
# IAM
#
variable "iam_role_arn" {
  description = "If configured, the module will attach this role to selections, instead of creating IAM resources by itself"
  type        = string
  default     = null

  validation {
    condition = var.iam_role_arn == null ? true : (
      can(regex("^arn:aws:iam::", var.iam_role_arn)) &&
      !can(regex("Administrator|Admin|PowerUser|FullAccess", var.iam_role_arn)) # Prevent overly permissive roles
    )
    error_message = "The iam_role_arn must be a valid IAM role ARN. Avoid using roles with Administrator, Admin, PowerUser, or FullAccess permissions for security reasons."
  }
}

variable "iam_role_name" {
  description = "Allow to set IAM role name, otherwise use predefined default"
  type        = string
  default     = ""
}

#
# AWS Backup Report Plan
#
variable "reports" {
  description = "The default cache behavior for this distribution."
  type = list(object({
    name               = string
    description        = optional(string, null)
    formats            = optional(list(string), null)
    s3_bucket_name     = string
    s3_key_prefix      = optional(string, null)
    report_template    = string
    accounts           = optional(list(string), null)
    organization_units = optional(list(string), null)
    regions            = optional(list(string), null)
    framework_arns     = optional(list(string), [])
  }))
  default = []
}

#
# AWS Backup Audit Manager Framework
#
variable "audit_framework" {
  description = "Configuration for AWS Backup Audit Manager framework"
  type = object({
    create      = bool
    name        = string
    description = optional(string)
    controls = list(object({
      name            = string
      parameter_name  = optional(string)
      parameter_value = optional(string)
    }))
  })
  default = {
    create      = false
    name        = null
    description = null
    controls    = []
  }
}

#
# AWS Organizations Backup Policy
#
variable "enable_org_policy" {
  description = "Enable AWS Organizations backup policy"
  type        = bool
  default     = false
}

variable "org_policy_name" {
  description = "Name of the AWS Organizations backup policy"
  type        = string
  default     = "backup-policy"
}

variable "org_policy_description" {
  description = "Description of the AWS Organizations backup policy"
  type        = string
  default     = "AWS Organizations backup policy"
}

variable "org_policy_target_id" {
  description = "Target ID (Root/OU/Account) for the backup policy"
  type        = string
  default     = null
}

variable "backup_policies" {
  description = "Map of backup policies to create"
  type = map(object({
    target_vault_name = string
    schedule          = string
    start_window      = number
    completion_window = number
    lifecycle = object({
      delete_after       = number
      cold_storage_after = optional(number)
    })
    recovery_point_tags      = optional(map(string))
    copy_actions             = optional(list(map(string)))
    enable_continuous_backup = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy in var.backup_policies : can(regex("^(cron\\([^)]+\\)|rate\\([1-9][0-9]* (minute|hour|day)s?\\))$", policy.schedule))
    ])
    error_message = "Schedule must be a valid cron expression (e.g., 'cron(0 12 * * ? *)') or rate expression (e.g., 'rate(1 day)'). AWS Backup uses 6-field cron format."
  }

  validation {
    condition = alltrue([
      for policy in var.backup_policies :
      can(regex("^rate\\(", policy.schedule)) ?
      !can(regex("rate\\(([1-9]|1[0-4])\\s+minutes?\\)", policy.schedule)) : true
    ])
    error_message = "Rate expressions should not be more frequent than every 15 minutes for backup operations. Use 'rate(15 minutes)' or higher intervals."
  }

  validation {
    condition = alltrue([
      for policy in var.backup_policies : policy.start_window >= 60 && policy.start_window <= 43200
    ])
    error_message = "The start_window must be between 60 minutes (1 hour) and 43200 minutes (30 days)."
  }

  validation {
    condition = alltrue([
      for policy in var.backup_policies :
      policy.completion_window >= policy.start_window + 60 &&
      policy.completion_window <= 43200
    ])
    error_message = "The completion_window must be at least 60 minutes longer than start_window and no more than 43200 minutes (30 days)."
  }

  validation {
    condition = alltrue([
      for policy in var.backup_policies :
      # Only validate cold_storage_after <= delete_after when both are non-null
      (try(policy.lifecycle.cold_storage_after, null) == null ||
        try(policy.lifecycle.delete_after, null) == null ||
      try(policy.lifecycle.cold_storage_after, 0) <= try(policy.lifecycle.delete_after, 90)) &&
      try(policy.lifecycle.delete_after, 90) >= 1 &&
      (try(policy.lifecycle.cold_storage_after, null) == null ||
        try(policy.lifecycle.cold_storage_after, 0) == 0 ||
      try(policy.lifecycle.cold_storage_after, 0) >= 30)
    ])
    error_message = "Lifecycle validation failed: cold_storage_after must be ≤ delete_after, delete_after ≥ 1 day. If cold_storage_after is specified, it must be 0 (disabled) or ≥ 30 days (AWS requirement). To disable cold storage, omit the cold_storage_after parameter entirely or set to 0."
  }
}

variable "backup_selections" {
  description = "Map of backup selections"
  type = map(object({
    resources     = optional(list(string))
    not_resources = optional(list(string))
    conditions = optional(object({
      string_equals     = optional(map(string))
      string_not_equals = optional(map(string))
      string_like       = optional(map(string))
      string_not_like   = optional(map(string))
    }))
    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for selection in var.backup_selections : selection.resources == null || alltrue([
        for resource in selection.resources :
        can(regex("^\\*$", resource)) ||
        can(regex("^arn:aws(-[a-z-]+)?:dynamodb:([a-z0-9-]+|\\*):([0-9]+|\\*):table/([a-zA-Z0-9._-]+|\\*)$", resource)) ||
        can(regex("^arn:aws(-[a-z-]+)?:ec2:([a-z0-9-]+|\\*):([0-9]+|\\*):(volume|instance)/([a-zA-Z0-9-]+|\\*)$", resource)) ||
        can(regex("^arn:aws(-[a-z-]+)?:rds:([a-z0-9-]+|\\*):([0-9]+|\\*):(db|cluster):([a-zA-Z0-9-]+|\\*)$", resource)) ||
        can(regex("^arn:aws(-[a-z-]+)?:elasticfilesystem:([a-z0-9-]+|\\*):([0-9]+|\\*):file-system/(fs-[a-zA-Z0-9]+|\\*)$", resource)) ||
        can(regex("^arn:aws(-[a-z-]+)?:fsx:([a-z0-9-]+|\\*):([0-9]+|\\*):file-system/(fs-[a-zA-Z0-9]+|\\*)$", resource)) ||
        can(regex("^arn:aws(-[a-z-]+)?:s3:::([a-zA-Z0-9.-]+|\\*)$", resource)) ||
        can(regex("^arn:aws(-[a-z-]+)?:storagegateway:([a-z0-9-]+|\\*):([0-9]+|\\*):gateway/([a-zA-Z0-9-]+|\\*)$", resource))
      ])
    ])
    error_message = "Resources must be valid ARNs for supported services (DynamoDB, EC2, RDS, EFS, FSx, S3, Storage Gateway) or wildcards ('*'). Wildcards are allowed in any ARN component. Examples: 'arn:aws:dynamodb:us-east-1:123456789012:table/MyTable', 'arn:aws:ec2:*:*:instance/*', 'arn:aws-us-gov:s3:::*'."
  }
}

variable "advanced_backup_settings" {
  description = "Advanced backup settings by resource type"
  type        = map(map(string))
  default     = {}
}

variable "backup_regions" {
  description = "List of regions where backups should be created"
  type        = list(string)
  default     = []
}

#
# Default lifecycle configuration constants
#
variable "default_lifecycle_delete_after_days" {
  description = "Default number of days after creation that a recovery point is deleted. Used when delete_after is not specified in lifecycle configuration."
  type        = number
  default     = 90

  validation {
    condition     = var.default_lifecycle_delete_after_days >= 1
    error_message = "The default_lifecycle_delete_after_days must be at least 1 day."
  }
}

variable "default_lifecycle_cold_storage_after_days" {
  description = "Default number of days after creation that a recovery point is moved to cold storage. Used when cold_storage_after is not specified in lifecycle configuration."
  type        = number
  default     = 0

  validation {
    condition     = var.default_lifecycle_cold_storage_after_days == 0 || var.default_lifecycle_cold_storage_after_days >= 30
    error_message = "The default_lifecycle_cold_storage_after_days must be 0 (disabled) or at least 30 days (AWS minimum requirement). To disable cold storage by default, set to 0."
  }
}

#
# AWS Backup Restore Testing Plans
#
variable "restore_testing_plans" {
  description = "Map of restore testing plans to create. Each plan defines automated testing schedule and recovery point selection criteria."
  type = map(object({
    name                         = string
    schedule_expression          = string
    schedule_expression_timezone = optional(string)
    start_window_hours           = optional(number)
    recovery_point_selection = object({
      algorithm             = string
      include_vaults        = list(string)
      recovery_point_types  = list(string)
      exclude_vaults        = optional(list(string))
      selection_window_days = optional(number)
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for plan_key, plan in var.restore_testing_plans : (
        can(regex("^[0-9A-Za-z-_]{1,50}$", plan.name)) &&
        can(regex("^cron\\(", plan.schedule_expression)) &&
        contains(["RANDOM_WITHIN_WINDOW", "LATEST_WITHIN_WINDOW"], plan.recovery_point_selection.algorithm) &&
        length(plan.recovery_point_selection.include_vaults) > 0 &&
        alltrue([for rpt in plan.recovery_point_selection.recovery_point_types : contains(["CONTINUOUS", "SNAPSHOT"], rpt)])
      )
    ])
    error_message = "Invalid restore testing plan configuration. Plan names must be 1-50 characters (alphanumeric, hyphens, underscores). Schedule expressions must be valid cron format. Algorithm must be RANDOM_WITHIN_WINDOW or LATEST_WITHIN_WINDOW. Must include at least one vault. Recovery point types must be CONTINUOUS or SNAPSHOT."
  }

  validation {
    condition = alltrue([
      for plan_key, plan in var.restore_testing_plans : (
        plan.start_window_hours == null || (plan.start_window_hours >= 1 && plan.start_window_hours <= 168)
      )
    ])
    error_message = "The start_window_hours must be between 1 and 168 hours when specified."
  }

  validation {
    condition = alltrue([
      for plan_key, plan in var.restore_testing_plans : (
        plan.recovery_point_selection.selection_window_days == null ||
        (plan.recovery_point_selection.selection_window_days >= 1 && plan.recovery_point_selection.selection_window_days <= 365)
      )
    ])
    error_message = "The selection_window_days must be between 1 and 365 days when specified."
  }
}

#
# AWS Backup Restore Testing Selections
#
variable "restore_testing_selections" {
  description = "Map of restore testing selections to create. Each selection defines which resources to test within a restore testing plan."
  type = map(object({
    name                      = string
    restore_testing_plan_name = string
    protected_resource_type   = string
    iam_role_arn              = optional(string)
    protected_resource_arns   = optional(list(string))
    protected_resource_conditions = optional(object({
      string_equals = optional(list(object({
        key   = string
        value = string
      })))
      string_not_equals = optional(list(object({
        key   = string
        value = string
      })))
    }))
    restore_metadata_overrides = optional(map(string))
    validation_window_hours    = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for selection_key, selection in var.restore_testing_selections : (
        can(regex("^[0-9A-Za-z-_]{1,50}$", selection.name)) &&
        length(selection.protected_resource_type) > 0
      )
    ])
    error_message = "Selection names must be 1-50 characters (alphanumeric, hyphens, underscores). Protected resource type cannot be empty."
  }

  validation {
    condition = alltrue([
      for selection_key, selection in var.restore_testing_selections : (
        selection.validation_window_hours == null ||
        (selection.validation_window_hours >= 1 && selection.validation_window_hours <= 168)
      )
    ])
    error_message = "The validation_window_hours must be between 1 and 168 hours when specified."
  }

  validation {
    condition = alltrue([
      for selection_key, selection in var.restore_testing_selections : (
        selection.iam_role_arn == null ||
        can(regex("^arn:aws:iam::[0-9]{12}:role/", selection.iam_role_arn))
      )
    ])
    error_message = "The iam_role_arn must be a valid IAM role ARN format when specified."
  }

  validation {
    condition = alltrue([
      for selection_key, selection in var.restore_testing_selections : (
        selection.protected_resource_conditions == null ||
        (selection.protected_resource_conditions.string_equals != null && length(selection.protected_resource_conditions.string_equals) > 0) ||
        (selection.protected_resource_conditions.string_not_equals != null && length(selection.protected_resource_conditions.string_not_equals) > 0)
      )
    ])
    error_message = "When protected_resource_conditions are specified, at least one condition (string_equals or string_not_equals) must be provided."
  }
}

#
# AWS Backup Restore Testing IAM Configuration
#
variable "restore_testing_iam_role_arn" {
  description = "The ARN of an existing IAM role for restore testing operations. If not provided, a new role will be created."
  type        = string
  default     = null

  validation {
    condition = var.restore_testing_iam_role_arn == null ? true : (
      can(regex("^arn:aws:iam::[0-9]{12}:role/", var.restore_testing_iam_role_arn)) &&
      !can(regex("(?i)(test|temp|delete|remove)", var.restore_testing_iam_role_arn))
    )
    error_message = "The restore_testing_iam_role_arn must be a valid IAM role ARN. Avoid using 'test', 'temp', 'delete', or 'remove' in role names for security reasons."
  }
}

#
# AWS Backup Global Settings
#
variable "enable_global_settings" {
  description = "Whether to manage AWS Backup global settings. Enable this to configure account-level backup settings."
  type        = bool
  default     = false
}

variable "global_settings" {
  description = "Global settings for AWS Backup. Currently supports isCrossAccountBackupEnabled for centralized cross-account backup governance."
  type        = map(string)
  default = {
    "isCrossAccountBackupEnabled" = "false"
  }

  validation {
    condition     = can(var.global_settings["isCrossAccountBackupEnabled"]) ? contains(["true", "false"], var.global_settings["isCrossAccountBackupEnabled"]) : true
    error_message = "isCrossAccountBackupEnabled must be either 'true' or 'false' as a string (not boolean). This setting controls cross-account backup capabilities for enterprise governance."
  }

  validation {
    condition = alltrue([
      for key, value in var.global_settings : can(regex("^[a-zA-Z][a-zA-Z0-9]*$", key))
    ])
    error_message = "Global setting keys must start with a letter and contain only alphanumeric characters. Currently supported: 'isCrossAccountBackupEnabled'."
  }

  validation {
    condition = alltrue([
      for key, value in var.global_settings : length(value) > 0
    ])
    error_message = "Global setting values cannot be empty strings. Use 'true' or 'false' for boolean settings."
  }
}

#
# AWS Backup Region Settings
#
variable "enable_region_settings" {
  description = "Whether to manage AWS Backup region settings. Enable this to configure resource type opt-in preferences and management at the region level."
  type        = bool
  default     = false
}

variable "region_settings" {
  description = "Configuration for AWS Backup region settings. Manages opt-in preferences and resource type management at the region level."
  type = object({
    resource_type_opt_in_preference     = map(bool)
    resource_type_management_preference = optional(map(bool))
  })
  default = null

  validation {
    condition = var.region_settings == null ? true : (
      var.region_settings.resource_type_opt_in_preference != null &&
      length(var.region_settings.resource_type_opt_in_preference) > 0
    )
    error_message = "When region_settings is specified, resource_type_opt_in_preference must be provided and cannot be empty. This defines which AWS services are enabled for backup in this region."
  }

  validation {
    condition = var.region_settings == null ? true : alltrue([
      for resource_type, enabled in var.region_settings.resource_type_opt_in_preference :
      contains([
        "Aurora", "CloudFormation", "DocumentDB", "DSQL", "DynamoDB", "EBS", "EC2",
        "EFS", "FSx", "Neptune", "Redshift", "Redshift Serverless", "RDS", "S3",
        "SAP HANA on Amazon EC2", "Storage Gateway", "VirtualMachine"
      ], resource_type)
    ])
    error_message = "Invalid resource type in resource_type_opt_in_preference. Valid types are: Aurora, CloudFormation, DocumentDB, DSQL, DynamoDB, EBS, EC2, EFS, FSx, Neptune, Redshift, Redshift Serverless, RDS, S3, SAP HANA on Amazon EC2, Storage Gateway, VirtualMachine."
  }

  validation {
    condition = var.region_settings == null ? true : (
      var.region_settings.resource_type_management_preference == null ? true : alltrue([
        for resource_type, enabled in var.region_settings.resource_type_management_preference :
        contains([
          "Aurora", "CloudFormation", "DocumentDB", "DSQL", "DynamoDB", "EBS", "EC2",
          "EFS", "FSx", "Neptune", "Redshift", "Redshift Serverless", "RDS", "S3",
          "SAP HANA on Amazon EC2", "Storage Gateway", "VirtualMachine"
        ], resource_type)
      ])
    )
    error_message = "Invalid resource type in resource_type_management_preference. Valid types are: Aurora, CloudFormation, DocumentDB, DSQL, DynamoDB, EBS, EC2, EFS, FSx, Neptune, Redshift, Redshift Serverless, RDS, S3, SAP HANA on Amazon EC2, Storage Gateway, VirtualMachine."
  }
}

#
# Region Validation Settings
#
variable "enable_strict_region_validation" {
  description = "Enable strict validation that region settings apply to the expected region. Requires expected_region to be set. When enabled, Terraform will fail if the provider region doesn't match expected_region, preventing accidental misconfiguration in multi-region setups."
  type        = bool
  default     = false
}

variable "expected_region" {
  description = "Expected AWS region for region settings deployment. Used with enable_strict_region_validation to prevent applying settings to the wrong region in multi-provider configurations. If null, no region validation is performed."
  type        = string
  default     = null

  validation {
    condition     = var.expected_region == null || can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.expected_region))
    error_message = "The expected_region must be a valid AWS region format (e.g., 'us-east-1', 'eu-west-1') or null."
  }
}
