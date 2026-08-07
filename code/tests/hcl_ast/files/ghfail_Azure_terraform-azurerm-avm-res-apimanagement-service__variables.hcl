# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations

# Below AI generated

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."
}

variable "publisher_email" {
  type        = string
  description = "The email of the API Management service publisher."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.publisher_email))
    error_message = "The publisher_email must be a valid email address."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "additional_location" {
  type = list(object({
    location             = string
    capacity             = optional(number, null)
    zones                = optional(list(string), null)
    public_ip_address_id = optional(string, null)
    gateway_disabled     = optional(bool, null)
    virtual_network_configuration = optional(object({
      subnet_id = string
    }), null)
  }))
  default     = []
  description = "Additional datacenter locations where the API Management service should be provisioned."
  nullable    = false
}

# API Version Sets for managing API versions
variable "api_version_sets" {
  type = map(object({
    display_name        = string
    versioning_scheme   = string
    description         = optional(string)
    version_header_name = optional(string)
    version_query_name  = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
API Version Sets for the API Management service. Version sets enable API versioning using Header, Query, or Segment-based schemes.

- `display_name` - (Required) The display name of the API version set.
- `versioning_scheme` - (Required) The versioning scheme. Valid values: `Header`, `Query`, `Segment`.
- `description` - (Optional) Description of the API version set.
- `version_header_name` - (Optional) Name of the HTTP header parameter for the `Header` versioning scheme. Required when `versioning_scheme` is `Header`.
- `version_query_name` - (Optional) Name of the query string parameter for the `Query` versioning scheme. Required when `versioning_scheme` is `Query`.

Example:
```terraform
api_version_sets = {
  "my-api-versions" = {
    display_name        = "My API Versions"
    versioning_scheme   = "Header"
    version_header_name = "api-version"
    description         = "Version set for My API"
  }
}
```
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.api_version_sets :
      contains(["Header", "Query", "Segment"], v.versioning_scheme)
    ])
    error_message = "versioning_scheme must be one of: Header, Query, Segment."
  }
  validation {
    condition = alltrue([
      for k, v in var.api_version_sets :
      v.versioning_scheme != "Header" || v.version_header_name != null
    ])
    error_message = "version_header_name is required when versioning_scheme is 'Header'."
  }
  validation {
    condition = alltrue([
      for k, v in var.api_version_sets :
      v.versioning_scheme != "Query" || v.version_query_name != null
    ])
    error_message = "version_query_name is required when versioning_scheme is 'Query'."
  }
}

