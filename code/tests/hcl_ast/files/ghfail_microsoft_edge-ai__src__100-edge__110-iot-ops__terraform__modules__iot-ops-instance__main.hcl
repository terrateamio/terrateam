/**
 * # Azure IoT Instance
 *
 * Deploys an AIO instance.
 *
 */

locals {
  # AIO Instance
  selfsigned_issuer_name    = "${var.operations_config.namespace}-aio-certificate-issuer"
  selfsigned_configmap_name = "${var.operations_config.namespace}-aio-ca-trust-bundle"

  is_customer_managed = var.trust_source == "CustomerManaged"

  trust = local.is_customer_managed ? var.customer_managed_trust_settings : {
    issuer_name    = local.selfsigned_issuer_name
    issuer_kind    = "ClusterIssuer"
    configmap_name = local.selfsigned_configmap_name
    configmap_key  = ""
  }
  custom_location_name = "cl-${var.connected_cluster_name}"
  aio_instance_name    = "iotops-${var.connected_cluster_name}"

  mqtt_broker_hostname = "${var.mqtt_broker_config.brokerListenerServiceName}.${var.operations_config.namespace}"
  mqtt_broker_address  = "mqtts://${local.mqtt_broker_hostname}:${var.mqtt_broker_config.brokerListenerPort}"

  # Helper function for boolean to enabled/disabled string conversion
  enabled_disabled = {
    true  = "Enabled"
    false = "Disabled"
  }

  metrics = {
    enabled              = var.should_enable_otel_collector
    otelCollectorAddress = var.should_enable_otel_collector ? "aio-otel-collector.${var.operations_config.namespace}.svc.cluster.local:4317" : ""
  }

  spc_name_hash_input = "${var.connected_cluster_name}-${var.resource_group.name}-${local.aio_instance_name}"
  spc_name            = "spc-ops-${substr(sha256(local.spc_name_hash_input), 0, 7)}"

  default_configuration_settings = {
    "AgentOperationTimeoutInMinutes"                                                  = tostring(var.operations_config.agentOperationTimeoutInMinutes)
    "connectors.values.mqttBroker.address"                                            = local.mqtt_broker_address
    "connectors.values.mqttBroker.serviceAccountTokenAudience"                        = var.mqtt_broker_config.serviceAccountAudience
    "dataFlows.values.tinyKube.mqttBroker.hostName"                                   = local.mqtt_broker_hostname
    "dataFlows.values.tinyKube.mqttBroker.port"                                       = tostring(var.mqtt_broker_config.brokerListenerPort)
    "dataFlows.values.tinyKube.mqttBroker.authentication.serviceAccountTokenAudience" = var.mqtt_broker_config.serviceAccountAudience
    "observability.metrics.enabled"                                                   = local.metrics.enabled ? "true" : "false"
    "observability.metrics.openTelemetryCollectorAddress"                             = local.metrics.otelCollectorAddress
    "trustSource"                                                                     = var.trust_source
    "trustBundleSettings.issuer.name"                                                 = local.trust.issuer_name
    "trustBundleSettings.issuer.kind"                                                 = local.trust.issuer_kind
    "trustBundleSettings.configMap.name"                                              = local.trust.configmap_name
    "trustBundleSettings.configMap.key"                                               = local.trust.configmap_key
    "schemaRegistry.values.mqttBroker.host"                                           = local.mqtt_broker_address
    "schemaRegistry.values.mqttBroker.serviceAccountTokenAudience"                    = var.mqtt_broker_config.serviceAccountAudience
  }
}


data "azurerm_subscription" "current" {}


resource "azurerm_arc_kubernetes_cluster_extension" "iot_operations" {
  name           = "iot-ops"
  cluster_id     = var.arc_connected_cluster_id
  extension_type = "microsoft.iotoperations"
  identity {
    type = "SystemAssigned"
  }
  version                = var.operations_config.version
  release_train          = var.operations_config.train
  release_namespace      = var.operations_config.namespace
  configuration_settings = merge(local.default_configuration_settings, var.configuration_settings_override)
}

