module "databricks_core" {
  source = "./modules/databrickscore"

  providers = {
    databricks         = databricks.engineering
    databricks.account = databricks
    null               = null
  }

  # General variables
  location    = var.location
  environment = var.environment
  prefix      = var.prefix
  tags        = var.tags

  # Service variables
  storage_account_ids                              = module.core.storage_account_ids
  storage_dependencies                             = module.core.storage_dependencies
  databricks_account_id                            = var.databricks_account_id
  databricks_workspace_details                     = local.databricks_workspace_details
  databricks_private_endpoint_rules                = local.databricks_private_endpoint_rules
  databricks_ip_access_list_allow                  = []
  databricks_ip_access_list_deny                   = []
  databricks_network_connectivity_config_name      = var.databricks_network_connectivity_config_name
  databricks_compliance_security_profile_standards = var.databricks_compliance_security_profile_standards

  # Identity variables
  service_principal_name_terraform_plan = var.service_principal_name_terraform_plan

  depends_on = [
    module.core.databricks_dependencies,
  ]
}

module "databricks_data_application" {
  for_each = local.data_application_definitions

  source = "./modules/databricksdataapplication"

  providers = {
    databricks         = databricks.engineering
    databricks.account = databricks
  }

  # General variables
  location    = var.location
  environment = var.environment
  prefix      = var.prefix
  tags        = merge(var.tags, try(each.value.tags, {}))

  # Service variables
  app_name                                  = each.key
  databricks_account_id                     = var.databricks_account_id
  databricks_workspace_workspace_id         = module.core.databricks_workspace_details.engineering.workspace_id
  databricks_access_connector_id            = module.data_application[each.key].databricks_access_connector_id
  databricks_cluster_policy_library_path    = var.databricks_cluster_policy_library_path
  databricks_cluster_policy_file_variables  = merge(var.databricks_cluster_policy_file_variables, try(each.value.databricks.cluster_policy_file_variables, {}))
  databricks_cluster_policy_file_overwrites = try(each.value.databricks.cluster_policy_file_overwrites, {})
  databricks_keyvault_secret_scope_details  = try(module.data_application[each.key].key_vault_details, {})
  databricks_user_assigned_identity_details = module.data_application[each.key].user_assigned_identity_details
  databricks_sql_endpoint_details           = try(each.value.databricks.sql_endpoints, {})
  databricks_workspace_binding_catalog      = var.databricks_workspace_binding_catalog
  databricks_data_factory_details = {
    data_factory_enabled      = try(each.value.data_factory.enabled, false)
    data_factory_id           = try(module.data_application[each.key].data_factory_details.data_factory_id, {})
    data_factory_name         = try(module.data_application[each.key].data_factory_details.data_factory_name, {})
    data_factory_principal_id = try(module.data_application[each.key].data_factory_details.data_factory_principal_id, {})
    data_factory_client_id    = try(module.data_application[each.key].data_factory_details.data_factory_client_id, {})
  }
  storage_container_ids = try(module.data_application[each.key].storage_container_ids, {})
  storage_queue_ids     = try(module.data_application[each.key].storage_queue_ids, {})
  data_provider_details = try(each.value.data_providers, {})

  # Identity variables
  admin_group_name                                    = try(each.value.identity.admin_group_name, "")
  developer_group_name                                = try(each.value.identity.developer_group_name, "")
  reader_group_name                                   = try(each.value.identity.reader_group_name, "")
  service_principal_name                              = try(each.value.identity.service_principal_name, "")
  service_principal_name_terraform_plan               = var.service_principal_name_terraform_plan
  databricks_service_principal_terraform_plan_details = module.databricks_core.databricks_service_principal_terraform_plan_details

  # Budget variables
  budget = try(each.value.budget, 100)

  depends_on = [
    module.core.databricks_dependencies,
  ]
}
