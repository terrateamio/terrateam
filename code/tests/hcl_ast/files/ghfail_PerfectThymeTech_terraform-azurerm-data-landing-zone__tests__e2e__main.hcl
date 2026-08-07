module "data_landing_zone" {
  source = "../../"
  providers = {
    azurerm = azurerm
    azapi   = azapi
    azuread = azuread
    fabric  = fabric
    # databricks         = databricks.account
    # databricks.account = databricks.account
    null = null
    time = time
  }

  # General variables
  location    = var.location
  environment = var.environment
  prefix      = var.prefix
  tags        = var.tags

  # Service variables
  trusted_subscription_ids                         = var.trusted_subscription_ids
  trusted_fabric_workspace_ids                     = var.trusted_fabric_workspace_ids
  data_application_library_path                    = var.data_application_library_path
  data_application_file_variables                  = var.data_application_file_variables
  databricks_cluster_policy_library_path           = var.databricks_cluster_policy_library_path
  databricks_cluster_policy_file_variables         = var.databricks_cluster_policy_file_variables
  databricks_account_id                            = var.databricks_account_id
  databricks_network_connectivity_config_name      = var.databricks_network_connectivity_config_name
  databricks_network_policy_details                = var.databricks_network_policy_details
  databricks_workspace_consumption_enabled         = var.databricks_workspace_consumption_enabled
  databricks_compliance_security_profile_standards = var.databricks_compliance_security_profile_standards
  databricks_workspace_binding_catalog             = var.databricks_workspace_binding_catalog
  fabric_capacity_details                          = var.fabric_capacity_details

  # HA/DR variables
  zone_redundancy_enabled        = var.zone_redundancy_enabled
  geo_redundancy_storage_enabled = var.geo_redundancy_storage_enabled

  # Logging variables
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Identity variables
  service_principal_name_terraform_plan = var.service_principal_name_terraform_plan

  # Network variables
  vnet_id            = var.vnet_id
  nsg_id             = var.nsg_id
  route_table_id     = var.route_table_id
  subnet_cidr_ranges = var.subnet_cidr_ranges

  # DNS variables
  private_dns_zone_id_blob              = var.private_dns_zone_id_blob
  private_dns_zone_id_dfs               = var.private_dns_zone_id_dfs
  private_dns_zone_id_queue             = var.private_dns_zone_id_queue
  private_dns_zone_id_vault             = var.private_dns_zone_id_vault
  private_dns_zone_id_databricks        = var.private_dns_zone_id_databricks
  private_dns_zone_id_cognitive_account = var.private_dns_zone_id_cognitive_account
  private_dns_zone_id_open_ai           = var.private_dns_zone_id_open_ai
  private_dns_zone_id_data_factory      = var.private_dns_zone_id_data_factory
  private_dns_zone_id_search_service    = var.private_dns_zone_id_search_service

  # Customer-managed key variables
  customer_managed_key = var.customer_managed_key
}
