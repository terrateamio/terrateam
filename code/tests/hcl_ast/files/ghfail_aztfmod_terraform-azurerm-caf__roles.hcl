module "custom_roles" {
  source   = "./modules/roles/custom_roles"
  for_each = var.custom_role_definitions

  global_settings      = local.global_settings
  subscription_primary = data.azurerm_subscription.primary.id
  custom_role          = each.value
  assignable_scopes    = local.assignable_scopes[each.key]
}

#
# Roles assignments
#
# Require the modules output an rbac_id that is set to the principal_id
#

resource "azurerm_role_assignment" "for" {
  for_each = {
    for key, value in try(local.roles_to_process, {}) : key => value
    if contains(keys(local.services_roles), value.scope_resource_key)
  }

  principal_id         = each.value.object_id_resource_type == "object_ids" ? each.value.object_id_key_resource : each.value.object_id_lz_key == null ? local.services_roles[each.value.object_id_resource_type][var.current_landingzone_key][each.value.object_id_key_resource].rbac_id : local.services_roles[each.value.object_id_resource_type][each.value.object_id_lz_key][each.value.object_id_key_resource].rbac_id
  role_definition_id   = each.value.mode == "custom_role_mapping" ? module.custom_roles[each.value.role_definition_name].role_definition_resource_id : null
  role_definition_name = each.value.mode == "built_in_role_mapping" ? each.value.role_definition_name : null
  scope                = each.value.scope_lz_key == null ? local.services_roles[each.value.scope_resource_key][var.current_landingzone_key][each.value.scope_key_resource].id : local.services_roles[each.value.scope_resource_key][each.value.scope_lz_key][each.value.scope_key_resource].id
}

resource "azurerm_role_assignment" "for_deferred" {
  for_each = {
    for key, value in try(local.roles_to_process, {}) : key => value
    if contains(keys(local.services_roles_deferred), value.scope_resource_key)
  }

  principal_id         = each.value.object_id_resource_type == "object_ids" ? each.value.object_id_key_resource : each.value.object_id_lz_key == null ? local.services_roles[each.value.object_id_resource_type][var.current_landingzone_key][each.value.object_id_key_resource].rbac_id : local.services_roles[each.value.object_id_resource_type][each.value.object_id_lz_key][each.value.object_id_key_resource].rbac_id
  role_definition_id   = each.value.mode == "custom_role_mapping" ? module.custom_roles[each.value.role_definition_name].role_definition_resource_id : null
  role_definition_name = each.value.mode == "built_in_role_mapping" ? each.value.role_definition_name : null
  scope                = each.value.scope_lz_key == null ? local.services_roles_deferred[each.value.scope_resource_key][var.current_landingzone_key][each.value.scope_key_resource].id : local.services_roles_deferred[each.value.scope_resource_key][each.value.scope_lz_key][each.value.scope_key_resource].id
}

resource "time_sleep" "azurerm_role_assignment_for" {
  depends_on = [azurerm_role_assignment.for]
  count = length(
    {
      for key, value in try(local.roles_to_process, {}) : key => value
      if contains(keys(local.services_roles), value.scope_resource_key)
    }
  ) > 0 ? 1 : 0

  # 2 mins timer on creation
  create_duration = "3m"
}

resource "time_sleep" "azurerm_role_assignment_for_deferred" {
  depends_on = [azurerm_role_assignment.for_deferred]
  count = length(
    {
      for key, value in try(local.roles_to_process, {}) : key => value
      if contains(keys(local.services_roles_deferred), value.scope_resource_key)
    }
  ) > 0 ? 1 : 0

  # 2 mins timer on creation
  create_duration = "2m"
}

data "azurerm_management_group" "level" {
  for_each = {
    for key, value in try(var.role_mapping.built_in_role_mapping.management_group, {}) : key => value
  }

  name = lower(each.key) == "root" ? data.azurerm_client_config.current.tenant_id : each.key
}