resource "azurerm_role_assignment" "schema_registry" {
  scope                = var.schema_registry_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_arc_kubernetes_cluster_extension.iot_operations.identity[0].principal_id
}

resource "azapi_resource" "custom_location" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-31-preview"
  name      = local.custom_location_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group.id
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      hostResourceId      = var.arc_connected_cluster_id
      namespace           = var.operations_config.namespace
      displayName         = local.custom_location_name
      clusterExtensionIds = concat([var.secret_store_cluster_extension_id, azurerm_arc_kubernetes_cluster_extension.iot_operations.id], var.additional_cluster_extension_ids)
    }
  }
  response_export_values = ["name", "id"]
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.iot_operations]
}

resource "azapi_resource" "aio_sync_rule" {
  type      = "Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview"
  name      = "${azapi_resource.custom_location.name}-broker-sync"
  parent_id = azapi_resource.custom_location.id
  body = {
    location = var.connected_cluster_location
    properties = {
      priority = 400
      selector = {
        matchLabels = {
          "management.azure.com/provider-name" : "microsoft.iotoperations"
        }
      }
      targetResourceGroup = var.resource_group.id
    }
  }

  count = var.should_deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "aio_device_registry_sync_rule" {
  type      = "Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview"
  name      = "${azapi_resource.custom_location.name}-adr-sync"
  parent_id = azapi_resource.custom_location.id

  body = {
    location = var.connected_cluster_location
    properties = {
      priority = 200
      selector = {
        matchLabels = {
          "management.azure.com/provider-name" : "Microsoft.DeviceRegistry"
        }
      }
      targetResourceGroup = var.resource_group.id
    }
  }

  count = var.should_deploy_resource_sync_rules ? 1 : 0
}

resource "azapi_resource" "instance" {
  type      = "Microsoft.IoTOperations/instances@2026-03-01"
  name      = local.aio_instance_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group.id
  identity {
    type         = "UserAssigned"
    identity_ids = [var.aio_uami_id]
  }
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.id
      type = "CustomLocation"
    }
    properties = {
      schemaRegistryRef = {
        resourceId = var.schema_registry_id
      }
      adrNamespaceRef = var.adr_namespace_id != null ? {
        resourceId = var.adr_namespace_id
      } : null
      features = try(var.aio_features, null)
    }
  }
  depends_on             = [azurerm_arc_kubernetes_cluster_extension.iot_operations]
  response_export_values = ["name", "id"]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2026-03-01 until azapi provider supports it
}

