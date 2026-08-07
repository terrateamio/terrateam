
# Organized locals for better maintainability and code clarity
locals {
  # Vault name validation (moved from variables.tf to support bypass logic)
  vault_name_has_restricted_words = var.vault_name != null ? can(regex("(?i)(test|temp|delete|remove|default)", var.vault_name)) : false
  vault_name_validation_failed    = local.vault_name_has_restricted_words && !var.vault_name_validation_bypass

  # Resource creation conditions
  should_create_vault           = var.enabled && var.vault_name != null && !local.vault_name_validation_failed
  should_create_standard_vault  = local.should_create_vault && var.vault_type == "standard"
  should_create_airgapped_vault = local.should_create_vault && var.vault_type == "logically_air_gapped"
  should_create_lock            = local.should_create_standard_vault && var.locked
  should_create_legacy_plan     = var.enabled && length(var.plans) == 0 && length(local.rules) > 0

  # Validation helpers for vault lock configuration
  vault_lock_requirements_met = var.min_retention_days != null && var.max_retention_days != null
  retention_days_valid        = local.vault_lock_requirements_met ? var.min_retention_days <= var.max_retention_days : true
  check_retention_days        = var.locked ? (local.vault_lock_requirements_met && local.retention_days_valid) : true

  # Validation for air-gapped vault requirements
  airgapped_vault_requirements_met = var.vault_type != "logically_air_gapped" || (var.min_retention_days != null && var.max_retention_days != null)

  # Cross-validation for retention days (unified validation approach)
  # Uses positive logic form (both not null) instead of negative (either null) for clarity.
  # Logically equivalent to: (min == null || max == null) ? true : (min <= max)
  # This form is clearer: "if both exist, compare them; otherwise, it's valid"
  retention_days_cross_valid = (var.min_retention_days != null && var.max_retention_days != null) ? (var.min_retention_days <= var.max_retention_days) : true

  # Vault reference helpers (dynamic based on vault type)
  vault_name = local.should_create_standard_vault ? try(aws_backup_vault.ab_vault[0].name, null) : (
    local.should_create_airgapped_vault ? try(aws_backup_logically_air_gapped_vault.ab_airgapped_vault[0].name, null) : null
  )

  # Vault policy configuration
  should_create_vault_policy = var.enabled && var.vault_policy != null && local.should_create_vault

  # Rule processing (matching existing logic for compatibility)
  rule = var.rule_name == null ? [] : [{
    name                         = var.rule_name
    target_vault_name            = var.vault_name != null ? var.vault_name : "Default"
    schedule                     = var.rule_schedule
    schedule_expression_timezone = var.rule_schedule_expression_timezone
    start_window                 = var.rule_start_window
    completion_window            = var.rule_completion_window
    lifecycle = var.rule_lifecycle_cold_storage_after == null ? {} : {
      cold_storage_after                        = var.rule_lifecycle_cold_storage_after
      delete_after                              = var.rule_lifecycle_delete_after
      opt_in_to_archive_for_supported_resources = var.rule_lifecycle_opt_in_to_archive
    }
    enable_continuous_backup = var.rule_enable_continuous_backup
    recovery_point_tags      = var.rule_recovery_point_tags
  }]

  rules = concat(local.rule, var.rules)

  # Selection processing (comprehensive logic for VSS validation)
  selection_resources = flatten([
    # Legacy single selection
    var.selection_resources,
    # Legacy multiple selections (var.selections)
    [for selection in try(tolist(var.selections), []) : try(selection.resources, [])],
    [for k, selection in try(tomap(var.selections), {}) : try(selection.resources, [])],
    # New multiple selections (var.backup_selections)
    [for selection in var.backup_selections : try(selection.resources, [])],
    # Plan-based selections
    [for plan in var.plans : flatten([for selection in try(plan.selections, []) : try(selection.resources, [])])]
  ])

  # Plans processing
  plans_map = var.plans

  # Lifecycle validations
  lifecycle_validations = alltrue([
    for rule in local.rules : (
      length(try(rule.lifecycle, {})) == 0 ? true : (
        # Only validate the comparison if both values are non-null
        (try(rule.lifecycle.cold_storage_after, null) == null || try(rule.lifecycle.delete_after, null) == null) ? true :
        coalesce(rule.lifecycle.cold_storage_after, 0) <= coalesce(rule.lifecycle.delete_after, var.default_lifecycle_delete_after_days)
      )
    ) &&
    alltrue([
      for copy_action in try(rule.copy_actions, []) : (
        length(try(copy_action.lifecycle, {})) == 0 ? true : (
          # Only validate the comparison if both values are non-null
          (try(copy_action.lifecycle.cold_storage_after, null) == null || try(copy_action.lifecycle.delete_after, null) == null) ? true :
          coalesce(copy_action.lifecycle.cold_storage_after, 0) <= coalesce(copy_action.lifecycle.delete_after, var.default_lifecycle_delete_after_days)
        )
      )
    ])
  ])
}

