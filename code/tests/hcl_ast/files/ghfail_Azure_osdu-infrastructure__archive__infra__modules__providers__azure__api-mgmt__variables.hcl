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

# Required

variable "resource_group_name" {
  description = "The name of the resource group where the API Management service will be deployed to."
  type        = string
}

variable "apim_service_name" {
  description = "The name of the apim service"
  type        = string
}

# Optional- If a value is provided, each property on the following input variables is required

variable "sku_tier" {
  description = "Apim service sku tier"
  type        = string
  default     = "Developer"
}

variable "sku_capacity" {
  description = "The number of deployed units of the sku, which must be a positive integer"
  type        = number
  default     = 1
}

variable "publisher_name" {
  description = "The name of publisher/company"
  type        = string
}

variable "publisher_email" {
  description = "The email of publisher/company"
  type        = string
}

variable "policy" {
  description = "Service policy xml content and format. Content can be inlined xml or a url"
  type = object({
    content = string
    format  = string
  })
  default = {
    content = <<XML
<policies>
    <inbound />
    <backend />
    <outbound />
    <on-error />
</policies>
XML
    format  = "xml"
  }
}

variable "tags" {
  description = "A mapping of tags assigned to the resource."
  type        = map(string)
  default     = {}
}

variable "available_tags" {
  description = "A list of strings that will be available as tags for apis, products, and named values"
  type = list(object({
    name         = string
    display_name = string
  }))
  default = []
}

variable "groups" {
  description = "A list of groups to attach to the API Management instance."
  type = list(object({
    name         = string
    display_name = string
    description  = string
    external_id  = string
    type         = string
  }))
  default = []
}

variable "api_version_sets" {
  description = "A list of API version sets to attach to the API Management instance."
  type = list(object({
    name                = string
    display_name        = string
    versioning_scheme   = string
    description         = string
    version_header_name = string
    version_query_name  = string
  }))
  default = []
}

variable "apis" {
  description = "A list of APIs to attach to the API Management instance."
  type = list(object({
    name         = string
    display_name = string
    revision     = string
    path         = string
    protocols    = list(string)
    description  = string
    api_import_file = object({
      content = string
      format  = string
    })
    version                       = string
    existing_version_set_id       = string
    provisioned_version_set_index = number
    tags                          = list(string)
    policy = object({
      content = string
      format  = string
    })
    operation_policies = list(object({
      operation_id = string
      content      = string
      format       = string
    }))
  }))
  default = []
}

variable "products" {
  description = "A list of products to attach to the API Management instance."
  type = list(object({
    product_id            = string
    display_name          = string
    subscription_required = bool
    approval_required     = bool
    published             = bool
    description           = string
    apis                  = list(string)
    groups                = list(string)
    tags                  = list(string)
    policy = object({
      content = string
      format  = string
    })
  }))
  default = []
}

variable "named_values" {
  description = "A list of named values to attach to the API Management instance."
  type = list(object({
    name         = string
    display_name = string
    value        = string
    secret       = bool
    tags         = list(string)
  }))
  default = []
}

variable "backends" {
  description = "A list of backends to attach to the API Management instance."
  type = list(object({
    name        = string
    protocol    = string
    url         = string
    description = string
  }))
  default = []
}
