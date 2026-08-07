//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

data "azurerm_client_config" "current" {}

locals {
  access_restriction_description = "blocking public traffic to app service"
  access_restriction_name        = "vnet_restriction"
  app_names                      = keys(var.app_service_config)
  app_configs                    = values(var.app_service_config)

  app_linux_fx_versions = {
    for app_name in local.app_names :
    // Without specifyin a `linux_fx_version` the webapp created by the `azurerm_app_service` resource
    // will be a non-container webapp.
    //
    // The value of "DOCKER" is a stand-in value that can be used to force the webapp created to be
    // container compatible without explicitly specifying the image that the app should run.
    //
    // If config.image is missing then this isn't a container compatible app service
    app_name => var.app_service_config[app_name].image == null
    ? var.app_service_config[app_name].linux_fx_version
    : var.app_service_config[app_name].image == ""
    ? "DOCKER" : format("DOCKER|%s/%s", var.docker_registry_server_url, var.app_service_config[app_name].image)
  }

  static_app_settings = {
    DOCKER_REGISTRY_SERVER_URL                 = var.docker_registry_server_url != "" ? format("https://%s", var.docker_registry_server_url) : ""
    WEBSITES_ENABLE_APP_SERVICE_STORAGE        = false
    DOCKER_REGISTRY_SERVER_USERNAME            = var.docker_registry_server_username
    DOCKER_REGISTRY_SERVER_PASSWORD            = var.docker_registry_server_password
    APPLICATIONINSIGHTS_CONNECTION_STRING      = format("InstrumentationKey=%s", var.app_insights_instrumentation_key)
    ApplicationInsightsAgent_EXTENSION_VERSION = var.app_insights_version
    KEYVAULT_URI                               = var.vault_uri
  }

  app_service_settings = merge(tomap(local.static_app_settings), var.app_service_settings)
}

data "azurerm_resource_group" "appsvc" {
  name = var.service_plan_resource_group_name
}

data "azurerm_app_service_plan" "appsvc" {
  name                = var.service_plan_name
  resource_group_name = data.azurerm_resource_group.appsvc.name
}

resource "azurerm_app_service" "appsvc" {
  name                = format("%s-%s", var.app_service_name_prefix, lower(local.app_names[count.index]))
  resource_group_name = data.azurerm_resource_group.appsvc.name
  location            = data.azurerm_resource_group.appsvc.location
  app_service_plan_id = data.azurerm_app_service_plan.appsvc.id
  tags                = var.resource_tags
  https_only          = true
  count               = length(local.app_names)

  app_settings = merge(
    local.app_service_settings,
    var.app_service_config[local.app_names[count.index]].app_settings
  )

  site_config {
    linux_fx_version     = local.app_linux_fx_versions[local.app_names[count.index]]
    always_on            = var.site_config_always_on
    virtual_network_name = var.vnet_name
    app_command_line     = var.app_service_config[local.app_names[count.index]].app_command_line
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    # This stanza will prevent terraform from reverting changes to the application container settings.
    # These settings are how application teams deploy new containers to the app service and should not
    # be overridden by Terraform deployments.
    ignore_changes = [
      site_config[0].linux_fx_version,
      site_config[0].app_command_line
    ]

    create_before_destroy = true
  }
}

resource "azurerm_app_service_slot" "appsvc_staging_slot" {
  name                = "staging"
  app_service_name    = format("%s-%s", var.app_service_name_prefix, lower(local.app_names[count.index]))
  count               = length(local.app_names)
  location            = data.azurerm_resource_group.appsvc.location
  resource_group_name = data.azurerm_resource_group.appsvc.name
  app_service_plan_id = data.azurerm_app_service_plan.appsvc.id
  depends_on          = [azurerm_app_service.appsvc]

  app_settings = merge(
    local.app_service_settings,
    var.app_service_config[local.app_names[count.index]].app_settings
  )

  site_config {
    linux_fx_version     = local.app_linux_fx_versions[local.app_names[count.index]]
    always_on            = var.site_config_always_on
    virtual_network_name = var.vnet_name
    app_command_line     = var.app_service_config[local.app_names[count.index]].app_command_line
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    # This stanza will prevent terraform from reverting changes to the application container settings.
    # These settings are how application teams deploy new containers to the app service and should not
    # be overridden by Terraform deployments.
    ignore_changes = [
      site_config[0].linux_fx_version,
      site_config[0].app_command_line
    ]
    create_before_destroy = true
  }
}

data "azurerm_app_service" "all" {
  count               = length(azurerm_app_service.appsvc)
  name                = azurerm_app_service.appsvc[count.index].name
  resource_group_name = data.azurerm_resource_group.appsvc.name
  depends_on          = [azurerm_app_service.appsvc]
}

resource "azurerm_template_deployment" "access_restriction" {
  name                = "access_restriction"
  count               = var.uses_vnet ? length(local.app_names) : 0
  resource_group_name = data.azurerm_resource_group.appsvc.name

  parameters = {
    service_name                   = format("%s-%s", var.app_service_name_prefix, lower(local.app_names[count.index]))
    vnet_subnet_id                 = var.vnet_subnet_id
    access_restriction_name        = local.access_restriction_name
    access_restriction_description = local.access_restriction_description
  }

  deployment_mode = "Incremental"
  template_body   = file("${path.module}/azuredeploy.json")
  depends_on      = [data.azurerm_app_service.all]
}