# APIs - Core API definitions with operations and policies
variable "apis" {
  type = map(object({
    # Basic API properties
    display_name          = string
    path                  = string
    protocols             = optional(list(string), ["https"])
    revision              = optional(string, "1")
    service_url           = optional(string)
    description           = optional(string)
    subscription_required = optional(bool, true)

    # API versioning
    api_version          = optional(string)
    api_version_set_name = optional(string)
    revision_description = optional(string)

    # Import configuration (OpenAPI, WSDL, WADL, etc.)
    import = optional(object({
      content_format = string
      content_value  = string
      wsdl_selector = optional(object({
        service_name  = string
        endpoint_name = string
      }))
    }))

    # Source API for cloning
    source_api_id = optional(string)

    # OAuth2 Authorization
    oauth2_authorization = optional(object({
      authorization_server_name = string
      scope                     = optional(string)
    }))

    # OpenID Connect Authentication
    openid_authentication = optional(object({
      openid_provider_name         = string
      bearer_token_sending_methods = optional(list(string))
    }))

    # Subscription key parameter names
    subscription_key_parameter_names = optional(object({
      header = string
      query  = string
    }))

    # Contact information
    contact = optional(object({
      email = optional(string)
      name  = optional(string)
      url   = optional(string)
    }))

    # License information
    license = optional(object({
      name = optional(string)
      url  = optional(string)
    }))

    terms_of_service_url = optional(string)

    # API-level policy
    policy = optional(object({
      xml_content = optional(string)
      xml_link    = optional(string)
    }))

    # API operations
    operations = optional(map(object({
      display_name = string
      method       = string
      url_template = string
      description  = optional(string)

      # Template parameters (URL path parameters)
      template_parameters = optional(list(object({
        name          = string
        required      = bool
        type          = string
        description   = optional(string)
        default_value = optional(string)
        values        = optional(list(string))
      })))

      # Request configuration
      request = optional(object({
        description = optional(string)

        query_parameters = optional(list(object({
          name          = string
          required      = bool
          type          = string
          description   = optional(string)
          default_value = optional(string)
          values        = optional(list(string))
        })))

        headers = optional(list(object({
          name          = string
          required      = bool
          type          = string
          description   = optional(string)
          default_value = optional(string)
          values        = optional(list(string))
        })))

        representations = optional(list(object({
          content_type = string
          schema_id    = optional(string)
          type_name    = optional(string)

          form_parameters = optional(list(object({
            name          = string
            required      = bool
            type          = string
            description   = optional(string)
            default_value = optional(string)
            values        = optional(list(string))
          })))
        })))
      }))

      # Response configuration
      responses = optional(list(object({
        status_code = number
        description = optional(string)

        headers = optional(list(object({
          name          = string
          required      = bool
          type          = string
          description   = optional(string)
          default_value = optional(string)
          values        = optional(list(string))
        })))

        representations = optional(list(object({
          content_type = string
          schema_id    = optional(string)
          type_name    = optional(string)

          form_parameters = optional(list(object({
            name          = string
            required      = bool
            type          = string
            description   = optional(string)
            default_value = optional(string)
            values        = optional(list(string))
          })))
        })))
      })))

      # Operation-level policy
      policy = optional(object({
        xml_content = optional(string)
        xml_link    = optional(string)
      }))
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
APIs for the API Management service. APIs define the operations available to API consumers.

- `display_name` - (Required) The display name of the API.
- `path` - (Required) The relative path for the API. Must be unique within the API Management service.
- `protocols` - (Optional) A list of protocols the API supports. Valid values: `http`, `https`, `ws`, `wss`. Defaults to `["https"]`.
- `revision` - (Optional) The revision number of the API. Defaults to `"1"`.
- `service_url` - (Optional) The backend service URL for the API.
- `description` - (Optional) Description of the API.
- `subscription_required` - (Optional) Whether a subscription key is required to access the API. Defaults to `true`.

Versioning:
- `api_version` - (Optional) The version identifier for the API.
- `api_version_set_name` - (Optional) The name of the API version set to associate with this API.
- `revision_description` - (Optional) Description of the API revision.

Import:
- `import` - (Optional) Import configuration for OpenAPI, WSDL, WADL specifications.
  - `content_format` - (Required) Format of the content. Valid values: `openapi`, `openapi+json`, `openapi+json-link`, `openapi-link`, `swagger-json`, `swagger-link-json`, `wadl-link-json`, `wadl-xml`, `wsdl`, `wsdl-link`.
  - `content_value` - (Required) The API definition content or URL.
  - `wsdl_selector` - (Optional) WSDL selector for SOAP APIs.

Operations:
- `operations` - (Optional) Map of API operations. Each operation defines an HTTP method and URL template.

Policies:
- `policy` - (Optional) API-level policy configuration.
  - `xml_content` - (Optional) XML policy content.
  - `xml_link` - (Optional) URL to XML policy content.

Example:
```terraform
apis = {
  "petstore-api" = {
    display_name = "Petstore API"
    path         = "petstore"
    protocols    = ["https"]
    service_url  = "https://petstore.swagger.io/v2"

    operations = {
      "get-pets" = {
        display_name = "Get all pets"
        method       = "GET"
        url_template = "/pets"
      }
    }
  }
}
```
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.apis :
      can(regex("^[^*#&+:<>?]+$", v.path))
    ])
    error_message = "API path cannot contain the following characters: *, #, &, +, :, <, >, ?."
  }
  validation {
    condition = alltrue([
      for k, v in var.apis :
      alltrue([
        for protocol in v.protocols :
        contains(["http", "https", "ws", "wss"], protocol)
      ])
    ])
    error_message = "API protocols must be one of: http, https, ws, wss."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.apis : [
        for operation_key, operation_value in v.operations :
        contains(["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "TRACE"], operation_value.method)
      ]
    ]))
    error_message = "API operation method must be one of: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, TRACE."
  }
}

variable "certificate" {
  type = list(object({
    encoded_certificate  = string
    store_name           = string
    certificate_password = optional(string, null)
  }))
  default     = []
  description = "Certificate configurations for the API Management service."
  nullable    = false

  validation {
    condition     = length(var.certificate) <= 10
    error_message = "A maximum of 10 certificates can be added to an API Management service."
  }
  validation {
    condition     = alltrue([for cert in var.certificate : contains(["CertificateAuthority", "Root"], cert.store_name)])
    error_message = "The store_name must be one of: 'CertificateAuthority', 'Root'."
  }
}

variable "client_certificate_enabled" {
  type        = bool
  default     = false
  description = "Enforce a client certificate to be presented on each request to the gateway. This is only supported when SKU type is Consumption."
  nullable    = false

  validation {
    condition     = startswith(var.sku_name, "Consumption") ? true : !var.client_certificate_enabled
    error_message = "Client certificate is only supported when SKU type is Consumption (e.g., Consumption_1, Consumption_2, etc)."
  }
}

variable "delegation" {
  type = object({
    subscriptions_enabled     = optional(bool, false)
    user_registration_enabled = optional(bool, false)
    url                       = optional(string, null)
    validation_key            = optional(string, null)
  })
  default     = null
  description = "Delegation settings for the API Management service."
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "gateway_disabled" {
  type        = bool
  default     = false
  description = "Disable the gateway in the main region? This is only supported when additional_location is set."
  nullable    = false

  validation {
    condition     = var.gateway_disabled == false || length(var.additional_location) > 0
    error_message = "Gateway can only be disabled in the main region when at least one additional location is configured."
  }
}

variable "hostname_configuration" {
  type = object({
    management = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string, null)
      certificate                     = optional(string, null)
      certificate_password            = optional(string, null)
      negotiate_client_certificate    = optional(bool, false)
      ssl_keyvault_identity_client_id = optional(string, null)
    })), [])
    portal = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string, null)
      certificate                     = optional(string, null)
      certificate_password            = optional(string, null)
      negotiate_client_certificate    = optional(bool, false)
      ssl_keyvault_identity_client_id = optional(string, null)
    })), [])
    developer_portal = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string, null)
      certificate                     = optional(string, null)
      certificate_password            = optional(string, null)
      negotiate_client_certificate    = optional(bool, false)
      ssl_keyvault_identity_client_id = optional(string, null)
    })), [])
    proxy = optional(list(object({
      host_name                       = string
      default_ssl_binding             = optional(bool, false)
      key_vault_id                    = optional(string, null)
      certificate                     = optional(string, null)
      certificate_password            = optional(string, null)
      negotiate_client_certificate    = optional(bool, false)
      ssl_keyvault_identity_client_id = optional(string, null)
    })), [])
    scm = optional(list(object({
      host_name                       = string
      key_vault_id                    = optional(string, null)
      certificate                     = optional(string, null)
      certificate_password            = optional(string, null)
      negotiate_client_certificate    = optional(bool, false)
      ssl_keyvault_identity_client_id = optional(string, null)
    })), [])
  })
  default     = null
  description = "Hostname configuration for the API Management service."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "min_api_version" {
  type        = string
  default     = null
  description = "The version which the control plane API calls to API Management service are limited with version equal to or newer than."
}

