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

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

locals {
  product_api_associations = flatten([
    for product in var.products : [
      for api_name in product.apis : [
        {
          product_id = product.product_id
          api_name   = api_name
        }
      ]
    ]
  ])
  product_group_associations = flatten([
    for product in var.products : [
      for group_name in product.groups : [
        {
          product_id = product.product_id
          group_name = group_name
        }
      ]
    ]
  ])
  product_tag_associations = flatten([
    for product in var.products : [
      for tag_name in product.tags : [
        {
          product_id = product.product_id
          tag_name   = tag_name
        }
      ]
    ]
  ])
  product_policy_associations = [
    for product in var.products :
    {
      product_id     = product.product_id
      policy_content = product.policy.content
      policy_format  = product.policy.format
    }
    if product.policy != null
  ]
  api_tag_associations = flatten([
    for api in var.apis : [
      for tag_name in api.tags : [
        {
          api_name = api.name
          tag_name = tag_name
        }
      ]
    ]
  ])
  api_policy_associations = [
    for api in var.apis :
    {
      api_name       = api.name
      policy_content = api.policy.content
      policy_format  = api.policy.format
    }
    if api.policy != null
  ]
  api_operation_policy_associations = flatten([
    for api in var.apis : [
      for operation_policy in api.operation_policies : [
        {
          api_name       = api.name
          operation_id   = operation_policy.operation_id
          policy_content = operation_policy.content
          policy_format  = operation_policy.format
        }
      ]
    ]
  ])
  service_policy_is_url = replace(var.policy.format, "link", "") != var.policy.format
}