locals {

  aks_ingress_application_gateway_identities = tomap(
    {
      (var.current_landingzone_key) = {
        for key, value in try(module.aks_clusters, {}) :
        key => {
          rbac_id = value.addon_profile[0].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
        } if can(value.addon_profile[0].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id)
      }
    }
  )

  management_groups = tomap(
    {
      (var.current_landingzone_key) = {
        for key, value in try(var.role_mapping.built_in_role_mapping.management_group, {}) :
        key => {
          id = data.azurerm_management_group.level[key].id
        }
      }
    }
  )

  # Nested objects that must be processed after the services_roles
  services_roles_deferred = {
    storage_containers          = local.combined_objects_storage_containers
    storage_account_file_shares = local.combined_objects_storage_account_file_shares
  }


  services_roles = {
    aks_clusters                               = local.combined_objects_aks_clusters
    aks_ingress_application_gateway_identities = local.aks_ingress_application_gateway_identities
    api_management                             = local.combined_objects_api_management
    app_config                                 = local.combined_objects_app_config
    app_service_environments                   = local.combined_objects_app_service_environments
    app_service_environments_v3                = local.combined_objects_app_service_environments_v3
    app_service_plans                          = local.combined_objects_app_service_plans
    app_services                               = local.combined_objects_app_services
    application_gateway_platforms              = local.combined_objects_application_gateway_platforms
    application_gateways                       = local.combined_objects_application_gateways
    automations                                = local.combined_objects_automations
    availability_sets                          = local.combined_objects_availability_sets
    azure_container_registries                 = local.combined_objects_azure_container_registries
    azuread_applications                       = local.combined_objects_azuread_applications
    azuread_apps                               = local.combined_objects_azuread_apps
    azuread_groups                             = local.combined_objects_azuread_groups
    azuread_service_principals                 = local.combined_objects_azuread_service_principals
    azurerm_firewalls                          = local.combined_objects_azurerm_firewalls
    backup_vaults                              = local.combined_objects_backup_vaults
    batch_accounts                             = local.combined_objects_batch_accounts
    cognitive_services_account                 = local.combined_objects_cognitive_services_accounts
    data_factory                               = local.combined_objects_data_factory
    databricks_workspaces                      = local.combined_objects_databricks_workspaces
    diagnostic_storage_accounts                = local.current_objects_diagnostic_storage_accounts
    dns_zones                                  = local.combined_objects_dns_zones
    event_hub_namespaces                       = local.combined_objects_event_hub_namespaces
    function_apps                              = local.combined_objects_function_apps
    iot_hub                                    = local.combined_objects_iot_hub
    iot_hub_dps                                = local.combined_objects_iot_hub_dps
    keyvaults                                  = local.combined_objects_keyvaults
    kusto_clusters                             = local.combined_objects_kusto_clusters
    log_analytics                              = local.current_objects_log_analytics
    logged_in                                  = local.logged_in
    machine_learning_compute_instance          = module.machine_learning_compute_instance
    machine_learning_workspaces                = local.combined_objects_machine_learning
    managed_identities                         = local.combined_objects_managed_identities
    management_group                           = local.management_groups
    monitor_action_groups                      = local.combined_objects_monitor_action_groups
    mssql_databases                            = local.combined_objects_mssql_databases
    mssql_elastic_pools                        = local.combined_objects_mssql_elastic_pools
    mssql_managed_databases                    = local.combined_objects_mssql_managed_databases
    mssql_managed_instances                    = local.combined_objects_mssql_managed_instances
    mssql_servers                              = local.combined_objects_mssql_servers
    maintenance_configuration                  = local.combined_objects_maintenance_configuration
    mysql_servers                              = local.combined_objects_mysql_servers
    network_watchers                           = local.combined_objects_network_watchers
    networking                                 = local.combined_objects_networking
    postgresql_servers                         = local.combined_objects_postgresql_servers
    private_dns                                = local.combined_objects_private_dns
    proximity_placement_groups                 = local.combined_objects_proximity_placement_groups
    public_ip_addresses                        = local.combined_objects_public_ip_addresses
    purview_accounts                           = local.combined_objects_purview_accounts
    recovery_vaults                            = local.combined_objects_recovery_vaults
    resource_groups                            = local.combined_objects_resource_groups
    route_tables                               = local.combined_objects_route_tables
    servicebus_namespaces                      = local.combined_objects_servicebus_namespaces
    servicebus_topics                          = local.combined_objects_servicebus_topics
    storage_accounts                           = local.combined_objects_storage_accounts
    subscriptions                              = local.combined_objects_subscriptions
    synapse_workspaces                         = local.combined_objects_synapse_workspaces
    virtual_subnets                            = local.combined_objects_virtual_subnets
    wvd_application_groups                     = local.combined_objects_wvd_application_groups
    wvd_applications                           = local.combined_objects_wvd_applications
    wvd_host_pools                             = local.combined_objects_wvd_host_pools
    wvd_workspaces                             = local.combined_objects_wvd_workspaces
  }

  current_objects_log_analytics = tomap(
    {
      (var.current_landingzone_key) = merge(local.combined_objects_log_analytics, local.combined_diagnostics.log_analytics)
    }
  )
  current_objects_diagnostic_storage_accounts = tomap(
    {
      (var.current_landingzone_key) = merge(local.combined_objects_diagnostic_storage_accounts, local.combined_diagnostics.storage_accounts)
    }
  )

  logged_in = tomap(
    {
      (var.current_landingzone_key) = {
        user = {
          rbac_id = local.client_config.logged_user_objectId
        }
        app = {
          rbac_id = local.client_config.logged_aad_app_objectId
        }
      }
    }
  )

  # Process assingnable_scopes and return a list with the object ids
  # assignment_type: can be any of the `local.services_roles` keys
  # attrs:
  #   id:     An object id provided as string - takes precedence over lz_key / key
  #   lz_key: Remote landingzone key
  #   key:    The resource key
  # example:
  # local.services_roles["resource_groups"]["LANDING_ZONE_KEY"]["RESOURCE_GROUP_KEY"].id
  assignable_scopes = {
    for k, v in try(var.custom_role_definitions, {}) : k => flatten([
      for assignment_type, attrs in try(v.assignable_scopes, {}) : [
        for attr in attrs : [
          try(attr.id, local.services_roles[assignment_type][try(attr.lz_key, var.current_landingzone_key)][attr.key].id)
        ]
      ]
    ])
  }

  roles_to_process = {
    for mapping in
    flatten(
      [                                                                 # Variable
        for key_mode, all_role_mapping in var.role_mapping : [          #  built_in_role_mapping = {
          for key, role_mappings in all_role_mapping : [                #       aks_clusters = {
            for scope_key_resource, role_mapping in role_mappings : [   #         seacluster = {
              for role_definition_name, resources in role_mapping : [   #           "Azure Kubernetes Service Cluster Admin Role" = {
                for object_id_key, object_resources in resources : [    #             azuread_group_keys = {
                  for object_id_key_resource in object_resources.keys : #               keys = [ "aks_admins" ] ----End of variable
                  {                                                     # "seacluster_Azure_Kubernetes_Service_Cluster_Admin_Role_aks_admins" = {
                    mode                    = key_mode                  #   "mode" = "built_in_role_mapping"
                    scope_resource_key      = key
                    scope_lz_key            = try(role_mapping.lz_key, null)
                    scope_key_resource      = scope_key_resource
                    role_definition_name    = role_definition_name
                    object_id_resource_type = object_id_key
                    object_id_key_resource  = object_id_key_resource #   "object_id_key_resource" = "aks_admins"
                    object_id_lz_key        = try(object_resources.lz_key, null)
                  }
                ]
              ] if role_definition_name != "lz_key"
            ]
          ]
        ]
      ]
    ) : format("%s_%s_%s_%s", mapping.object_id_resource_type, mapping.scope_key_resource, replace(mapping.role_definition_name, " ", "_"), mapping.object_id_key_resource) => mapping
  }
}