# Named Values for configuration and secrets management
variable "named_values" {
  type = map(object({
    display_name = string
    value        = optional(string)
    secret       = optional(bool, false)
    tags         = optional(list(string), [])
    value_from_key_vault = optional(object({
      secret_id          = string
      identity_client_id = optional(string)
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
Named values for the API Management service. Named values are a collection of key/value pairs that can be referenced in policies and API configurations.

- `display_name` - (Required) The display name of the named value. Must be unique within the API Management service.
- `value` - (Optional) The value of the named value. Conflicts with `value_from_key_vault`. If neither is specified, the named value must be set through other means.
- `secret` - (Optional) Whether the value is a secret and should be encrypted. Defaults to `false`.
- `tags` - (Optional) A list of tags that can be used to filter the named values list.
- `value_from_key_vault` - (Optional) A Key Vault configuration for secret values. Conflicts with `value`.
  - `secret_id` - (Required) The versioned secret ID from Key Vault (e.g., `https://myvault.vault.azure.net/secrets/mysecret/version`).
  - `identity_client_id` - (Optional) The client ID of a user-assigned managed identity to use for Key Vault access. If not specified, the system-assigned identity will be used.

Example:
```terraform
named_values = {
  "api-key" = {
    display_name = "API Key"
    value        = "my-secret-key"
    secret       = true
    tags         = ["production", "api"]
  }
  "keyvault-secret" = {
    display_name = "Database Connection String"
    secret       = true
    value_from_key_vault = {
      secret_id = "https://myvault.vault.azure.net/secrets/db-conn/abc123"
    }
  }
}
```
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.named_values :
      v.display_name != null && v.display_name != ""
    ])
    error_message = "All named values must have a non-empty display_name."
  }
  validation {
    condition = alltrue([
      for k, v in var.named_values :
      (v.value != null && v.value_from_key_vault == null) ||
      (v.value == null && v.value_from_key_vault != null) ||
      (v.value == null && v.value_from_key_vault == null)
    ])
    error_message = "Each named value must specify either 'value' or 'value_from_key_vault', but not both."
  }
  validation {
    condition = alltrue([
      for k, v in var.named_values :
      can(regex("^[a-zA-Z0-9-._]+$", k))
    ])
    error_message = "Named value keys can only contain letters, numbers, hyphens, periods, and underscores."
  }
}

variable "notification_sender_email" {
  type        = string
  default     = null
  description = "Email address from which the notification will be sent."
}

variable "policy" {
  type = object({
    xml_content = string
  })
  default     = null
  description = <<DESCRIPTION
Service-level (global) policy for the API Management service. This policy applies to all APIs.

- `xml_content` - (Required) The XML content of the policy.

Example:
```terraform
policy = {
  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <cors allow-credentials="true">
      <allowed-origins>
        <origin>https://example.com</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
      </allowed-methods>
    </cors>
    <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription.Id)" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
    <set-header name="X-Powered-By" exists-action="delete" />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}
```
DESCRIPTION
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false

  validation {
    condition = length(var.private_endpoints) == 0 || (
    var.virtual_network_type == "None" || can(regex("StandardV2|PremiumV2", var.sku_name))) && !startswith(var.sku_name, "Consumption")
    error_message = "Private endpoints are not supported with Consumption SKU or when using Internal/External virtual network mode (unless using StandardV2 or PremiumV2 SKU)."
  }
}

# This variable is used to determine if the private_dns_zone_group block should be included,
# or if it is to be managed externally, e.g. using Azure Policy.
# https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault/issues/32
# Alternatively you can use AzAPI, which does not have this issue.
#TODO: add DNS zone if enabled
variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

# Products variable
variable "products" {
  type = map(object({
    display_name          = string
    description           = optional(string)
    terms                 = optional(string)
    subscription_required = optional(bool, false)
    approval_required     = optional(bool, false)
    subscriptions_limit   = optional(number)
    state                 = optional(string, "published") # published, notPublished

    # Associations
    api_names   = optional(list(string), [])
    group_names = optional(list(string), [])
  }))
  default     = {}
  description = <<DESCRIPTION
Products for the API Management service. The map key is the product identifier.

- `display_name` - (Required) The display name of the product.
- `description` - (Optional) Description of the product.
- `terms` - (Optional) Terms of use for the product.
- `subscription_required` - (Optional) Whether a subscription is required to access APIs in this product. Default is `false`.
- `approval_required` - (Optional) Whether subscription approval is required. Default is `false`.
- `subscriptions_limit` - (Optional) Maximum number of subscriptions allowed for this product.
- `state` - (Optional) Publication state of the product. Valid values: `published`, `notPublished`. Default is `published`.
- `api_names` - (Optional) List of API names to associate with this product.
- `group_names` - (Optional) List of group names to associate with this product (e.g., "developers", "administrators", "guests").

Example:
```terraform
products = {
  "starter" = {
    display_name          = "Starter"
    description           = "Starter product for new developers"
    subscription_required = true
    approval_required     = false
    state                 = "published"
    api_names             = ["petstore-api", "weather-api"]
    group_names           = ["developers"]
  }
}
```
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.products :
      contains(["published", "notPublished"], v.state)
    ])
    error_message = "Product state must be either 'published' or 'notPublished'."
  }
}

