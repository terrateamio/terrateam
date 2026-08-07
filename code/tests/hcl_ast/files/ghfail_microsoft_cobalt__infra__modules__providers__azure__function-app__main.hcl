data "azurerm_client_config" "current" {}

locals {
  fn_names                       = keys(var.fn_app_config)
  fn_configs                     = values(var.fn_app_config)
  access_restriction_name        = "vnet_restriction"
  access_restriction_description = "blocking public traffic to function app"

  // Without specifyin a `linux_fx_version` the webapp created by the `azurerm_function_app` resource	
  app_linux_fx_versions = [
    for config in local.fn_configs :
    // The value of "DOCKER" is a stand-in value that can be used to force the webapp created to be	  app_deployment_config = [
    // container compatible without explicitly specifying the image that the app should run.
    config.image == null ? "DOCKER" : format("DOCKER|%s/%s", var.docker_registry_server_url, config.image)
  ]

  app_deployment_config = [
    for config in local.fn_configs :
    config.image == null ?
    config.zip == null ?
    tomap({}) :
    tomap({ HASH = config.hash, WEBSITE_RUN_FROM_PACKAGE = config.zip }) :
    tomap({ DOCKER_CUSTOM_IMAGE_NAME = "${var.docker_registry_server_url}/${config.image}" })
  ]

  static_app_settings = {
    FUNCTIONS_EXTENSION_VERSION         = var.runtime_version
    FUNCTIONS_WORKER_RUNTIME            = var.worker_runtime
    DOCKER_REGISTRY_SERVER_URL          = format("https://%s", var.docker_registry_server_url)
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    DOCKER_REGISTRY_SERVER_USERNAME     = var.docker_registry_server_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = var.docker_registry_server_password
    APPINSIGHTS_INSTRUMENTATIONKEY      = var.app_insights_instrumentation_key
  }

  merged_app_settings = merge(tomap(local.static_app_settings), tomap(var.fn_app_settings))
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_resource_group" "stmain" {
  name = var.storage_account_resource_group_name
}

data "azurerm_storage_account" "main" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.stmain.name == "" ? data.azurerm_resource_group.main.name : data.azurerm_resource_group.stmain.name
}

resource "azurerm_function_app" "main" {
  count                     = length(local.fn_names)
  name                      = format("%s-%s", var.fn_name_prefix, lower(local.fn_names[count.index]))
  location                  = data.azurerm_resource_group.main.location
  resource_group_name       = data.azurerm_resource_group.main.name
  app_service_plan_id       = var.service_plan_id
  storage_connection_string = data.azurerm_storage_account.main.primary_connection_string
  tags                      = var.resource_tags
  version                   = var.runtime_version

  app_settings = merge(local.merged_app_settings, local.app_deployment_config[count.index])

  site_config {
    linux_fx_version = local.app_linux_fx_versions[count.index]
    always_on        = var.site_config_always_on
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].linux_fx_version
    ]
  }
}

# Regional VNet Integration
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_int" {
  count          = length(local.fn_names)
  app_service_id = azurerm_function_app.main[count.index].id
  subnet_id      = var.vnet_subnet_id
}