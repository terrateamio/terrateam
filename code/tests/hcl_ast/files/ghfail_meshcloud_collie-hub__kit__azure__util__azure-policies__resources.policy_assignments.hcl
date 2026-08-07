
locals {
  # policy assignments need some lightweight templating to make sure they can reference the right definition ids, scopes etc.
  # this is why we store them as tmpl.jsons and run them trough templatefile
  policy_assignment_files = fileset(var.policy_path, "policy_assignments/*.tmpl.json")
  policy_assignment_objects = { for f in local.policy_assignment_files :
    f => jsondecode(templatefile("${var.policy_path}/${f}", var.template_file_variables))
  }

  policy_assignments = { for f, p in local.policy_assignment_objects :
    f => {
      name         = p.name,
      display_name = try(p.properties.displayName, null)
      description  = try(p.properties.description, null)

      policy_definition_id = try(p.properties.policyDefinitionId, null)

      parameters                            = try(p.properties.parameters, null)
      not_scopes                            = try(p.properties.notScopes, null)
      enforcement_mode                      = try(p.properties.enforce, null)
      identity                              = try(p.identity, null)
      override                              = try(p.properties.override, null)
      policy_non_compliance_message_enabled = try(p.properties.nonComplianceMessages, null)
    }
  }
}

resource "azurerm_management_group_policy_assignment" "enterprise_scale" {
  for_each = local.policy_assignments

  # Mandatory resource attributes
  # The policy assignment name length must not exceed '24' characters
  # note that Terraform plan is unable to validate this in the plan stage
  name                = each.value.name
  management_group_id = var.management_group_id

  policy_definition_id = each.value.policy_definition_id

  # Optional resource attributes
  description  = each.value.description
  display_name = each.value.display_name

  location   = var.location
  not_scopes = each.value.not_scopes
  parameters = length(each.value.parameters) > 0 ? jsonencode(each.value.parameters) : null
  enforce    = each.value.enforcement_mode

  # Dynamic configuration blocks for overrides
  # More details can be found here: https://learn.microsoft.com/en-gb/azure/governance/policy/concepts/assignment-structure#overrides-preview
  dynamic "overrides" {
    for_each = try({ for i, override in each.value.override : i => override }, {})
    content {
      value = overrides.value.value
      dynamic "selectors" {
        for_each = try({ for i, selector in overrides.value.selectors : i => selector }, {})
        content {
          in     = try(selectors.in, [])
          not_in = try(selectors.not_in, [])
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
    for_each = {
      for ik, iv in try(each.value.identity, {}) :
      ik => iv
      if lower(iv) == "systemassigned"
    }
    content {
      type = "SystemAssigned"
    }
  }

  # deploy assignemnts after definitions and sets
  depends_on = [
    azurerm_policy_definition.enterprise_scale,
    azurerm_policy_set_definition.enterprise_scale
  ]
}