variable "protocols" {
  type = object({
    enable_http2 = optional(bool, false)
  })
  default     = null
  description = "Protocol settings for the API Management service."
}

variable "public_ip_address_id" {
  type        = string
  default     = null
  description = "ID of a standard SKU IPv4 Public IP. Only supported on Premium and Developer tiers when deployed in a virtual network."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Is public access to the API Management service allowed? This only applies to the Management plane, not the API gateway or Developer portal."
  nullable    = false
}

variable "publisher_name" {
  type        = string
  default     = "Apim Example Publisher"
  description = "The name of the API Management service publisher."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "security" {
  type = object({
    enable_backend_ssl30                                = optional(bool, false)
    enable_backend_tls10                                = optional(bool, false)
    enable_backend_tls11                                = optional(bool, false)
    enable_frontend_ssl30                               = optional(bool, false)
    enable_frontend_tls10                               = optional(bool, false)
    enable_frontend_tls11                               = optional(bool, false)
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = optional(bool, false)
    tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = optional(bool, false)
    tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = optional(bool, false)
    tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = optional(bool, false)
    tls_rsa_with_aes128_cbc_sha256_ciphers_enabled      = optional(bool, false)
    tls_rsa_with_aes128_cbc_sha_ciphers_enabled         = optional(bool, false)
    tls_rsa_with_aes128_gcm_sha256_ciphers_enabled      = optional(bool, false)
    tls_rsa_with_aes256_gcm_sha384_ciphers_enabled      = optional(bool, false)
    tls_rsa_with_aes256_cbc_sha256_ciphers_enabled      = optional(bool, false)
    tls_rsa_with_aes256_cbc_sha_ciphers_enabled         = optional(bool, false)
    triple_des_ciphers_enabled                          = optional(bool, false)
  })
  default     = null
  description = "Security settings for the API Management service."
}

variable "sign_in" {
  type = object({
    enabled = bool
  })
  default     = null
  description = "Sign-in settings for the API Management service. When enabled, anonymous users will be redirected to the sign-in page."
}

variable "sign_up" {
  type = object({
    enabled = bool
    terms_of_service = object({
      consent_required = bool
      enabled          = bool
      text             = optional(string, null)
    })
  })
  default     = null
  description = "Sign-up settings for the API Management service."
}

variable "sku_name" {
  type        = string
  default     = "Developer_1"
  description = "The SKU name of the API Management service."

  validation {
    condition     = can(regex("^Consumption_0$|^Basic_(1|2)$|^BasicV2_([1-9]|10)|^Developer_1$|^Premium_([1-9][0-9]{0,1})$|^PremiumV2_([1-9]|1[0-9]|2[0-9]|30)$|^Standard_[1-4]$|^StandardV2_([1-9]|10)$", var.sku_name))
    error_message = "The sku_name must be one of: Consumption_0, Basic_1, Basic_2, BasicV2_1 through BasicV2_10, Developer_1, Premium_1 through Premium_99, PremiumV2_1 through PremiumV2_30, Standard_1 through Standard_4, or StandardV2_1 through StandardV2_10."
  }
}

# Subscriptions variable
variable "subscriptions" {
  type = map(object({
    display_name     = string
    scope_type       = string           # "product", "api", or "all_apis"
    scope_identifier = optional(string) # Product ID or API name (not needed for "all_apis")
    user_id          = optional(string)
    primary_key      = optional(string)
    secondary_key    = optional(string)
    state            = optional(string, "active") # active, suspended, submitted, rejected, cancelled
    allow_tracing    = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
Subscriptions for the API Management service. The map key is the subscription identifier.

- `display_name` - (Required) The display name of the subscription.
- `scope_type` - (Required) The scope type. Valid values: `product`, `api`, `all_apis`.
- `scope_identifier` - (Optional) The product ID or API name. Required for `product` and `api` scope types. Not needed for `all_apis`.
- `user_id` - (Optional) The user ID for this subscription (format: /users/{userId}).
- `primary_key` - (Optional) Custom primary subscription key.
- `secondary_key` - (Optional) Custom secondary subscription key.
- `state` - (Optional) The state of the subscription. Valid values: `active`, `suspended`, `submitted`, `rejected`, `cancelled`. Default is `active`.
- `allow_tracing` - (Optional) Whether tracing is allowed. Default is `false`.

Example:
```terraform
subscriptions = {
  "developer-sub" = {
    display_name     = "Developer Subscription"
    scope_type       = "product"
    scope_identifier = "starter"
    state            = "active"
    allow_tracing    = true
  }
  "api-specific-sub" = {
    display_name     = "Petstore API Subscription"
    scope_type       = "api"
    scope_identifier = "petstore-api"
    state            = "active"
  }
}
```
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.subscriptions :
      contains(["product", "api", "all_apis"], v.scope_type)
    ])
    error_message = "Subscription scope_type must be one of: product, api, all_apis."
  }
  validation {
    condition = alltrue([
      for k, v in var.subscriptions :
      v.scope_type == "all_apis" || v.scope_identifier != null
    ])
    error_message = "Subscription scope_identifier is required when scope_type is 'product' or 'api'."
  }
  validation {
    condition = alltrue([
      for k, v in var.subscriptions :
      contains(["active", "suspended", "submitted", "rejected", "cancelled"], v.state)
    ])
    error_message = "Subscription state must be one of: active, suspended, submitted, rejected, cancelled."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "tenant_access" {
  type = object({
    enabled = bool
  })
  default     = null
  description = "Controls whether access to the management API is enabled. When enabled, the primary/secondary keys provide access to this API."
}

variable "virtual_network_subnet_id" {
  type        = string
  default     = null
  description = "The ID of the subnet in the virtual network where the API Management service will be deployed."

  validation {
    condition     = var.virtual_network_type == "None" ? var.virtual_network_subnet_id == null : true
    error_message = "The virtual_network_subnet_id must not be set when virtual_network_type is None."
  }
}

variable "virtual_network_type" {
  type        = string
  default     = "None"
  description = "The type of virtual network configuration for the API Management service."

  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "The virtual_network_type must be one of: None, External, or Internal."
  }
}

variable "zones" {
  type        = list(string)
  default     = null
  description = "Specifies a list of Availability Zones in which this API Management service should be located. Only supported in the Premium tier."

  validation {
    condition     = var.zones == null || startswith(var.sku_name, "Premium")
    error_message = "Availability Zones are only supported in the Premium tier."
  }
}
