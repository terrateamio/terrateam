resource "azapi_resource" "policyDefinition" {
  type      = "Microsoft.Authorization/policyDefinitions@2021-06-01"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  name      = var.resource_name
  body = {
    properties = {
      description = ""
      displayName = "my-policy-definition"
      mode        = "All"
      parameters = {
        allowedLocations = {
          metadata = {
            description = "The list of allowed locations for resources."
            displayName = "Allowed locations"
            strongType  = "location"
          }
          type = "Array"
        }
      }
      policyRule = {
        if = {
          not = {
            field = "location"
            in    = "[parameters('allowedLocations')]"
          }
        }
        then = {
          effect = "audit"
        }
      }
      policyType = "Custom"
    }
  }
  schema_validation_enabled = false
  response_export_values    = ["*"]
}
