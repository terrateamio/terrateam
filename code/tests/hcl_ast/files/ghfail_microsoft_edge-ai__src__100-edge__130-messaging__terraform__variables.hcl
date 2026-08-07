/*
 * Optional Variables
 */

variable "asset_name" {
  type        = string
  description = "The name of the Azure IoT Operations Device Registry Asset resource to send its data from edge to cloud."
  default     = "namespace-oven"
}

variable "adr_namespace" {
  type = object({
    id   = string,
    name = string
  })
  description = "Azure Device Registry namespace to use with Azure IoT Operations. Otherwise, not configured."
  default     = null
}

variable "should_create_eventgrid_dataflows" {
  type        = bool
  description = "Whether to create EventGrid dataflows in the edge messaging component"
  default     = true
}

variable "should_create_eventhub_dataflows" {
  type        = bool
  description = "Whether to create EventHub dataflows in the edge messaging component"
  default     = true
}

variable "should_create_fabric_rti_dataflows" {
  type        = bool
  description = "Whether to create fabric RTI dataflows."
  default     = false
}

variable "dataflow_graphs" {
  type = list(object({
    name                     = string
    mode                     = optional(string, "Enabled")
    request_disk_persistence = optional(string, "Disabled")
    nodes = list(object({
      nodeType = string
      name     = string
      sourceSettings = optional(object({
        endpointRef = string
        assetRef    = optional(string)
        dataSources = list(string)
      }))
      graphSettings = optional(object({
        registryEndpointRef = string
        artifact            = string
        configuration = optional(list(object({
          key   = string
          value = string
        })))
      }))
      destinationSettings = optional(object({
        endpointRef     = string
        dataDestination = string
        headers = optional(list(object({
          actionType = string
          key        = string
          value      = optional(string)
        })))
      }))
    }))
    node_connections = list(object({
      from = object({
        name = string
        schema = optional(object({
          schemaRef           = string
          serializationFormat = optional(string, "Json")
        }))
      })
      to = object({
        name = string
      })
    }))
  }))
  description = "List of dataflow graphs to create with their node configurations"
  default     = []

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", graph.name)) && length(graph.name) >= 3 && length(graph.name) <= 63
    ])
    error_message = "Dataflow graph name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      contains(["Enabled", "Disabled"], graph.mode)
    ])
    error_message = "Dataflow graph mode must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs :
      contains(["Enabled", "Disabled"], graph.request_disk_persistence)
    ])
    error_message = "Dataflow graph request_disk_persistence must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs : alltrue([
        for node in graph.nodes :
        contains(["Source", "Graph", "Destination"], node.nodeType)
      ])
    ])
    error_message = "Node type must be one of: 'Source', 'Graph', or 'Destination'."
  }

  validation {
    condition = alltrue([
      for graph in var.dataflow_graphs : alltrue([
        for node in graph.nodes :
        node.destinationSettings == null || node.destinationSettings.headers == null || alltrue([
          for header in coalesce(node.destinationSettings.headers, []) :
          contains(["AddIfNotPresent", "AddOrReplace", "Remove"], header.actionType)
        ])
      ])
    ])
    error_message = "Header action type must be one of: 'AddIfNotPresent', 'AddOrReplace', or 'Remove'."
  }
}

variable "dataflows" {
  type = list(object({
    name                     = string
    mode                     = optional(string, "Enabled")
    request_disk_persistence = optional(string, "Disabled")
    operations = list(object({
      operationType = string
      name          = optional(string)
      sourceSettings = optional(object({
        endpointRef         = string
        assetRef            = optional(string)
        serializationFormat = optional(string, "Json")
        schemaRef           = optional(string)
        dataSources         = list(string)
      }))
      builtInTransformationSettings = optional(object({
        serializationFormat = optional(string, "Json")
        schemaRef           = optional(string)
        datasets = optional(list(object({
          key         = string
          description = optional(string)
          schemaRef   = optional(string)
          inputs      = list(string)
          expression  = string
        })))
        filter = optional(list(object({
          type        = optional(string, "Filter")
          description = optional(string)
          inputs      = list(string)
          expression  = string
        })))
        map = optional(list(object({
          type        = optional(string, "NewProperties")
          description = optional(string)
          inputs      = list(string)
          expression  = optional(string)
          output      = string
        })))
      }))
      destinationSettings = optional(object({
        endpointRef     = string
        dataDestination = string
      }))
    }))
  }))
  description = "List of dataflows to create with their operation configurations"
  default     = []

  validation {
    condition = alltrue([
      for df in var.dataflows :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", df.name)) && length(df.name) >= 3 && length(df.name) <= 63
    ])
    error_message = "Dataflow name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows :
      contains(["Enabled", "Disabled"], df.mode)
    ])
    error_message = "Dataflow mode must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows :
      contains(["Enabled", "Disabled"], df.request_disk_persistence)
    ])
    error_message = "Dataflow request_disk_persistence must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        contains(["Source", "Destination", "BuiltInTransformation"], op.operationType)
      ])
    ])
    error_message = "Operation type must be one of: 'Source', 'Destination', or 'BuiltInTransformation'."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        op.operationType != "Source" || op.sourceSettings != null
      ])
    ])
    error_message = "Source operations must include sourceSettings."
  }

  validation {
    condition = alltrue([
      for df in var.dataflows : alltrue([
        for op in df.operations :
        op.operationType != "Destination" || op.destinationSettings != null
      ])
    ])
    error_message = "Destination operations must include destinationSettings."
  }
}

