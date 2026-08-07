
output "mssql_servers" {
  value = module.mssql_servers

}

module "mssql_servers" {
  source     = "./modules/databases/mssql_server"
  depends_on = [module.keyvault_access_policies, module.keyvault_access_policies_azuread_apps]
  for_each   = local.database.mssql_servers

  global_settings   = local.global_settings
  client_config     = local.client_config
  settings          = each.value
  storage_accounts  = module.storage_accounts
  azuread_groups    = local.combined_objects_azuread_groups
  vnets             = local.combined_objects_networking
  private_endpoints = try(each.value.private_endpoints, {})
  private_dns       = local.combined_objects_private_dns
  resource_groups   = local.combined_objects_resource_groups

  base_tags           = local.global_settings.inherit_tags
  resource_group      = local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group_key, each.value.resource_group.key)]
  resource_group_name = can(each.value.resource_group.name) || can(each.value.resource_group_name) ? try(each.value.resource_group.name, each.value.resource_group_name) : null
  location            = try(local.global_settings.regions[each.value.region], null)

  keyvault_id = can(each.value.administrator_login_password) ? each.value.administrator_login_password : local.combined_objects_keyvaults[try(each.value.keyvault.lz_key, local.client_config.landingzone_key)][try(each.value.keyvault.key, each.value.keyvault_key)].id

  remote_objects = {
    keyvault_keys = local.combined_objects_keyvault_keys
  }
}

data "azurerm_storage_account" "mssql_auditing" {
  for_each = {
    for key, value in local.database.mssql_servers : key => value
    if try(value.extended_auditing_policy, null) != null
  }

  name                = module.storage_accounts[each.value.extended_auditing_policy.storage_account.key].name
  resource_group_name = module.storage_accounts[each.value.extended_auditing_policy.storage_account.key].resource_group_name
}


resource "azurerm_mssql_server_extended_auditing_policy" "mssql" {
  depends_on = [azurerm_role_assignment.for]
  for_each = {
    for key, value in local.database.mssql_servers : key => value
    if try(value.extended_auditing_policy, null) != null
  }

  log_monitoring_enabled                  = try(each.value.extended_auditing_policy.log_monitoring_enabled, false)
  server_id                               = module.mssql_servers[each.key].id
  storage_endpoint                        = data.azurerm_storage_account.mssql_auditing[each.key].primary_blob_endpoint
  storage_account_access_key              = data.azurerm_storage_account.mssql_auditing[each.key].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = try(each.value.extended_auditing_policy.retention_in_days, null)
}

module "mssql_failover_groups" {
  source   = "./modules/databases/mssql_server/failover_group"
  for_each = local.database.mssql_failover_groups

  global_settings     = local.global_settings
  client_config       = local.client_config
  settings            = each.value
  resource_group_name = can(each.value.resource_group.name) || can(each.value.resource_group_name) ? try(each.value.resource_group.name, each.value.resource_group_name) : local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group_key, each.value.resource_group.key)].name
  primary_server_name = local.combined_objects_mssql_servers[try(each.value.primary_server.lz_key, local.client_config.landingzone_key)][each.value.primary_server.sql_server_key].name
  secondary_server_id = local.combined_objects_mssql_servers[try(each.value.secondary_server.lz_key, local.client_config.landingzone_key)][each.value.secondary_server.sql_server_key].id
  databases           = local.combined_objects_mssql_databases
}