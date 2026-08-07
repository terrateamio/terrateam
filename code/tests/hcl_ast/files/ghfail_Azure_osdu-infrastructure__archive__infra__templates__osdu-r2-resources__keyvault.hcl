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

resource "random_id" "entitlement_key" {
  byte_length = 18
}

module "keyvault" {
  source              = "../../modules/providers/azure/keyvault"
  keyvault_name       = local.kv_name
  resource_group_name = azurerm_resource_group.app_rg.name
}

locals {
  secrets_map = {
    # AAD Application Secrets
    aad-client-id = module.ad_application.id
    # App Insights Secrets
    appinsights-key = module.app_insights.app_insights_instrumentation_key
    # Service Bus Namespace Secrets
    sb-connection = module.service_bus.service_bus_namespace_default_connection_string
    # Elastic Search Cluster Secrets
    elastic-endpoint = var.elasticsearch_endpoint
    elastic-username = var.elasticsearch_username
    elastic-password = var.elasticsearch_password
    # Cosmos Cluster Secrets
    cosmos-endpoint    = module.cosmosdb_account.properties.cosmosdb.endpoint
    cosmos-primary-key = module.cosmosdb_account.properties.cosmosdb.primary_master_key
    cosmos-connection  = module.cosmosdb_account.properties.cosmosdb.connection_strings[0]
    # App Service Auth Related Secrets
    entitlement-key = random_id.entitlement_key.hex
    # Storage Account Secrets
    storage-account-key = module.storage_account.primary_access_key
    # Service Principal Secrets
    app-dev-sp-username  = module.app_management_service_principal.client_id
    app-dev-sp-password  = module.app_management_service_principal.client_secret
    app-dev-sp-tenant-id = data.azurerm_client_config.current.tenant_id
  }

  output_secret_map = {
    for secret in module.keyvault_secrets.keyvault_secret_attributes :
    secret.name => secret.id
  }
  app_setting_kv_format = "@Microsoft.KeyVault(SecretUri=%s)"
}

module "keyvault_secrets" {
  source      = "../../modules/providers/azure/keyvault-secret"
  keyvault_id = module.keyvault.keyvault_id
  secrets     = local.secrets_map
}

/* Acccess for `authn_app_service` */
module "authn_app_service_keyvault_access_policy" {
  source                  = "../../modules/providers/azure/keyvault-policy"
  vault_id                = module.keyvault.keyvault_id
  tenant_id               = module.authn_app_service.app_service_identity_tenant_id
  object_ids              = module.authn_app_service.app_service_identity_object_ids
  key_permissions         = ["get", "list"]
  secret_permissions      = ["get", "list"]
  certificate_permissions = ["get", "list"]
}

/* Acccess for `function_app` */
module "function_app_keyvault_access_policy" {
  source                  = "../../modules/providers/azure/keyvault-policy"
  vault_id                = module.keyvault.keyvault_id
  tenant_id               = module.function_app.identity_tenant_id
  object_ids              = module.function_app.identity_object_ids
  key_permissions         = ["get", "list"]
  secret_permissions      = ["get", "list"]
  certificate_permissions = ["get", "list"]
}

/* Acccess for `app_management_service_principal`

   Assumes that SP is within the same AZ tenant as
   the `authn_app_service` also deployed by this
   template */
module "app_management_service_principal_keyvault_access_policy" {
  source    = "../../modules/providers/azure/keyvault-policy"
  vault_id  = module.keyvault.keyvault_id
  tenant_id = module.authn_app_service.app_service_identity_tenant_id
  object_ids = [
  module.app_management_service_principal.id]
  key_permissions = [
    "update",
    "delete",
    "get",
  "list"]
  secret_permissions = [
    "set",
    "delete",
    "get",
  "list"]
  certificate_permissions = [
    "update",
    "delete",
    "get",
  "list"]
}