resource "azapi_resource" "broker" {
  type      = "Microsoft.IoTOperations/instances/brokers@2026-03-01"
  name      = "default"
  parent_id = azapi_resource.instance.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.id
      type = "CustomLocation"
    }
    properties = merge(
      {
        memoryProfile = var.mqtt_broker_config.memoryProfile
        generateResourceLimits = {
          cpu = "Disabled"
        }
        cardinality = {
          backendChain = {
            partitions       = var.mqtt_broker_config.backendPartitions
            workers          = var.mqtt_broker_config.backendWorkers
            redundancyFactor = var.mqtt_broker_config.backendRedundancyFactor
          }
          frontend = {
            replicas = var.mqtt_broker_config.frontendReplicas
            workers  = var.mqtt_broker_config.frontendWorkers
          }
        }
        diagnostics = merge(
          {
            logs = {
              level = var.mqtt_broker_config.logsLevel
            }
          },
          try(var.mqtt_broker_diagnostics_config.metrics.prometheus_port != null ? {
            metrics = {
              prometheusPort = var.mqtt_broker_diagnostics_config.metrics.prometheus_port
            }
          } : {}, {}),
          try(
            anytrue([
              var.mqtt_broker_diagnostics_config.self_check.mode != null,
              var.mqtt_broker_diagnostics_config.self_check.interval_seconds != null,
              var.mqtt_broker_diagnostics_config.self_check.timeout_seconds != null
              ]) ? {
              selfCheck = merge(
                var.mqtt_broker_diagnostics_config.self_check.mode != null ? {
                  mode = var.mqtt_broker_diagnostics_config.self_check.mode
                } : {},
                var.mqtt_broker_diagnostics_config.self_check.interval_seconds != null ? {
                  intervalSeconds = var.mqtt_broker_diagnostics_config.self_check.interval_seconds
                } : {},
                var.mqtt_broker_diagnostics_config.self_check.timeout_seconds != null ? {
                  timeoutSeconds = var.mqtt_broker_diagnostics_config.self_check.timeout_seconds
                } : {}
              )
            } : {},
            {}
          ),
          try(
            anytrue([
              var.mqtt_broker_diagnostics_config.traces.mode != null,
              var.mqtt_broker_diagnostics_config.traces.cache_size_megabytes != null,
              var.mqtt_broker_diagnostics_config.traces.span_channel_capacity != null,
              var.mqtt_broker_diagnostics_config.traces.self_tracing != null
              ]) ? {
              traces = merge(
                var.mqtt_broker_diagnostics_config.traces.mode != null ? {
                  mode = var.mqtt_broker_diagnostics_config.traces.mode
                } : {},
                var.mqtt_broker_diagnostics_config.traces.cache_size_megabytes != null ? {
                  cacheSizeMegabytes = var.mqtt_broker_diagnostics_config.traces.cache_size_megabytes
                } : {},
                var.mqtt_broker_diagnostics_config.traces.span_channel_capacity != null ? {
                  spanChannelCapacity = var.mqtt_broker_diagnostics_config.traces.span_channel_capacity
                } : {},
                try(
                  anytrue([
                    var.mqtt_broker_diagnostics_config.traces.self_tracing.mode != null,
                    var.mqtt_broker_diagnostics_config.traces.self_tracing.interval_seconds != null
                    ]) ? {
                    selfTracing = merge(
                      var.mqtt_broker_diagnostics_config.traces.self_tracing.mode != null ? {
                        mode = var.mqtt_broker_diagnostics_config.traces.self_tracing.mode
                      } : {},
                      var.mqtt_broker_diagnostics_config.traces.self_tracing.interval_seconds != null ? {
                        intervalSeconds = var.mqtt_broker_diagnostics_config.traces.self_tracing.interval_seconds
                      } : {}
                    )
                  } : {},
                  {}
                )
              )
            } : {},
            {}
          )
        )
      },
      try({
        persistence = merge(
          {
            maxSize = var.mqtt_broker_persistence_config.max_size
          },
          try({
            encryption = {
              mode = local.enabled_disabled[var.mqtt_broker_persistence_config.encryption_enabled]
            }
          }, {}),
          try({
            retain = merge(
              {
                mode = var.mqtt_broker_persistence_config.retain_policy.mode
              },
              try(
                alltrue([
                  var.mqtt_broker_persistence_config.retain_policy.custom_settings != null,
                  var.mqtt_broker_persistence_config.retain_policy.mode == "Custom"
                  ]) ? anytrue([
                  var.mqtt_broker_persistence_config.retain_policy.custom_settings.topics != null,
                  var.mqtt_broker_persistence_config.retain_policy.custom_settings.dynamic_enabled != null
                  ]) ? {
                  retainSettings = merge(
                    var.mqtt_broker_persistence_config.retain_policy.custom_settings.topics != null ? {
                      topics = var.mqtt_broker_persistence_config.retain_policy.custom_settings.topics
                    } : {},
                    var.mqtt_broker_persistence_config.retain_policy.custom_settings.dynamic_enabled != null ? {
                      dynamic = {
                        mode = local.enabled_disabled[var.mqtt_broker_persistence_config.retain_policy.custom_settings.dynamic_enabled]
                      }
                    } : {}
                  )
                } : {} : {},
                {}
              )
            )
          }, {}),
          try({
            stateStore = merge(
              {
                mode = var.mqtt_broker_persistence_config.state_store_policy.mode
              },
              try(
                alltrue([
                  var.mqtt_broker_persistence_config.state_store_policy.custom_settings != null,
                  var.mqtt_broker_persistence_config.state_store_policy.mode == "Custom"
                  ]) ? anytrue([
                  var.mqtt_broker_persistence_config.state_store_policy.custom_settings.state_store_resources != null,
                  var.mqtt_broker_persistence_config.state_store_policy.custom_settings.dynamic_enabled != null
                  ]) ? {
                  stateStoreSettings = merge(
                    var.mqtt_broker_persistence_config.state_store_policy.custom_settings.state_store_resources != null ? {
                      stateStoreResources = [
                        for resource in var.mqtt_broker_persistence_config.state_store_policy.custom_settings.state_store_resources : {
                          keyType = resource.key_type
                          keys    = resource.keys
                        }
                      ]
                    } : {},
                    var.mqtt_broker_persistence_config.state_store_policy.custom_settings.dynamic_enabled != null ? {
                      dynamic = {
                        mode = local.enabled_disabled[var.mqtt_broker_persistence_config.state_store_policy.custom_settings.dynamic_enabled]
                      }
                    } : {}
                  )
                } : {} : {},
                {}
              )
            )
          }, {}),
          try({
            subscriberQueue = merge(
              {
                mode = var.mqtt_broker_persistence_config.subscriber_queue_policy.mode
              },
              try(
                alltrue([
                  var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings != null,
                  var.mqtt_broker_persistence_config.subscriber_queue_policy.mode == "Custom"
                  ]) ? anytrue([
                  var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.subscriber_client_ids != null,
                  var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.dynamic_enabled != null
                  ]) ? {
                  subscriberQueueSettings = merge(
                    var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.subscriber_client_ids != null ? {
                      subscriberClientIds = var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.subscriber_client_ids
                    } : {},
                    var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.dynamic_enabled != null ? {
                      dynamic = {
                        mode = local.enabled_disabled[var.mqtt_broker_persistence_config.subscriber_queue_policy.custom_settings.dynamic_enabled]
                      }
                    } : {}
                  )
                } : {} : {},
                {}
              )
            )
          }, {}),
          try(
            anytrue([
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_name != null,
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_mode != null,
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.storage_class_name != null,
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.access_modes != null,
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source != null,
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source_ref != null,
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources != null,
              var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector != null
              ]) ? {
              persistentVolumeClaimSpec = merge(
                var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_name != null ? {
                  volumeName = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_name
                } : {},
                var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_mode != null ? {
                  volumeMode = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.volume_mode
                } : {},
                var.mqtt_broker_persistence_config.persistent_volume_claim_spec.storage_class_name != null ? {
                  storageClassName = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.storage_class_name
                } : {},
                var.mqtt_broker_persistence_config.persistent_volume_claim_spec.access_modes != null ? {
                  accessModes = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.access_modes
                } : {},
                try({
                  dataSource = merge(
                    {
                      kind = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source.kind
                      name = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source.name
                    },
                    var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source.api_group != null ? {
                      apiGroup = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source.api_group
                    } : {}
                  )
                }, {}),
                try({
                  dataSourceRef = merge(
                    {
                      kind = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source_ref.kind
                      name = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source_ref.name
                    },
                    var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source_ref.api_group != null ? {
                      apiGroup = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source_ref.api_group
                    } : {},
                    var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source_ref.namespace != null ? {
                      namespace = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.data_source_ref.namespace
                    } : {}
                  )
                }, {}),
                try(
                  anytrue([
                    var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.requests != null,
                    var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.limits != null
                    ]) ? {
                    resources = merge(
                      var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.requests != null ? {
                        requests = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.requests
                      } : {},
                      var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.limits != null ? {
                        limits = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.resources.limits
                      } : {}
                    )
                  } : {},
                  {}
                ),
                try(
                  anytrue([
                    var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_labels != null,
                    var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_expressions != null
                    ]) ? {
                    selector = merge(
                      var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_labels != null ? {
                        matchLabels = var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_labels
                      } : {},
                      var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_expressions != null ? {
                        matchExpressions = [
                          for expr in var.mqtt_broker_persistence_config.persistent_volume_claim_spec.selector.match_expressions : {
                            key      = expr.key
                            operator = expr.operator
                            values   = expr.values
                          }
                        ]
                      } : {}
                    )
                  } : {},
                  {}
                )
              )
            } : {},
            {}
          )
        )
      }, {}),
      try({
        diskBackedMessageBuffer = merge(
          {
            maxSize = var.mqtt_broker_disk_buffer_config.max_size
          },
          try(
            anytrue([
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.volume_name != null,
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.volume_mode != null,
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.storage_class_name != null,
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.access_modes != null,
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source != null,
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source_ref != null,
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.resources != null,
              var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector != null
              ]) ? {
              ephemeralVolumeClaimSpec = merge(
                var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.volume_name != null ? {
                  volumeName = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.volume_name
                } : {},
                var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.volume_mode != null ? {
                  volumeMode = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.volume_mode
                } : {},
                var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.storage_class_name != null ? {
                  storageClassName = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.storage_class_name
                } : {},
                var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.access_modes != null ? {
                  accessModes = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.access_modes
                } : {},
                try({
                  dataSource = merge(
                    {
                      kind = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source.kind
                      name = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source.name
                    },
                    var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source.api_group != null ? {
                      apiGroup = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source.api_group
                    } : {}
                  )
                }, {}),
                try({
                  dataSourceRef = merge(
                    {
                      kind = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source_ref.kind
                      name = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source_ref.name
                    },
                    var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source_ref.api_group != null ? {
                      apiGroup = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source_ref.api_group
                    } : {},
                    var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source_ref.namespace != null ? {
                      namespace = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.data_source_ref.namespace
                    } : {}
                  )
                }, {}),
                try(
                  anytrue([
                    var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.resources.requests != null,
                    var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.resources.limits != null
                    ]) ? {
                    resources = merge(
                      var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.resources.requests != null ? {
                        requests = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.resources.requests
                      } : {},
                      var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.resources.limits != null ? {
                        limits = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.resources.limits
                      } : {}
                    )
                  } : {},
                  {}
                ),
                try(
                  anytrue([
                    var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector.match_labels != null,
                    var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector.match_expressions != null
                    ]) ? {
                    selector = merge(
                      var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector.match_labels != null ? {
                        matchLabels = var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector.match_labels
                      } : {},
                      var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector.match_expressions != null ? {
                        matchExpressions = [
                          for expr in var.mqtt_broker_disk_buffer_config.ephemeral_volume_claim_spec.selector.match_expressions : {
                            key      = expr.key
                            operator = expr.operator
                            values   = expr.values
                          }
                        ]
                      } : {}
                    )
                  } : {},
                  {}
                )
              )
            } : {},
            {}
          ),
          try(
            anytrue([
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.volume_name != null,
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.volume_mode != null,
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.storage_class_name != null,
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.access_modes != null,
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source != null,
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source_ref != null,
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.resources != null,
              var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector != null
              ]) ? {
              persistentVolumeClaimSpec = merge(
                var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.volume_name != null ? {
                  volumeName = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.volume_name
                } : {},
                var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.volume_mode != null ? {
                  volumeMode = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.volume_mode
                } : {},
                var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.storage_class_name != null ? {
                  storageClassName = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.storage_class_name
                } : {},
                var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.access_modes != null ? {
                  accessModes = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.access_modes
                } : {},
                try({
                  dataSource = merge(
                    {
                      kind = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source.kind
                      name = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source.name
                    },
                    var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source.api_group != null ? {
                      apiGroup = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source.api_group
                    } : {}
                  )
                }, {}),
                try({
                  dataSourceRef = merge(
                    {
                      kind = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source_ref.kind
                      name = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source_ref.name
                    },
                    var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source_ref.api_group != null ? {
                      apiGroup = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source_ref.api_group
                    } : {},
                    var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source_ref.namespace != null ? {
                      namespace = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.data_source_ref.namespace
                    } : {}
                  )
                }, {}),
                try(
                  anytrue([
                    var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.resources.requests != null,
                    var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.resources.limits != null
                    ]) ? {
                    resources = merge(
                      var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.resources.requests != null ? {
                        requests = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.resources.requests
                      } : {},
                      var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.resources.limits != null ? {
                        limits = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.resources.limits
                      } : {}
                    )
                  } : {},
                  {}
                ),
                try(
                  anytrue([
                    var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector.match_labels != null,
                    var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector.match_expressions != null
                    ]) ? {
                    selector = merge(
                      var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector.match_labels != null ? {
                        matchLabels = var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector.match_labels
                      } : {},
                      var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector.match_expressions != null ? {
                        matchExpressions = [
                          for expr in var.mqtt_broker_disk_buffer_config.persistent_volume_claim_spec.selector.match_expressions : {
                            key      = expr.key
                            operator = expr.operator
                            values   = expr.values
                          }
                        ]
                      } : {}
                    )
                  } : {},
                  {}
                )
              )
            } : {},
            {}
          )
        )
      }, {}),
      // Advanced broker settings: client limits, internal traffic encryption, and internal certificates
      try({
        advanced = merge(
          var.mqtt_broker_advanced_config.encrypt_internal_traffic != null ? {
            encryptInternalTraffic = var.mqtt_broker_advanced_config.encrypt_internal_traffic
          } : {},
          try({
            internalCerts = merge(
              var.mqtt_broker_advanced_config.internal_certs.duration != null ? {
                duration = var.mqtt_broker_advanced_config.internal_certs.duration
              } : {},
              var.mqtt_broker_advanced_config.internal_certs.renew_before != null ? {
                renewBefore = var.mqtt_broker_advanced_config.internal_certs.renew_before
              } : {},
              try(
                anytrue([
                  var.mqtt_broker_advanced_config.internal_certs.private_key_algorithm != null,
                  var.mqtt_broker_advanced_config.internal_certs.private_key_rotation_policy != null
                  ]) ? {
                  privateKey = merge(
                    var.mqtt_broker_advanced_config.internal_certs.private_key_algorithm != null ? {
                      algorithm = var.mqtt_broker_advanced_config.internal_certs.private_key_algorithm
                    } : {},
                    var.mqtt_broker_advanced_config.internal_certs.private_key_rotation_policy != null ? {
                      rotationPolicy = var.mqtt_broker_advanced_config.internal_certs.private_key_rotation_policy
                    } : {}
                  )
                } : {},
                {}
              )
            )
          }, {}),
          try({
            clients = merge(
              var.mqtt_broker_advanced_config.clients.max_session_expiry_seconds != null ? {
                maxSessionExpirySeconds = var.mqtt_broker_advanced_config.clients.max_session_expiry_seconds
              } : {},
              var.mqtt_broker_advanced_config.clients.max_message_expiry_seconds != null ? {
                maxMessageExpirySeconds = var.mqtt_broker_advanced_config.clients.max_message_expiry_seconds
              } : {},
              var.mqtt_broker_advanced_config.clients.max_packet_size_bytes != null ? {
                maxPacketSizeBytes = var.mqtt_broker_advanced_config.clients.max_packet_size_bytes
              } : {},
              var.mqtt_broker_advanced_config.clients.max_receive_maximum != null ? {
                maxReceiveMaximum = var.mqtt_broker_advanced_config.clients.max_receive_maximum
              } : {},
              var.mqtt_broker_advanced_config.clients.max_keep_alive_seconds != null ? {
                maxKeepAliveSeconds = var.mqtt_broker_advanced_config.clients.max_keep_alive_seconds
              } : {},
              try(
                anytrue([
                  var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.length != null,
                  var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.strategy != null
                  ]) ? {
                  subscriberQueueLimit = merge(
                    var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.length != null ? {
                      length = var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.length
                    } : {},
                    var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.strategy != null ? {
                      strategy = var.mqtt_broker_advanced_config.clients.subscriber_queue_limit.strategy
                    } : {}
                  )
                } : {},
                {}
              )
            )
          }, {})
        )
      }, {})
    )
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.instance]

  replace_triggers_external_values = [var.mqtt_broker_config]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2026-03-01 until azapi provider supports it
}

