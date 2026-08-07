output "mssql_databases" {
  value = module.mssql_databases

}

module "mssql_databases" {
  source   = "./modules/databases/mssql_database"
  for_each = local.database.mssql_databases

  global_settings     = local.global_settings
  cloud               = local.cloud
  managed_identities  = local.combined_objects_managed_identities
  settings            = each.value
  server_id           = can(each.value.server_id) ? each.value.server_id : local.combined_objects_mssql_servers[try(each.value.lz_key, local.client_config.landingzone_key)][each.value.mssql_server_key].id
  server_name         = can(each.value.server_name) ? each.value.server_name : local.combined_objects_mssql_servers[try(each.value.lz_key, local.client_config.landingzone_key)][each.value.mssql_server_key].name
  elastic_pool_id     = can(each.value.elastic_pool_id) || can(each.value.elastic_pool_key) == false ? try(each.value.elastic_pool_id, null) : local.combined_objects_mssql_elastic_pools[try(each.value.lz_key, local.client_config.landingzone_key)][each.value.elastic_pool_key].id
  storage_accounts    = module.storage_accounts
  diagnostic_profiles = try(each.value.diagnostic_profiles, {})
  diagnostics         = local.combined_diagnostics
  location            = can(local.global_settings.regions[each.value.region]) || can(each.value.region) ? try(local.global_settings.regions[each.value.region], each.value.region) : local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)].location
  base_tags           = try(local.global_settings.inherit_tags, false) ? try(local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)].tags, {}) : {}
}


# Database auditing

data "azurerm_storage_account" "mssqldb_auditing" {
  for_each = {
    for key, value in local.database.mssql_databases : key => value
    if try(value.extended_auditing_policy, null) != null
  }

  name                = module.storage_accounts[each.value.extended_auditing_policy.storage_account.key].name
  resource_group_name = module.storage_accounts[each.value.extended_auditing_policy.storage_account.key].resource_group_name
}

resource "azurerm_mssql_server_extended_auditing_policy" "mssqldb" {
  depends_on = [azurerm_role_assignment.for]
  for_each = {
    for key, value in local.database.mssql_databases : key => value
    if try(value.extended_auditing_policy, null) != null
  }


  log_monitoring_enabled                  = try(each.value.extended_auditing_policy.log_monitoring_enabled, false)
  server_id                               = module.mssql_servers[each.key].id
  storage_endpoint                        = data.azurerm_storage_account.mssql_auditing[each.key].primary_blob_endpoint
  storage_account_access_key              = data.azurerm_storage_account.mssql_auditing[each.key].primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = try(each.value.extended_auditing_policy.retention_in_days, null)
}