resource "azurerm_api_management" "apim_service" {
  name                = var.apim_service_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "${var.sku_tier}_${var.sku_capacity}"
  tags                = var.tags
  policy {
    xml_content = local.service_policy_is_url == false ? var.policy.content : null
    xml_link    = local.service_policy_is_url == true ? var.policy.content : null
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_property" "named_value" {
  count               = length(var.named_values)
  name                = var.named_values[count.index].name
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  display_name        = var.named_values[count.index].display_name
  value               = var.named_values[count.index].value
  secret              = var.named_values[count.index].secret
  tags                = var.named_values[count.index].tags
}

resource "azurerm_api_management_group" "group" {
  count               = length(var.groups)
  name                = var.groups[count.index].name
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  display_name        = var.groups[count.index].display_name
  description         = var.groups[count.index].description
  external_id         = var.groups[count.index].external_id
  type                = var.groups[count.index].type
  depends_on          = [azurerm_api_management_property.named_value]
}

resource "azurerm_api_management_api_version_set" "api_version_set" {
  count               = length(var.api_version_sets)
  name                = var.api_version_sets[count.index].name
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  display_name        = var.api_version_sets[count.index].display_name
  versioning_scheme   = var.api_version_sets[count.index].versioning_scheme
  description         = var.api_version_sets[count.index].description
  version_header_name = var.api_version_sets[count.index].version_header_name
  version_query_name  = var.api_version_sets[count.index].version_query_name
  depends_on          = [azurerm_api_management_property.named_value]
}

resource "azurerm_api_management_api" "api" {
  count               = length(var.apis)
  name                = var.apis[count.index].name
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  revision            = var.apis[count.index].revision
  display_name        = var.apis[count.index].display_name
  path                = var.apis[count.index].path
  protocols           = var.apis[count.index].protocols
  description         = var.apis[count.index].description
  version             = var.apis[count.index].version
  version_set_id      = var.apis[count.index].existing_version_set_id == null ? (var.apis[count.index].provisioned_version_set_index == null ? null : element(azurerm_api_management_api_version_set.api_version_set, var.apis[count.index].provisioned_version_set_index).id) : var.apis[count.index].existing_version_set_id
  import {
    content_format = var.apis[count.index].api_import_file.format
    content_value  = var.apis[count.index].api_import_file.content
  }
  depends_on = [azurerm_api_management_property.named_value, azurerm_api_management_api_version_set.api_version_set]
}

resource "azurerm_api_management_product" "product" {
  count                 = length(var.products)
  product_id            = var.products[count.index].product_id
  resource_group_name   = data.azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.apim_service.name
  display_name          = var.products[count.index].display_name
  subscription_required = var.products[count.index].subscription_required
  approval_required     = var.products[count.index].approval_required
  published             = var.products[count.index].published
  description           = var.products[count.index].description
  depends_on            = [azurerm_api_management_property.named_value]
}

resource "azurerm_api_management_backend" "backend" {
  count               = length(var.backends)
  name                = var.backends[count.index].name
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  protocol            = var.backends[count.index].protocol
  url                 = var.backends[count.index].url
  description         = var.backends[count.index].description
  depends_on          = [azurerm_api_management_property.named_value]
}

resource "azurerm_api_management_product_api" "product_api" {
  count               = length(local.product_api_associations)
  product_id          = local.product_api_associations[count.index].product_id
  api_name            = local.product_api_associations[count.index].api_name
  api_management_name = azurerm_api_management.apim_service.name
  resource_group_name = data.azurerm_resource_group.rg.name
  depends_on          = [azurerm_api_management_product.product, azurerm_api_management_api.api]
}


resource "azurerm_api_management_product_group" "product_group" {
  count               = length(local.product_group_associations)
  product_id          = local.product_group_associations[count.index].product_id
  group_name          = local.product_group_associations[count.index].group_name
  api_management_name = azurerm_api_management.apim_service.name
  resource_group_name = data.azurerm_resource_group.rg.name
  depends_on          = [azurerm_api_management_product.product, azurerm_api_management_group.group]
}

resource "azurerm_template_deployment" "service_tag" {
  name                = "service_tag"
  count               = length(var.available_tags)
  resource_group_name = data.azurerm_resource_group.rg.name

  parameters = {
    service_name     = var.apim_service_name
    tag_name         = var.available_tags[count.index].name
    tag_display_name = var.available_tags[count.index].display_name
  }

  deployment_mode = "Incremental"
  template_body   = file("${path.module}/arm-templates/service-tags.template.json")
  depends_on      = [azurerm_api_management.apim_service]
}

resource "azurerm_template_deployment" "api_tag" {
  name                = "api_tag"
  count               = length(local.api_tag_associations)
  resource_group_name = data.azurerm_resource_group.rg.name

  parameters = {
    service_name = var.apim_service_name
    api_name     = local.api_tag_associations[count.index].api_name
    tag_name     = local.api_tag_associations[count.index].tag_name
  }

  deployment_mode = "Incremental"
  template_body   = file("${path.module}/arm-templates/api-tags.template.json")
  depends_on      = [azurerm_api_management_api.api, azurerm_template_deployment.service_tag]
}

resource "azurerm_template_deployment" "product_tag" {
  name                = "product_tag"
  count               = length(local.product_tag_associations)
  resource_group_name = data.azurerm_resource_group.rg.name

  parameters = {
    service_name = var.apim_service_name
    product_id   = local.product_tag_associations[count.index].product_id
    tag_name     = local.product_tag_associations[count.index].tag_name
  }

  deployment_mode = "Incremental"
  template_body   = file("${path.module}/arm-templates/product-tags.template.json")
  depends_on      = [azurerm_api_management_product.product, azurerm_template_deployment.service_tag]
}

resource "azurerm_template_deployment" "api_policy" {
  name                = "api_policy"
  count               = length(local.api_policy_associations)
  resource_group_name = data.azurerm_resource_group.rg.name

  parameters = {
    service_name   = var.apim_service_name
    api_name       = local.api_policy_associations[count.index].api_name
    policy_content = local.api_policy_associations[count.index].policy_content
    policy_format  = local.api_policy_associations[count.index].policy_format
  }

  deployment_mode = "Incremental"
  template_body   = file("${path.module}/arm-templates/api-policy.template.json")
  depends_on      = [azurerm_api_management_api.api]
}

resource "azurerm_template_deployment" "product_policy" {
  name                = "product_policy"
  count               = length(local.product_policy_associations)
  resource_group_name = data.azurerm_resource_group.rg.name

  parameters = {
    service_name   = var.apim_service_name
    product_id     = local.product_policy_associations[count.index].product_id
    policy_content = local.product_policy_associations[count.index].policy_content
    policy_format  = local.product_policy_associations[count.index].policy_format
  }

  deployment_mode = "Incremental"
  template_body   = file("${path.module}/arm-templates/product-policy.template.json")
  depends_on      = [azurerm_api_management_product.product]
}

resource "azurerm_template_deployment" "operation_policy" {
  name                = "operation_policy"
  count               = length(local.api_operation_policy_associations)
  resource_group_name = data.azurerm_resource_group.rg.name

  parameters = {
    service_name   = var.apim_service_name
    api_name       = local.api_operation_policy_associations[count.index].api_name
    operation_id   = local.api_operation_policy_associations[count.index].operation_id
    policy_content = local.api_operation_policy_associations[count.index].policy_content
    policy_format  = local.api_operation_policy_associations[count.index].policy_format
  }

  deployment_mode = "Incremental"
  template_body   = file("${path.module}/arm-templates/operation-policy.template.json")
  depends_on      = [azurerm_api_management_api.api]
}