resource "azapi_resource" "broker_authn" {
  type      = "Microsoft.IoTOperations/instances/brokers/authentications@2026-03-01"
  name      = "default"
  parent_id = azapi_resource.broker.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.id
      type = "CustomLocation"
    }
    properties = {
      authenticationMethods = [
        {
          method = "ServiceAccountToken"
          serviceAccountTokenSettings = {
            audiences = [var.mqtt_broker_config.serviceAccountAudience]
          }
        }
      ]
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.broker]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2026-03-01 until azapi provider supports it
}

resource "azapi_resource" "broker_listener" {
  type      = "Microsoft.IoTOperations/instances/brokers/listeners@2026-03-01"
  name      = "default"
  parent_id = azapi_resource.broker.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      serviceType = var.mqtt_broker_config.serviceType
      serviceName = var.mqtt_broker_config.brokerListenerServiceName
      ports = [
        {
          authenticationRef = "default"
          port              = var.mqtt_broker_config.brokerListenerPort
          tls = {
            mode = "Automatic"
            certManagerCertificateSpec = {
              issuerRef = {
                name  = local.trust.issuer_name
                kind  = local.trust.issuer_kind
                group = "cert-manager.io"
              }
            }
          }
        }
      ]
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.broker, azapi_resource.broker_authn]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2026-03-01 until azapi provider supports it
}

