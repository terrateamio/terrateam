resource "azurerm_management_group_policy_assignment" "enterprise_scale" {
  for_each = local.azurerm_management_group_policy_assignment_enterprise_scale

  # Mandatory resource attributes
  # The policy assignment name length must not exceed '24' characters, but Terraform plan is unable to validate this in the plan stage. The following logic forces an error during plan if an invalid name length is specified.
  name                 = tonumber(length(each.value.template.name) > 24 ? "The policy assignment name '${each.value.template.name}' is invalid. The policy assignment name length must not exceed '24' characters." : length(each.value.template.name)) > 24 ? null : each.value.template.name
  management_group_id  = each.value.scope_id
  policy_definition_id = each.value.template.properties.policyDefinitionId

  # Optional resource attributes
  location     = try(each.value.template.location, null)
  description  = try(each.value.template.properties.description, "${each.value.template.name} Policy Assignment at scope ${each.value.scope_id}")
  display_name = try(each.value.template.properties.displayName, each.value.template.name)
  metadata     = try(length(each.value.template.properties.metadata) > 0, false) ? jsonencode(each.value.template.properties.metadata) : null
  parameters   = try(length(each.value.parameters) > 0, false) ? jsonencode(each.value.parameters) : null
  not_scopes   = try(each.value.template.properties.notScopes, local.empty_list)
  enforce      = each.value.enforcement_mode

  # Dynamic configuration blocks for overrides
  # More details can be found here: https://learn.microsoft.com/en-gb/azure/governance/policy/concepts/assignment-structure#overrides-preview
  dynamic "overrides" {
    for_each = try({ for i, override in each.value.template.properties.overrides : i => override }, local.empty_map)
    content {
      value = overrides.value.value
      dynamic "selectors" {
        for_each = try({ for i, selector in overrides.value.selectors : i => selector }, local.empty_map)
        content {
          in     = try(selectors.value.in, local.empty_list)
          not_in = try(selectors.value.not_in, local.empty_list)
        }
      }
    }
  }

  # Dynamic configuration blocks
  # The identity block only supports a single value
  # for type = "SystemAssigned" so the following logic
  # ensures the block is only created when this value
  # is specified in the source template
  dynamic "identity" {
    for_each = (
      try(each.value.template.identity, local.empty_map) == local.empty_map
      ? []
      : [for ik, iv in tomap({ "type" = each.value.template.identity.type }) : each.value.template.identity if iv != "None"]
    )
    content {
      type         = identity.value.type
      identity_ids = can(identity.value.userAssignedIdentities) ? toset(keys(identity.value.userAssignedIdentities)) : null
    }
  }

  # Optional Resource selectors block
  # Only one of "in" or "not_in" should be used
  # Each kind can be used only once

  dynamic "resource_selectors" {
    for_each = try({ for i, resourceSelector in each.value.template.properties.resourceSelectors : i => resourceSelector }, local.empty_map)
    content {
      name = resource_selectors.value.name
      dynamic "selectors" {
        for_each = try({ for i, selector in resource_selectors.value.selectors : i => selector }, local.empty_map)
        content {
          in     = try(selectors.value.in, local.empty_list)
          kind   = selectors.value.kind
          not_in = try(selectors.value.not_in, local.empty_list)
        }
      }
    }
  }

  # Optional Non-compliance messages
  # The message will have the placeholder replaced with 'must' or 'should' by default dependent on the enforcement mode
  # The language can the altered or localised using the variables
  dynamic "non_compliance_message" {
    for_each = local.policy_non_compliance_message_enabled ? (contains(                                  # if noncompliance msgs enabled...
      local.non_compliance_message_supported_policy_modes,                                               # if non_compliance_message_supported_policy_modes contains
      lookup(local.all_policy_modes,                                                                     # ...the policy definition mode
        each.value.template.properties.policyDefinitionId,                                               #
      local.policy_set_mode)                                                                             # default use policy set mode
      ) ? lookup(                                                                                        # then... if the mode is supported then
      each.value.template.properties, "nonComplianceMessages", local.default_non_compliance_message_list # lookup any custom non-compliance message if not use default
    ) : local.empty_list) : local.empty_list                                                             # if mode not supported then empty list, or is not enabled then empty list
    content {
      content                        = replace(lookup(non_compliance_message.value, "message", local.policy_non_compliance_message_default), local.non_compliance_message_enforcement_mode_placeholder, each.value.enforcement_mode ? local.non_compliance_message_enforcement_mode_replacements.default : local.non_compliance_message_enforcement_mode_replacements.donotenforce)
      policy_definition_reference_id = lookup(non_compliance_message.value, "policyDefinitionReferenceId", null)
    }
  }

  # Set explicit dependency on Management Group, Policy Definition and Policy Set Definition deployments.
  # Additionally ensure the Policy Assignment is created after and destroyed before the User Assigned Identity
  # this is to ensure that the deny delete policy is deleted before the identity is removed.
  depends_on = [
    azurerm_user_assigned_identity.management,
    time_sleep.after_azurerm_management_group,
    time_sleep.after_azurerm_policy_definition,
    time_sleep.after_azurerm_policy_set_definition,
  ]
}

resource "time_sleep" "after_azurerm_policy_assignment" {
  depends_on = [
    time_sleep.after_azurerm_management_group,
    time_sleep.after_azurerm_policy_definition,
    time_sleep.after_azurerm_policy_set_definition,
    azurerm_management_group_policy_assignment.enterprise_scale,
  ]

  triggers = {
    "azurerm_management_group_policy_assignment_enterprise_scale" = jsonencode(keys(azurerm_management_group_policy_assignment.enterprise_scale))
  }

  create_duration  = local.create_duration_delay["after_azurerm_policy_assignment"]
  destroy_duration = local.destroy_duration_delay["after_azurerm_policy_assignment"]
}
