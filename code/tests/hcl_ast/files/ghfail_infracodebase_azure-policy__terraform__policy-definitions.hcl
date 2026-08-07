# Azure Policy Definitions with FIN/SEC/AZU Categorization

# Financial Governance Policy - Cost Control (FIN)
resource "azurerm_policy_definition" "fin_cost_control" {
  name                = local.policy_definitions.fin_cost_control
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "FIN - Deny Expensive VM SKUs"
  description         = "Prevents deployment of expensive VM SKUs to control costs"
  management_group_id = azurerm_management_group.tenant_root.id

  metadata = jsonencode({
    category = "Financial Governance"
    version  = "1.0.0"
    source   = "Enterprise Policy Framework"
  })

  parameters = jsonencode({
    allowedVMSizes = {
      type = "Array"
      metadata = {
        description = "Array of allowed VM sizes"
        displayName = "Allowed VM Sizes"
      }
      defaultValue = var.allowed_vm_sizes
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          not = {
            field = "Microsoft.Compute/virtualMachines/vmSize"
            in    = "[parameters('allowedVMSizes')]"
          }
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })

  depends_on = [azurerm_management_group.tenant_root]
}

# Security Governance Policy - HTTPS Storage (SEC)
resource "azurerm_policy_definition" "sec_https_storage" {
  name                = local.policy_definitions.sec_https_storage
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "SEC - Require HTTPS for Storage Accounts"
  description         = "Ensures storage accounts only allow HTTPS traffic"
  management_group_id = azurerm_management_group.tenant_root.id

  metadata = jsonencode({
    category = "Security Governance"
    version  = "1.0.0"
    source   = "Enterprise Policy Framework"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field     = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"
          notEquals = true
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })

  depends_on = [azurerm_management_group.tenant_root]
}

# Security Governance Policy - Network Access (SEC)
resource "azurerm_policy_definition" "sec_network_access" {
  name                = local.policy_definitions.sec_network_access
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "SEC - Deny Public Network Access"
  description         = "Prevents resources from having public network access"
  management_group_id = azurerm_management_group.tenant_root.id

  metadata = jsonencode({
    category = "Security Governance"
    version  = "1.0.0"
    source   = "Enterprise Policy Framework"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          in = [
            "Microsoft.Storage/storageAccounts",
            "Microsoft.KeyVault/vaults",
            "Microsoft.Sql/servers"
          ]
        },
        {
          anyOf = [
            {
              allOf = [
                {
                  field  = "type"
                  equals = "Microsoft.Storage/storageAccounts"
                },
                {
                  field     = "Microsoft.Storage/storageAccounts/publicNetworkAccess"
                  notEquals = "Disabled"
                }
              ]
            },
            {
              allOf = [
                {
                  field  = "type"
                  equals = "Microsoft.KeyVault/vaults"
                },
                {
                  field     = "Microsoft.KeyVault/vaults/publicNetworkAccess"
                  notEquals = "Disabled"
                }
              ]
            }
          ]
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })

  depends_on = [azurerm_management_group.tenant_root]
}

# Azure Foundation Policy - Naming Convention (AZU)
resource "azurerm_policy_definition" "azu_naming_convention" {
  name                = local.policy_definitions.azu_naming_convention
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "AZU - Require Naming Convention"
  description         = "Enforces enterprise naming standards for Azure resources"
  management_group_id = azurerm_management_group.tenant_root.id

  metadata = jsonencode({
    category = "Azure Foundation"
    version  = "1.0.0"
    source   = "Enterprise Policy Framework"
  })

  parameters = jsonencode({
    namePattern = {
      type = "String"
      metadata = {
        description = "Required naming pattern"
        displayName = "Naming Pattern"
      }
      defaultValue = "*-${var.environment}-*"
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          in = [
            "Microsoft.Compute/virtualMachines",
            "Microsoft.Storage/storageAccounts",
            "Microsoft.Network/virtualNetworks"
          ]
        },
        {
          not = {
            field = "name"
            like  = "[parameters('namePattern')]"
          }
        }
      ]
    }
    then = {
      effect = "Audit"
    }
  })

  depends_on = [azurerm_management_group.tenant_root]
}

# Azure Foundation Policy - Region Compliance (AZU)
resource "azurerm_policy_definition" "azu_region_compliance" {
  name                = local.policy_definitions.azu_region_compliance
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "AZU - Allow Specific Regions Only"
  description         = "Restricts resource deployment to approved Azure regions"
  management_group_id = azurerm_management_group.tenant_root.id

  metadata = jsonencode({
    category = "Azure Foundation"
    version  = "1.0.0"
    source   = "Enterprise Policy Framework"
  })

  parameters = jsonencode({
    allowedRegions = {
      type = "Array"
      metadata = {
        description = "Array of allowed Azure regions"
        displayName = "Allowed Regions"
      }
      defaultValue = var.allowed_regions
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "location"
          exists = true
        },
        {
          not = {
            field = "location"
            in    = "[parameters('allowedRegions')]"
          }
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })

  depends_on = [azurerm_management_group.tenant_root]
}

# Azure Foundation Policy - Required Tags (AZU)
resource "azurerm_policy_definition" "azu_required_tags" {
  name                = local.policy_definitions.azu_required_tags
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "AZU - Require Billing Tags"
  description         = "Requires specific tags for cost allocation and billing"
  management_group_id = azurerm_management_group.tenant_root.id

  metadata = jsonencode({
    category = "Azure Foundation"
    version  = "1.0.0"
    source   = "Enterprise Policy Framework"
  })

  parameters = jsonencode({
    requiredTags = {
      type = "Array"
      metadata = {
        description = "Array of required tag names"
        displayName = "Required Tags"
      }
      defaultValue = var.required_tags
    }
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        for tag in var.required_tags : {
          not = {
            field  = "tags['${tag}']"
            exists = true
          }
        }
      ]
    }
    then = {
      effect = "Audit"
    }
  })

  depends_on = [azurerm_management_group.tenant_root]
}