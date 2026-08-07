data "azurerm_client_config" "current" {}

# Generate random resource group name
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Generate random value for the storage task name
resource "random_string" "storage_task_name" {
  length  = 8
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "time_offset" "locked_until_date" {
  offset_days = var.offset_days
}

resource "azapi_resource" "my_terraform_task" {
  type      = "Microsoft.StorageActions/storageTasks@2023-01-01"
  name      = random_string.storage_task_name.result
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      action = {
        if = {
          condition = "[[endsWith(Name, '.docx')]]"
          operations = [
            {
              name      = "SetBlobImmutabilityPolicy"
              onFailure = "break"
              onSuccess = "continue"
              parameters = {
                untilDate : time_offset.locked_until_date.rfc3339
                mode : "locked"
              }
            }
          ]
        }
      }
      description = var.storage_task_description
      enabled     = true
    }
  }
}