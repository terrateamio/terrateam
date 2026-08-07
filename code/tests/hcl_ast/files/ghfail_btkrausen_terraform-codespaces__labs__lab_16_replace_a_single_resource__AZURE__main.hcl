# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources"
  location = var.azure_location

  tags = {
    Environment = var.environment
    Lab         = var.lab_name
  }
}

# Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}storage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Name        = var.storage_account_tag_name
    Environment = var.environment
    Lab         = var.lab_name
  }
}

# Storage Container
resource "azurerm_storage_container" "example" {
  name                  = "${var.prefix}-container"
  storage_account_id    = azurerm_storage_account.example.id
  container_access_type = "private"
}

# User-Assigned Identity
resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  name                = "${var.prefix}-identity"

  tags = {
    Lab         = var.lab_name
    Environment = var.environment
  }
}

# Role Assignment
resource "azurerm_role_assignment" "example" {
  scope                = azurerm_storage_account.example.id
  role_definition_name = var.role_definition_name
  principal_id         = azurerm_user_assigned_identity.example.principal_id
}

# Policy Definition
resource "azurerm_policy_definition" "example" {
  name         = "${var.prefix}-policy-definition"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "${var.prefix}-storage-policy"
  description  = "${var.policy_description} for ${var.lab_name}"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Storage/storageAccounts"
    }
    then = {
      effect = "audit"
    }
  })

  metadata = jsonencode({
    category = "Storage"
    Lab      = var.lab_name
  })
}

# Random string for storage account name uniqueness
resource "random_string" "suffix" {
  length  = var.random_suffix_length
  special = var.special_chars_allowed
  upper   = var.upper_chars_allowed
}