# Validation check for vault name with restricted words (moved from variables.tf to enable bypass functionality)
resource "null_resource" "vault_name_validation" {
  count = local.vault_name_validation_failed ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      echo "ERROR: Vault name validation failed!"
      echo "The vault name '${var.vault_name}' contains restricted words (test, temp, delete, remove, default)."
      echo "These words are not recommended for security reasons."
      echo ""
      echo "Solutions:"
      echo "1. Change the vault name to avoid these words"
      echo "2. For existing vaults, set: vault_name_validation_bypass = true"
      echo ""
      exit 1
    EOF
  }

  lifecycle {
    create_before_destroy = true
  }
}

# AWS Backup vault (standard) with optimized timeouts
resource "aws_backup_vault" "ab_vault" {
  count = local.should_create_standard_vault ? 1 : 0

  name          = var.vault_name
  kms_key_arn   = var.vault_kms_key_arn
  force_destroy = var.vault_force_destroy
  tags          = var.tags

}

# AWS Backup logically air gapped vault
resource "aws_backup_logically_air_gapped_vault" "ab_airgapped_vault" {
  count = local.should_create_airgapped_vault ? 1 : 0

  name               = var.vault_name
  min_retention_days = var.min_retention_days
  max_retention_days = var.max_retention_days
  tags               = var.tags

}

# AWS Backup vault lock configuration
resource "aws_backup_vault_lock_configuration" "ab_vault_lock_configuration" {
  count = local.should_create_lock ? 1 : 0

  backup_vault_name   = aws_backup_vault.ab_vault[0].name
  min_retention_days  = var.min_retention_days
  max_retention_days  = var.max_retention_days
  changeable_for_days = var.changeable_for_days

  lifecycle {
    precondition {
      condition     = local.check_retention_days
      error_message = "When vault locking is enabled (locked = true), min_retention_days and max_retention_days must be provided and min_retention_days must be less than or equal to max_retention_days."
    }
  }
}

# AWS Backup vault access policy
resource "aws_backup_vault_policy" "ab_vault_policy" {
  count = local.should_create_vault_policy ? 1 : 0

  backup_vault_name = local.vault_name
  policy            = var.vault_policy

  depends_on = [
    aws_backup_vault.ab_vault,
    aws_backup_logically_air_gapped_vault.ab_airgapped_vault
  ]
}

# Legacy AWS Backup plan (for backward compatibility) with optimized timeouts
resource "aws_backup_plan" "ab_plan" {
  count = local.should_create_legacy_plan ? 1 : 0
  name  = coalesce(var.plan_name, "aws-backup-plan-${var.vault_name != null ? var.vault_name : "default"}")

  # Rules
  dynamic "rule" {
    for_each = local.rules
    content {
      rule_name                    = try(rule.value.name, null)
      target_vault_name            = try(rule.value.target_vault_name, null) != null ? rule.value.target_vault_name : var.vault_name != null ? local.vault_name : "Default"
      schedule                     = try(rule.value.schedule, null)
      schedule_expression_timezone = try(rule.value.schedule_expression_timezone, null)
      start_window                 = try(rule.value.start_window, null)
      completion_window            = try(rule.value.completion_window, null)
      enable_continuous_backup     = try(rule.value.enable_continuous_backup, null)
      recovery_point_tags          = coalesce(rule.value.recovery_point_tags, var.tags)

      # Lifecycle
      dynamic "lifecycle" {
        for_each = length(try(rule.value.lifecycle, {})) == 0 ? [] : [rule.value.lifecycle]
        content {
          cold_storage_after                        = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
          delete_after                              = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
          opt_in_to_archive_for_supported_resources = try(lifecycle.value.opt_in_to_archive_for_supported_resources, null)
        }
      }

      # Copy action
      dynamic "copy_action" {
        for_each = try(rule.value.copy_actions, [])
        content {
          destination_vault_arn = try(copy_action.value.destination_vault_arn, null)

          # Copy Action Lifecycle
          dynamic "lifecycle" {
            for_each = length(try(copy_action.value.lifecycle, {})) == 0 ? [] : [copy_action.value.lifecycle]
            content {
              cold_storage_after                        = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
              delete_after                              = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
              opt_in_to_archive_for_supported_resources = try(lifecycle.value.opt_in_to_archive_for_supported_resources, null)
            }
          }
        }
      }
    }
  }

  # Advanced backup setting
  dynamic "advanced_backup_setting" {
    for_each = var.windows_vss_backup ? [1] : []
    content {
      backup_options = {
        WindowsVSS = "enabled"
      }
      resource_type = "EC2"
    }
  }

  # Tags
  tags = var.tags

  # First create the vault if needed
  depends_on = [
    aws_backup_vault.ab_vault,
    aws_backup_logically_air_gapped_vault.ab_airgapped_vault
  ]

  lifecycle {
    precondition {
      condition     = !var.windows_vss_backup || (length(local.selection_resources) > 0 && can(regex("(?i).*ec2.*", join(",", local.selection_resources))))
      error_message = "Windows VSS backup is enabled but no EC2 instances are selected for backup. Either disable windows_vss_backup or include EC2 instances in your backup selection."
    }

    precondition {
      condition     = local.airgapped_vault_requirements_met
      error_message = "When vault_type is 'logically_air_gapped', both min_retention_days and max_retention_days must be specified."
    }

    precondition {
      condition     = local.retention_days_cross_valid
      error_message = "The min_retention_days must be less than or equal to max_retention_days."
    }

    # Add lifecycle validations at the plan level
    precondition {
      condition     = local.lifecycle_validations
      error_message = "In one or more rules, cold_storage_after must be less than or equal to delete_after."
    }
  }
}

