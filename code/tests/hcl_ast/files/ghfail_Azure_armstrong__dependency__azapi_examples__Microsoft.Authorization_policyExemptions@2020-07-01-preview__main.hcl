terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {
  }
}

provider "azapi" {
  skip_provider_registration = false
}

variable "resource_name" {
  type    = string
  default = "acctest0001"
}

variable "location" {
  type    = string
  default = "eastus"
}

data "azurerm_client_config" "current" {
}

data "azapi_resource" "subscription" {
  type                   = "Microsoft.Resources/subscriptions@2021-01-01"
  resource_id            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  response_export_values = ["*"]
}

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

resource "azapi_resource" "policyAssignment" {
  type      = "Microsoft.Authorization/policyAssignments@2022-06-01"
  parent_id = data.azapi_resource.subscription.id
  name      = var.resource_name
  location  = "westeurope"
  identity {
    type         = "SystemAssigned"
    identity_ids = []
  }
  body = {
    properties = {
      displayName        = ""
      enforcementMode    = "Default"
      policyDefinitionId = azapi_resource.policyDefinition.id
      scope              = data.azapi_resource.subscription.id
    }
  }
  schema_validation_enabled = false
  response_export_values    = ["*"]
}

resource "azapi_resource" "policyExemption" {
  type      = "Microsoft.Authorization/policyExemptions@2020-07-01-preview"
  parent_id = data.azapi_resource.subscription.id
  name      = var.resource_name
  body = {
    properties = {
      exemptionCategory  = "Mitigated"
      policyAssignmentId = azapi_resource.policyAssignment.id
      policyDefinitionReferenceIds = [
      ]
    }
  }
  schema_validation_enabled = false
  response_export_values    = ["*"]
}