# The code transform this input format to
#   custom_role_mapping = {
#     subscription_keys = {
#       logged_in_subscription = {
#         "caf-launchpad-contributor" = {
#           azuread_group_keys = [
#             "keyvault_level0_rw", "keyvault_level1_rw", "keyvault_level2_rw", "keyvault_level3_rw", "keyvault_level4_rw",
#           ]
#           managed_identity_keys = [
#             "level0", "level1", "level2", "level3", "level4"
#           ]
#         }
#       }
#     }
#   }

#  built_in_role_mapping = {
#       aks_clusters = {
#         seacluster = {
#           "Azure Kubernetes Service Cluster Admin Role" = {
#             azuread_group_keys = {
#               keys = [ "aks_admins" ]
#             }
#             managed_identity_keys = {
#               keys = [ "jumpbox" ]
#             }
#           }
#         }
#       }
#       azure_container_registries = {
#         acr1 = {
#           "AcrPull" = {
#             aks_cluster_keys = {
#               keys = [ "seacluster" ]
#             }
#           }
#         }
#       }
#       storage_accounts = {
#         scripts_region1 = {
#           "Storage Blob Data Contributor" = {
#             logged_in = {
#               keys = [ "user" ]
#             }
#             managed_identities = {
#               lz_key = "launchpad"
#               keys = [ "level0", "level1" ]
#             }
#           }
#         }
#       }
#     }
# ......

