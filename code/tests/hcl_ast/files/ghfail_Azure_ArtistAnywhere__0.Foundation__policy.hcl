#########################################################################
# Policy (https://learn.microsoft.com/azure/governance/policy/overview) #
#########################################################################

variable policy {
  type = object({
    denyPasswordAuthLinux = object({
      enable = bool
    })
  })
}

resource azurerm_subscription_policy_assignment deny_password_auth_linux {
  count                = var.policy.denyPasswordAuthLinux.enable ? 1 : 0
  name                 = azurerm_policy_definition.deny_password_auth_linux.name
  policy_definition_id = azurerm_policy_definition.deny_password_auth_linux.id
  subscription_id      = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  location             = azurerm_resource_group.foundation.location
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.main.id
    ]
  }
}

resource azurerm_policy_definition deny_password_auth_linux {
  name         = "denyPasswordAuthLinux"
  display_name = "Deny Linux VM password authentication"
  policy_type  = "Custom"
  mode         = "Indexed"
  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType"
          equals = "Linux"
        },
        {
          field  = "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration.disablePasswordAuthentication"
          equals = "false"
        }
      ]
    },
    then = {
      effect = "deny"
    }
  })
}
