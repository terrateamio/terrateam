/*
 * Dataflow Endpoint Dependency Parameters
 */

variable "aio_instance" {
  type = object({
    id = string
  })
  description = "The Azure IoT Operations instance object"
}

variable "custom_location" {
  type = object({
    id = string
  })
  description = "The custom location object"
}

/*
 * Dataflow Endpoint Parameters
 */

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
