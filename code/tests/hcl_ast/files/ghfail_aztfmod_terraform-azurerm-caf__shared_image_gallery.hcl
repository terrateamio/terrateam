module "shared_image_galleries" {
  source   = "./modules/shared_image_gallery/image_galleries"
  for_each = try(local.shared_services.shared_image_galleries, {})

  resource_group  = local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)]
  base_tags       = local.global_settings.inherit_tags
  diagnostics     = local.diagnostics
  client_config   = local.client_config
  global_settings = local.global_settings
  settings        = each.value

  depends_on = [
    module.keyvaults,
  ]
}

module "image_definitions" {
  source   = "./modules/shared_image_gallery/image_definitions"
  for_each = try(local.shared_services.image_definitions, {})

  resource_group  = local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)]
  base_tags       = local.global_settings.inherit_tags
  diagnostics     = local.diagnostics
  client_config   = local.client_config
  global_settings = local.global_settings
  gallery_name    = module.shared_image_galleries[each.value.gallery_key].name
  settings        = each.value

}

output "image_definitions" {
  value = module.image_definitions
}

module "packer_service_principal" {
  source   = "./modules/shared_image_gallery/packer_service_principal"
  for_each = try(local.shared_services.packer_service_principal, {})

  resource_group  = local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)]
  base_tags       = local.global_settings.inherit_tags
  client_config   = local.client_config
  global_settings = local.global_settings
  subscription    = data.azurerm_subscription.primary.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
  gallery_name    = module.shared_image_galleries[each.value.shared_image_gallery_destination.gallery_key].name
  image_name      = module.image_definitions[each.value.shared_image_gallery_destination.image_key].name
  key_vault_id    = lookup(each.value, "keyvault_key", null) == null ? null : module.keyvaults[each.value.keyvault_key].id
  settings        = each.value

  depends_on = [
    module.shared_image_galleries,
    module.image_definitions,
    azurerm_role_assignment.for,
  ]
}

module "packer_build" {
  source   = "./modules/shared_image_gallery/packer_build"
  for_each = try(local.shared_services.packer_build, {})

  resource_group            = local.combined_objects_resource_groups[try(each.value.resource_group.lz_key, local.client_config.landingzone_key)][try(each.value.resource_group.key, each.value.resource_group_key)]
  base_tags                 = local.global_settings.inherit_tags
  build_resource_group_name = try(local.resource_groups[each.value.build_resource_group_key].name, local.resource_groups[each.value.resource_group_key].name) #build in separate or same rg
  client_config             = local.client_config
  global_settings           = local.global_settings
  subscription              = data.azurerm_subscription.primary.subscription_id
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  gallery_name              = module.shared_image_galleries[each.value.shared_image_gallery_destination.gallery_key].name
  image_name                = module.image_definitions[each.value.shared_image_gallery_destination.image_key].name
  key_vault_id              = each.value.keyvault_key == null ? null : module.keyvaults[each.value.keyvault_key].id
  managed_identities        = local.combined_objects_managed_identities
  vnet_name                 = try(try(local.combined_objects_networking[each.value.lz_key][each.value.vnet_key].name, local.combined_objects_networking[local.client_config.landingzone_key][each.value.vnet_key].name), "")
  subnet_name               = try(lookup(each.value, "lz_key", null) == null ? local.combined_objects_networking[local.client_config.landingzone_key][each.value.vnet_key].subnets[each.value.subnet_key].name : local.combined_objects_networking[each.value.lz_key][each.value.vnet_key].subnets[each.value.subnet_key].name, "")
  settings                  = each.value
  depends_on = [
    module.shared_image_galleries,
    module.image_definitions,
    azurerm_role_assignment.for,
  ]
}