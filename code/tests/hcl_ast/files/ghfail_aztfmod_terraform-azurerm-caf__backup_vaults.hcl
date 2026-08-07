module "backup_vaults" {
  source   = "./modules/backup_vault"
  for_each = local.data_protection.backup_vaults

  global_settings     = local.global_settings
  client_config       = local.client_config
  settings            = each.value
  storage_accounts    = local.combined_objects_storage_accounts
  diagnostics         = local.combined_diagnostics
  identity            = try(each.value.identity, {})
  resource_groups     = local.combined_objects_resource_groups
  location            = can(local.global_settings.regions[each.value.region]) ? local.global_settings.regions[each.value.region] : local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)].location
  resource_group_name = can(each.value.resource_group.name) || can(each.value.resource_group_name) ? try(each.value.resource_group.name, each.value.resource_group_name) : local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group_key, each.value.resource_group.key)].name
  base_tags           = try(local.global_settings.inherit_tags, false) ? try(local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)].tags, {}) : {}
}

output "backup_vaults" {
  value = module.backup_vaults
}

module "backup_vault_policies_blob_storage" {
  source = "./modules/backup_vault/backup_vault_policy_blob_storage"
  for_each = {
    for key, value in local.data_protection.backup_vault_policies : key => value
    if value.type == "blob_storage"
  }

  global_settings = local.global_settings
  settings        = each.value
  vault_id        = can(each.value.backup_vault.id) || can(each.value.backup_vault_key) == false ? try(each.value.backup_vault.id, null) : local.combined_objects_backup_vaults[try(each.value.backup_vault.lz_key, local.client_config.landingzone_key)][try(each.value.backup_vault_key, each.value.backup_vault.key)].id
}

module "backup_vault_policies_disk" {
  source = "./modules/backup_vault/backup_vault_policy_disk"
  for_each = {
    for key, value in local.data_protection.backup_vault_policies : key => value
    if value.type == "disk"
  }

  global_settings = local.global_settings
  settings        = each.value
  vault_id        = can(each.value.backup_vault.id) || can(each.value.backup_vault_key) == false ? try(each.value.backup_vault.id, null) : local.combined_objects_backup_vaults[try(each.value.backup_vault.lz_key, local.client_config.landingzone_key)][try(each.value.backup_vault_key, each.value.backup_vault.key)].id
}

locals {
  backup_vault_policies = merge(module.backup_vault_policies_blob_storage, module.backup_vault_policies_disk)
}

output "backup_vault_policies" {
  value = local.backup_vault_policies
}

module "backup_vault_instances_blob_storage" {
  source     = "./modules/backup_vault/backup_vault_instance_blob_storage"
  depends_on = [azurerm_role_assignment.for]
  for_each = {
    for key, value in local.data_protection.backup_vault_instances : key => value
    if value.type == "blob_storage"
  }

  settings           = each.value
  vault_id           = can(each.value.backup_vault.id) ? each.value.backup_vault.id : local.combined_objects_backup_vaults[try(each.value.backup_vault.lz_key, local.client_config.landingzone_key)][try(each.value.backup_vault_key, each.value.backup_vault.key)].id
  location           = can(local.global_settings.regions[each.value.region]) ? local.global_settings.regions[each.value.region] : local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)].location
  storage_account_id = can(each.value.storage_account.id) ? each.value.storage_account.id : local.combined_objects_storage_accounts[try(each.value.storage_account.lz_key, local.client_config.landingzone_key)][try(each.value.storage_account_key, each.value.storage_account.key)].id
  backup_policy_id   = can(each.value.backup_vault_policy.id) ? each.value.backup_vault_policy.id : local.combined_objects_backup_vault_policies[try(each.value.backup_vault_policy.lz_key, local.client_config.landingzone_key)][try(each.value.backup_vault_policy_key, each.value.backup_vault_policy.key)].id
}

module "backup_vault_instances_disk" {
  source     = "./modules/backup_vault/backup_vault_instance_disk"
  depends_on = [azurerm_role_assignment.for]
  for_each = {
    for key, value in local.data_protection.backup_vault_instances : key => value
    if value.type == "disk"
  }

  settings                     = each.value
  vault_id                     = can(each.value.backup_vault.id) ? each.value.backup_vault.id : local.combined_objects_backup_vaults[try(each.value.backup_vault.lz_key, local.client_config.landingzone_key)][try(each.value.backup_vault_key, each.value.backup_vault.key)].id
  location                     = can(local.global_settings.regions[each.value.region]) ? local.global_settings.regions[each.value.region] : local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)].location
  backup_policy_id             = can(each.value.backup_vault_policy.id) ? each.value.backup_vault_policy.id : local.combined_objects_backup_vault_policies[try(each.value.backup_vault_policy.lz_key, local.client_config.landingzone_key)][try(each.value.backup_vault_policy_key, each.value.backup_vault_policy.key)].id
  snapshot_resource_group_name = can(each.value.snapshot_resource_group.name) || can(each.value.snapshot_resource_group_name) ? try(each.value.snapshot_resource_group.name, each.value.snapshot_resource_group_name) : local.combined_objects_resource_groups[try(each.value.snapshot_resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.snapshot_resource_group_key, each.value.snapshot_resource_group.key)].name
  disk_id                      = try(each.value.disk.os_disk, false) == true ? try(local.combined_objects_virtual_machines[try(each.value.disk.lz_key, local.client_config.landingzone_key)][each.value.disk.vm_key].os_disk_id) : try(local.combined_objects_virtual_machines[try(each.value.disk.lz_key, local.client_config.landingzone_key)][each.value.disk.vm_key].data_disks[each.value.disk.disk_key])
}

locals {
  backup_vault_instances = merge(module.backup_vault_instances_blob_storage, module.backup_vault_instances_disk)
}

output "backup_vault_instances" {
  value = local.backup_vault_instances
}
