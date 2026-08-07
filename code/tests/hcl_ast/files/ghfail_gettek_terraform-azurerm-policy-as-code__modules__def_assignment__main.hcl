resource "terraform_data" "def_assign_replace_def" {
  input = md5(jsonencode(var.definition))
}

resource "terraform_data" "def_assign_replace_param" {
  input = md5(jsonencode(local.parameters))
}

resource "azurerm_management_group_policy_assignment" "def" {
  count                = local.assignment_scope.mg
  policy_definition_id = var.definition.id
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  management_group_id  = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = local.non_compliance_message
    content {
      content = non_compliance_message.value
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
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
    replace_triggered_by = [terraform_data.def_assign_replace_param]
  }
}

resource "azurerm_subscription_policy_assignment" "def" {
  count                = local.assignment_scope.sub
  policy_definition_id = var.definition.id
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  subscription_id      = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = local.non_compliance_message
    content {
      content = non_compliance_message.value
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
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
    replace_triggered_by = [terraform_data.def_assign_replace_param]
  }
}

resource "azurerm_resource_group_policy_assignment" "def" {
  count                = local.assignment_scope.rg
  policy_definition_id = var.definition.id
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  resource_group_id    = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = local.non_compliance_message
    content {
      content = non_compliance_message.value
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
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
    replace_triggered_by = [terraform_data.def_assign_replace_param]
  }
}

resource "azurerm_resource_policy_assignment" "def" {
  count                = local.assignment_scope.resource
  policy_definition_id = var.definition.id
  name                 = local.assignment_name
  display_name         = local.display_name
  description          = local.description
  metadata             = local.metadata
  parameters           = local.parameters
  resource_id          = var.assignment_scope
  not_scopes           = var.assignment_not_scopes
  enforce              = var.assignment_enforcement_mode
  location             = local.assignment_location

  dynamic "non_compliance_message" {
    for_each = local.non_compliance_message
    content {
      content = non_compliance_message.value
    }
  }

  dynamic "identity" {
    for_each = local.identity_type
    content {
      type         = identity.value
      identity_ids = var.identity_ids
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
    replace_triggered_by = [terraform_data.def_assign_replace_param]
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
resource "azurerm_management_group_policy_remediation" "rem" {
  count                = local.create_remediation + local.remediate.mg > 1 ? 1 : 0
  name                 = lower(var.definition.name)
  management_group_id  = local.remediation_scope
  policy_assignment_id = local.assignment.id
  location_filters     = var.location_filters
  failure_percentage   = var.failure_percentage
  parallel_deployments = var.parallel_deployments
  resource_count       = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.def_assign_replace_def]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}

resource "azurerm_subscription_policy_remediation" "rem" {
  count                   = local.create_remediation + local.remediate.sub > 1 ? 1 : 0
  name                    = lower(var.definition.name)
  subscription_id         = local.remediation_scope
  policy_assignment_id    = local.assignment.id
  resource_discovery_mode = local.resource_discovery_mode
  location_filters        = var.location_filters
  failure_percentage      = var.failure_percentage
  parallel_deployments    = var.parallel_deployments
  resource_count          = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.def_assign_replace_def]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}

resource "azurerm_resource_group_policy_remediation" "rem" {
  count                   = local.create_remediation + local.remediate.rg > 1 ? 1 : 0
  name                    = lower(var.definition.name)
  resource_group_id       = local.remediation_scope
  policy_assignment_id    = local.assignment.id
  resource_discovery_mode = local.resource_discovery_mode
  location_filters        = var.location_filters
  failure_percentage      = var.failure_percentage
  parallel_deployments    = var.parallel_deployments
  resource_count          = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.def_assign_replace_def]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}

resource "azurerm_resource_policy_remediation" "rem" {
  count                   = local.create_remediation + local.remediate.resource > 1 ? 1 : 0
  name                    = lower(var.definition.name)
  resource_id             = local.remediation_scope
  policy_assignment_id    = local.assignment.id
  resource_discovery_mode = local.resource_discovery_mode
  location_filters        = var.location_filters
  failure_percentage      = var.failure_percentage
  parallel_deployments    = var.parallel_deployments
  resource_count          = var.resource_count

  lifecycle {
    replace_triggered_by = [terraform_data.def_assign_replace_def]
    ignore_changes = [
      parallel_deployments,
      resource_count
    ]
  }
}