# AWS Backup Global Settings
resource "aws_backup_global_settings" "ab_global_settings" {
  count = var.enabled && var.enable_global_settings ? 1 : 0

  global_settings = var.global_settings

  lifecycle {
    precondition {
      condition     = var.enable_global_settings ? length(var.global_settings) > 0 : true
      error_message = "When enable_global_settings is true, global_settings map cannot be empty. At minimum, specify isCrossAccountBackupEnabled."
    }
  }
}

# Multiple AWS Backup plans with optimized timeouts
resource "aws_backup_plan" "ab_plans" {
  for_each = var.enabled ? local.plans_map : {}
  name     = coalesce(each.value.name, each.key)

  # Rules
  dynamic "rule" {
    for_each = each.value.rules
    content {
      rule_name                    = try(rule.value.name, null)
      target_vault_name            = try(rule.value.target_vault_name, null) != null ? rule.value.target_vault_name : var.vault_name != null ? local.vault_name : "Default"
      schedule                     = try(rule.value.schedule, null)
      schedule_expression_timezone = try(rule.value.schedule_expression_timezone, null)
      start_window                 = try(rule.value.start_window, null)
      completion_window            = try(rule.value.completion_window, null)
      enable_continuous_backup     = try(rule.value.enable_continuous_backup, null)
      recovery_point_tags          = coalesce(rule.value.recovery_point_tags, var.tags)

      # Lifecycle
      dynamic "lifecycle" {
        for_each = length(try(rule.value.lifecycle, {})) == 0 ? [] : [rule.value.lifecycle]
        content {
          cold_storage_after                        = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
          delete_after                              = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
          opt_in_to_archive_for_supported_resources = try(lifecycle.value.opt_in_to_archive_for_supported_resources, null)
        }
      }

      # Copy action
      dynamic "copy_action" {
        for_each = try(rule.value.copy_actions, [])
        content {
          destination_vault_arn = try(copy_action.value.destination_vault_arn, null)

          # Copy Action Lifecycle
          dynamic "lifecycle" {
            for_each = length(try(copy_action.value.lifecycle, {})) == 0 ? [] : [copy_action.value.lifecycle]
            content {
              cold_storage_after                        = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
              delete_after                              = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
              opt_in_to_archive_for_supported_resources = try(lifecycle.value.opt_in_to_archive_for_supported_resources, null)
            }
          }
        }
      }
    }
  }

  # Advanced backup setting
  dynamic "advanced_backup_setting" {
    for_each = var.windows_vss_backup ? [1] : []
    content {
      backup_options = {
        WindowsVSS = "enabled"
      }
      resource_type = "EC2"
    }
  }

  # Tags
  tags = var.tags

  # First create the vault if needed
  depends_on = [
    aws_backup_vault.ab_vault,
    aws_backup_logically_air_gapped_vault.ab_airgapped_vault
  ]

  lifecycle {
    precondition {
      condition     = !var.windows_vss_backup || (length(local.selection_resources) > 0 && can(regex("(?i).*ec2.*", join(",", local.selection_resources))))
      error_message = "Windows VSS backup is enabled but no EC2 instances are selected for backup. Either disable windows_vss_backup or include EC2 instances in your backup selection."
    }
  }
}
