//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

output "service_id" {
  description = "The ID of the API Management Service created"
  value       = azurerm_api_management.apim_service.id
}

output "gateway_url" {
  description = "The URL of the Gateway for the API Management Service"
  value       = azurerm_api_management.apim_service.gateway_url
}

output "service_public_ip_addresses" {
  description = "The Public IP addresses of the API Management Service"
  value       = azurerm_api_management.apim_service.public_ip_addresses
}

output "service_identity_tenant_id" {
  description = "The Tenant ID for the Service Principal associated with the Managed Service Identity of this API Management Service"
  value       = azurerm_api_management.apim_service.identity[0].tenant_id
}

output "service_identity_object_id" {
  description = "The Principal ID for the Service Principal associated with the Managed Service Identity for the API Management Service"
  value       = azurerm_api_management.apim_service.identity[0].principal_id
}

output "group_ids" {
  description = "The IDs of the API Management Groups created"
  value = {
    for group in azurerm_api_management_group.group :
    group.name => group.id
  }
}

output "api_version_set_ids" {
  description = "The IDs of the API Version Sets created"
  value = {
    for api_version_set in azurerm_api_management_api_version_set.api_version_set :
    api_version_set.name => api_version_set.id
  }
}

output "api_outputs" {
  description = "The IDs, state, and version outputs of the APIs created"
  value = {
    for api in azurerm_api_management_api.api :
    api.name => {
      id             = api.id
      is_current     = api.is_current
      is_online      = api.is_online
      version        = api.version
      version_set_id = api.version_set_id
    }
  }
}

output "product_ids" {
  description = "The IDs of the Products created"
  value = {
    for product in azurerm_api_management_product.product :
    product.product_id => product.id
  }
}

output "named_value_ids" {
  description = "The IDs of the Named Values created"
  value = {
    for named_value in azurerm_api_management_property.named_value :
    named_value.name => named_value.id
  }
}

output "backend_ids" {
  description = "The IDs of the Backends created"
  value = {
    for backend in azurerm_api_management_backend.backend :
    backend.name => backend.id
  }
}

output "product_api_ids" {
  description = "The IDs of the Product/API associations created"
  value       = azurerm_api_management_product_api.product_api.*.id
}

output "product_group_ids" {
  description = "The IDs of the Product/Group associations created"
  value       = azurerm_api_management_product_group.product_group.*.id
}
