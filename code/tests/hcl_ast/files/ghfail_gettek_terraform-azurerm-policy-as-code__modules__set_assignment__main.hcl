resource "terraform_data" "set_assign_replace" {
  input = try(var.initiative.replace_trigger, md5(jsonencode(var.initiative.parameters)))
}

resource "azurerm_management_group_policy_assignment" "set" {
  count                = local.assignment_scope.mg
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  management_group_id  = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  policy_definition_id = var.initiative.id
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = var.non_compliance_messages
    content {
      content                        = non_compliance_message.value
      policy_definition_reference_id = non_compliance_message.key == "null" ? null : non_compliance_message.key
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
    }
  }

  dynamic "overrides" {
    for_each = var.overrides
    content {
      value = overrides.value.effect
      selectors {
        in     = try(overrides.value.selectors.in, null)
        not_in = try(overrides.value.selectors.not_in, null)
      }
    }
  }

  dynamic "resource_selectors" {
    for_each = var.resource_selectors
    content {
      name = try(resource_selectors.value.name, null)
      selectors {
        kind   = resource_selectors.value.selectors.kind
        in     = try(resource_selectors.value.selectors.in, null)
        not_in = try(resource_selectors.value.selectors.not_in, null)
      }
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.set_assign_replace]
  }
}

resource "azurerm_subscription_policy_assignment" "set" {
  count                = local.assignment_scope.sub
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  subscription_id      = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  policy_definition_id = var.initiative.id
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = var.non_compliance_messages
    content {
      content                        = non_compliance_message.value
      policy_definition_reference_id = non_compliance_message.key == "null" ? null : non_compliance_message.key
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
    }
  }

  dynamic "overrides" {
    for_each = var.overrides
    content {
      value = overrides.value.effect
      selectors {
        in     = try(overrides.value.selectors.in, null)
        not_in = try(overrides.value.selectors.not_in, null)
      }
    }
  }

  dynamic "resource_selectors" {
    for_each = var.resource_selectors
    content {
      name = try(resource_selectors.value.name, null)
      selectors {
        kind   = resource_selectors.value.selectors.kind
        in     = try(resource_selectors.value.selectors.in, null)
        not_in = try(resource_selectors.value.selectors.not_in, null)
      }
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.set_assign_replace]
  }
}

resource "azurerm_resource_group_policy_assignment" "set" {
  count                = local.assignment_scope.rg
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  resource_group_id    = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  policy_definition_id = var.initiative.id
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = var.non_compliance_messages
    content {
      content                        = non_compliance_message.value
      policy_definition_reference_id = non_compliance_message.key == "null" ? null : non_compliance_message.key
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
    }
  }

  dynamic "overrides" {
    for_each = var.overrides
    content {
      value = overrides.value.effect
      selectors {
        in     = try(overrides.value.selectors.in, null)
        not_in = try(overrides.value.selectors.not_in, null)
      }
    }
  }

  dynamic "resource_selectors" {
    for_each = var.resource_selectors
    content {
      name = try(resource_selectors.value.name, null)
      selectors {
        kind   = resource_selectors.value.selectors.kind
        in     = try(resource_selectors.value.selectors.in, null)
        not_in = try(resource_selectors.value.selectors.not_in, null)
      }
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.set_assign_replace]
  }
}

resource "azurerm_resource_policy_assignment" "set" {
  count                = local.assignment_scope.resource
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  resource_id          = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  policy_definition_id = var.initiative.id
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = var.non_compliance_messages
    content {
      content                        = non_compliance_message.value
      policy_definition_reference_id = non_compliance_message.key == "null" ? null : non_compliance_message.key
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
    }
  }

  dynamic "overrides" {
    for_each = var.overrides
    content {
      value = overrides.value.effect
      selectors {
        in     = try(overrides.value.selectors.in, null)
        not_in = try(overrides.value.selectors.not_in, null)
      }
    }
  }

  dynamic "resource_selectors" {
    for_each = var.resource_selectors
    content {
      name = try(resource_selectors.value.name, null)
      selectors {
        kind   = resource_selectors.value.selectors.kind
        in     = try(resource_selectors.value.selectors.in, null)
        not_in = try(resource_selectors.value.selectors.not_in, null)
      }
    }
  }

  lifecycle {
    replace_triggered_by = [terraform_data.set_assign_replace]
  }
}

## role assignments ##
resource "azurerm_role_assignment" "remediation" {
  for_each                         = { for i in local.role_definition_ids : split("-", basename(i))[0] => i }
  scope                            = coalesce(var.role_assignment_scope, var.assignment_scope)
  role_definition_id               = each.value
  principal_id                     = local.assignment.identity[0].principal_id
  skip_service_principal_aad_check = true
}

## aad group memberships ##
resource "azuread_group_member" "remediation" {
  for_each = {
    for i in var.aad_group_remediation_object_ids : split("-", basename(i))[0] => i
    if try(local.identity_type.type, "") == "SystemAssigned"
  }
  group_object_id  = each.value
  member_object_id = local.assignment.identity[0].principal_id
}

## remediation tasks ##
resource "terraform_data" "remediation" {
  for_each = { for dr in flatten(values(local.definition_reference)) : dr.reference_id => dr }
  input    = md5(jsonencode(each.key))
}

resource "azurerm_management_group_policy_remediation" "rem" {
  for_each                       = { for dr in local.definition_reference.mg : dr.reference_id => dr }
  name                           = lower(each.key)
  management_group_id            = local.remediation_scope
  policy_assignment_id           = local.assignment.id
  policy_definition_reference_id = lower(each.key) # https://github.com/hashicorp/terraform-provider-azurerm/issues/18846
  location_filters               = var.location_filters
  failure_percentage             = var.failure_percentage
  parallel_deployments           = var.parallel_deployments
  resource_count                 = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.remediation[each.key]]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}

resource "azurerm_subscription_policy_remediation" "rem" {
  for_each                       = { for dr in local.definition_reference.sub : dr.reference_id => dr }
  name                           = lower(each.key)
  subscription_id                = local.remediation_scope
  policy_assignment_id           = local.assignment.id
  policy_definition_reference_id = lower(each.key)
  resource_discovery_mode        = local.resource_discovery_mode
  location_filters               = var.location_filters
  failure_percentage             = var.failure_percentage
  parallel_deployments           = var.parallel_deployments
  resource_count                 = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.remediation[each.key]]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}

resource "azurerm_resource_group_policy_remediation" "rem" {
  for_each                       = { for dr in local.definition_reference.rg : dr.reference_id => dr }
  name                           = lower(each.key)
  resource_group_id              = local.remediation_scope
  policy_assignment_id           = local.assignment.id
  policy_definition_reference_id = lower(each.key)
  resource_discovery_mode        = local.resource_discovery_mode
  location_filters               = var.location_filters
  failure_percentage             = var.failure_percentage
  parallel_deployments           = var.parallel_deployments
  resource_count                 = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.remediation[each.key]]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}

resource "azurerm_resource_policy_remediation" "rem" {
  for_each                       = { for dr in local.definition_reference.resource : dr.reference_id => dr }
  name                           = lower(each.key)
  resource_id                    = local.remediation_scope
  policy_assignment_id           = local.assignment.id
  policy_definition_reference_id = lower(each.key)
  resource_discovery_mode        = local.resource_discovery_mode
  location_filters               = var.location_filters
  failure_percentage             = var.failure_percentage
  parallel_deployments           = var.parallel_deployments
  resource_count                 = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.remediation[each.key]]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}