## Generates a transformed structure for azurerm_role_assignment to process
# built_in_roles = {
# "acr1_AcrPull_seacluster" = {
#   "mode" = "built_in_role_mapping"
#   "object_id_key_resource" = "seacluster"
#   "object_id_resource_type" = "aks_cluster_keys"
#   "role_definition_name" = "AcrPull"
#   "scope_key_resource" = "acr1"
#   "scope_resource_key" = "azure_container_registries"
# }
# "scripts_region1_Storage_Blob_Data_Contributor_level0" = {
#   "lz_key" = "launchpad"
#   "mode" = "built_in_role_mapping"
#   "object_id_key_resource" = "level0"
#   "object_id_resource_type" = "managed_identities"
#   "role_definition_name" = "Storage Blob Data Contributor"
#   "scope_key_resource" = "scripts_region1"
#   "scope_resource_key" = "storage_accounts"
# }
# "scripts_region1_Storage_Blob_Data_Contributor_level1" = {
#   "lz_key" = "launchpad"
#   "mode" = "built_in_role_mapping"
#   "object_id_key_resource" = "level1"
#   "object_id_resource_type" = "managed_identities"
#   "role_definition_name" = "Storage Blob Data Contributor"
#   "scope_key_resource" = "scripts_region1"
#   "scope_resource_key" = "storage_accounts"
# }
# "scripts_region1_Storage_Blob_Data_Contributor_user" = {
#   "mode" = "built_in_role_mapping"
#   "object_id_key_resource" = "user"
#   "object_id_resource_type" = "logged_in"
#   "role_definition_name" = "Storage Blob Data Contributor"
#   "scope_key_resource" = "scripts_region1"
#   "scope_resource_key" = "storage_accounts"
# }
# "seacluster_Azure_Kubernetes_Service_Cluster_Admin_Role_aks_admins" = {
#   "mode" = "built_in_role_mapping"
#   "object_id_key_resource" = "aks_admins"
#   "object_id_resource_type" = "azuread_group_keys"
#   "role_definition_name" = "Azure Kubernetes Service Cluster Admin Role"
#   "scope_key_resource" = "seacluster"
#   "scope_resource_key" = "aks_clusters"
# }
# "seacluster_Azure_Kubernetes_Service_Cluster_Admin_Role_jumpbox" = {
#   "mode" = "built_in_role_mapping"
#   "object_id_key_resource" = "jumpbox"
#   "object_id_resource_type" = "managed_identity_keys"
#   "role_definition_name" = "Azure Kubernetes Service Cluster Admin Role"
#   "scope_key_resource" = "seacluster"
#   "scope_resource_key" = "aks_clusters"
# }
# .......
