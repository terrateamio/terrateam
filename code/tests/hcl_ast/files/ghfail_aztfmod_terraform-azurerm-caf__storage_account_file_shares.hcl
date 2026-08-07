#
# Storage account blobs can be created as a nested object or isolated to allow RBAC to be set before writing the blob
#

module "storage_account_file_shares" {
  source     = "./modules/storage_account/file_share"
  depends_on = [azurerm_role_assignment.for]
  for_each   = local.storage.storage_account_file_shares

  storage_account_name = local.combined_objects_storage_accounts[try(each.value.storage_account.lz_key, local.client_config.landingzone_key)][each.value.storage_account.key].name
  storage_account_id   = can(each.value.backups.vault_key) ? local.combined_objects_storage_accounts[try(each.value.storage_account.lz_key, local.client_config.landingzone_key)][each.value.storage_account.key].id : null
  settings             = each.value
  recovery_vault       = can(each.value.backups.vault_key) ? local.combined_objects_recovery_vaults[try(each.value.backups.lz_key, local.client_config.landingzone_key)][each.value.backups.vault_key] : null
  resource_group_name  = try(each.value.backups.resource_group_name, null)
}

output "storage_account_file_shares" {
  value = module.storage_account_file_shares

}