variable "dataflow_endpoints" {
  type = list(object({
    name         = string
    endpointType = string
    hostType     = optional(string)
    dataExplorerSettings = optional(object({
      authentication = object({
        method = string
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
      })
      batching = optional(object({
        latencySeconds = optional(number)
        maxMessages    = optional(number)
      }))
      database = string
      host     = string
    }))
    dataLakeStorageSettings = optional(object({
      authentication = object({
        accessTokenSettings = optional(object({
          secretRef = string
        }))
        method = string
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
      })
      batching = optional(object({
        latencySeconds = optional(number)
        maxMessages    = optional(number)
      }))
      host = string
    }))
    fabricOneLakeSettings = optional(object({
      authentication = object({
        method = string
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
      })
      batching = optional(object({
        latencySeconds = optional(number)
        maxMessages    = optional(number)
      }))
      host = string
      names = object({
        lakehouseName = string
        workspaceName = string
      })
      oneLakePathType = string
    }))
    kafkaSettings = optional(object({
      authentication = object({
        method = string
        saslSettings = optional(object({
          saslType  = string
          secretRef = string
        }))
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
        x509CertificateSettings = optional(object({
          secretRef = string
        }))
      })
      batching = optional(object({
        latencyMs   = optional(number)
        maxBytes    = optional(number)
        maxMessages = optional(number)
        mode        = optional(string)
      }))
      cloudEventAttributes = optional(string)
      compression          = optional(string)
      consumerGroupId      = optional(string)
      copyMqttProperties   = optional(string)
      host                 = string
      kafkaAcks            = optional(string)
      partitionStrategy    = optional(string)
      tls = optional(object({
        mode                             = optional(string)
        trustedCaCertificateConfigMapRef = optional(string)
      }))
    }))
    localStorageSettings = optional(object({
      persistentVolumeClaimRef = string
    }))
    mqttSettings = optional(object({
      authentication = object({
        method = string
        serviceAccountTokenSettings = optional(object({
          audience = string
        }))
        systemAssignedManagedIdentitySettings = optional(object({
          audience = optional(string)
        }))
        userAssignedManagedIdentitySettings = optional(object({
          clientId = string
          scope    = optional(string)
          tenantId = string
        }))
        x509CertificateSettings = optional(object({
          secretRef = string
        }))
      })
      clientIdPrefix       = optional(string)
      cloudEventAttributes = optional(string)
      host                 = optional(string)
      keepAliveSeconds     = optional(number)
      maxInflightMessages  = optional(number)
      protocol             = optional(string)
      qos                  = optional(number)
      retain               = optional(string)
      sessionExpirySeconds = optional(number)
      tls = optional(object({
        mode                             = optional(string)
        trustedCaCertificateConfigMapRef = optional(string)
      }))
    }))
    openTelemetrySettings = optional(object({
      authentication = object({
        method            = string
        anonymousSettings = optional(any)
        serviceAccountTokenSettings = optional(object({
          audience = string
        }))
        x509CertificateSettings = optional(object({
          secretRef = string
        }))
      })
      batching = optional(object({
        latencySeconds = optional(number)
        maxMessages    = optional(number)
      }))
      host = string
      tls = optional(object({
        mode                             = optional(string)
        trustedCaCertificateConfigMapRef = optional(string)
      }))
    }))
  }))
  description = "List of dataflow endpoints to create with their type-specific configurations"
  default     = []

  validation {
    condition = alltrue([
      for ep in var.dataflow_endpoints :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", ep.name)) && length(ep.name) >= 3 && length(ep.name) <= 63
    ])
    error_message = "Dataflow endpoint name must be 3-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for ep in var.dataflow_endpoints :
      contains(["DataExplorer", "DataLakeStorage", "FabricOneLake", "Kafka", "LocalStorage", "Mqtt", "OpenTelemetry"], ep.endpointType)
    ])
    error_message = "Endpoint type must be one of: 'DataExplorer', 'DataLakeStorage', 'FabricOneLake', 'Kafka', 'LocalStorage', 'Mqtt', or 'OpenTelemetry'."
  }

  validation {
    condition = alltrue([
      for ep in var.dataflow_endpoints :
      ep.hostType == null || contains(["CustomKafka", "CustomMqtt", "EventGrid", "Eventhub", "FabricRT", "LocalBroker"], ep.hostType)
    ])
    error_message = "Host type must be one of: 'CustomKafka', 'CustomMqtt', 'EventGrid', 'Eventhub', 'FabricRT', or 'LocalBroker'."
  }

  validation {
    condition = alltrue([
      for ep in var.dataflow_endpoints :
      (ep.endpointType != "DataExplorer" || ep.dataExplorerSettings != null) &&
      (ep.endpointType != "DataLakeStorage" || ep.dataLakeStorageSettings != null) &&
      (ep.endpointType != "FabricOneLake" || ep.fabricOneLakeSettings != null) &&
      (ep.endpointType != "Kafka" || ep.kafkaSettings != null) &&
      (ep.endpointType != "LocalStorage" || ep.localStorageSettings != null) &&
      (ep.endpointType != "Mqtt" || ep.mqttSettings != null) &&
      (ep.endpointType != "OpenTelemetry" || ep.openTelemetrySettings != null)
    ])
    error_message = "Each endpoint must include the settings object matching its endpointType (e.g., kafkaSettings for Kafka, mqttSettings for Mqtt)."
  }
}