resource "azapi_resource" "broker_listener_anonymous" {
  count = var.should_create_anonymous_broker_listener ? 1 : 0

  type      = "Microsoft.IoTOperations/instances/brokers/listeners@2026-03-01"
  name      = "default-anon"
  parent_id = azapi_resource.broker.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      serviceType = "NodePort"
      serviceName = var.broker_listener_anonymous_config.serviceName
      ports = [
        {
          port     = var.broker_listener_anonymous_config.port
          nodePort = var.broker_listener_anonymous_config.nodePort
        }
      ]
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.broker, azapi_resource.broker_authn]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2026-03-01 until azapi provider supports it
}

resource "azapi_resource" "data_profiles" {
  type      = "Microsoft.IoTOperations/instances/dataflowProfiles@2026-03-01"
  name      = "default"
  parent_id = azapi_resource.instance.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      instanceCount = var.dataflow_instance_count
    }
  }
  depends_on             = [azapi_resource.custom_location, azapi_resource.instance]
  response_export_values = ["name", "id"]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2026-03-01 until azapi provider supports it
}

resource "azapi_resource" "data_endpoint" {
  type      = "Microsoft.IoTOperations/instances/dataflowEndpoints@2026-03-01"
  name      = "default"
  parent_id = azapi_resource.instance.id
  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      endpointType = "Mqtt"
      mqttSettings = {
        host = "${var.mqtt_broker_config.brokerListenerServiceName}:${var.mqtt_broker_config.brokerListenerPort}"
        authentication = {
          method = "ServiceAccountToken"
          serviceAccountTokenSettings = {
            audience = var.mqtt_broker_config.serviceAccountAudience
          }
        }
        tls = {
          mode                             = "Enabled"
          trustedCaCertificateConfigMapRef = local.trust.configmap_name
        }
      }
    }
  }
  depends_on = [azapi_resource.custom_location, azapi_resource.instance]

  schema_validation_enabled = false # Disable schema validation for azapi_resource for 2026-03-01 until azapi provider supports it
}

resource "azapi_resource" "default_aio_keyvault_secret_provider_class" {
  count = var.enable_instance_secret_sync ? 1 : 0

  type      = "Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses@2024-08-21-preview"
  name      = local.spc_name
  location  = var.connected_cluster_location
  parent_id = var.resource_group.id

  body = {
    extendedLocation = {
      name = azapi_resource.custom_location.output.id
      type = "CustomLocation"
    }
    properties = {
      clientId     = var.secret_sync_identity.client_id
      keyvaultName = var.key_vault.name
      tenantId     = data.azurerm_subscription.current.tenant_id
    }
  }

  depends_on = [azapi_resource.custom_location]
}

resource "azapi_update_resource" "aio_instance_secret_sync_update" {
  count     = var.enable_instance_secret_sync ? 1 : 0
  type      = "Microsoft.IoTOperations/instances@2026-03-01"
  name      = local.aio_instance_name
  parent_id = var.resource_group.id

  body = {
    properties = {
      defaultSecretProviderClassRef = {
        resourceId = azapi_resource.default_aio_keyvault_secret_provider_class[0].id
      }
    }
  }

  depends_on = [azapi_resource.default_aio_keyvault_secret_provider_class, azapi_resource.instance]
}
