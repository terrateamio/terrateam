# Configure the Azure provider
provider "azurerm" {
  version = "~>1.5"
}

resource "azurerm_resource_group" "aiala" {
  name     = "rg-aiala-${var.environment}"
  location = var.location
}

# Blob storage and containers for pictures data
resource "azurerm_storage_account" "aiala" {
  name                     = "aiala${var.app_id}${var.environment}"
  resource_group_name      = azurerm_resource_group.aiala.name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "gallery" {
  name                  = "gallery"
  storage_account_name  = azurerm_storage_account.aiala.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "placepictures" {
  name                  = "placepictures"
  storage_account_name  = azurerm_storage_account.aiala.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "profile" {
  name                  = "profile"
  storage_account_name  = azurerm_storage_account.aiala.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "taskpictures" {
  name                  = "taskpictures"
  storage_account_name  = azurerm_storage_account.aiala.name
  container_access_type = "private"
}

# App service plan for app, api and sts app services hosting
resource "azurerm_app_service_plan" "aiala" {
  name                     = "aiala-app-service-plan${var.environment}"
  resource_group_name      = azurerm_resource_group.aiala.name
  location                 = var.location
  kind                     = "App"

  sku {
    tier = "Shared"
    size = "D1"
  }
}

resource "azurerm_app_service" "aiala-api" {
  name                = "aiala-api-${var.app_id}-${var.environment}"
  resource_group_name = azurerm_resource_group.aiala.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.aiala.id
}

resource "azurerm_app_service" "aiala-sts" {
  name                = "aiala-sts-${var.app_id}-${var.environment}"
  resource_group_name = azurerm_resource_group.aiala.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.aiala.id
}

resource "azurerm_app_service" "aiala-app" {
  name                = "aiala-app-${var.app_id}-${var.environment}"
  resource_group_name = azurerm_resource_group.aiala.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.aiala.id
}

resource "azurerm_application_insights" "aiala" {
  name                = "aiala-api-${var.environment}"
  resource_group_name = azurerm_resource_group.aiala.name
  location            = var.location
  application_type    = "web"
}

# SQL servers for the portal and STS databases
resource "azurerm_sql_server" "aiala" {
  name                         = "aiala-sql-${var.app_id}-${var.environment}"
  resource_group_name          = azurerm_resource_group.aiala.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.db-login
  administrator_login_password = var.db-pwd
}

resource  "azurerm_sql_database" "aiala-portal" {
  name                = "aiala-sql-portal-${var.environment}"
  location            = var.location
  server_name         = azurerm_sql_server.aiala.name
  resource_group_name = azurerm_resource_group.aiala.name
  create_mode         = "Default"
  edition             = "Basic"
}

resource  "azurerm_sql_database" "aiala-sts" {
  name                = "aiala-sql-sts-${var.environment}"
  location            =  var.location
  server_name         =  azurerm_sql_server.aiala.name
  resource_group_name =  azurerm_resource_group.aiala.name
  create_mode         = "Default"
  edition             = "Basic"
}

# Computer vision API
resource "azurerm_cognitive_account" "aiala" {
  name                = "aiala-vision-${var.environment}"
  resource_group_name = azurerm_resource_group.aiala.name
  location            = var.location
  kind                = "ComputerVision"

  sku_name = "F0"
}

# Azure Maps
resource "azurerm_maps_account" "aiala" {
  name                = "aiala-map-${var.environment}"
  resource_group_name = azurerm_resource_group.aiala.name
  sku_name            = "S0"
}