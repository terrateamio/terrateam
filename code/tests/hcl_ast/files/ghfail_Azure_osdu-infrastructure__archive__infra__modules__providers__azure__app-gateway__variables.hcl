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

variable "resource_group_name" {
  description = "Resource group name that the app gateway will be created in."
  type        = string
}

variable "virtual_network_subnet_id" {
  description = "Subnet id that the app gateway will be created in."
  type        = string
}

variable "appgateway_name" {
  description = "The name of the application gateway"
  type        = string
}

variable "location" {
  description = "Location of the application gateway"
  type        = string
}

variable "ssl_key_vault_secret_id" {
  description = "Secret Id of (base-64 encoded unencrypted pfx) Secret or Certificate object stored in Azure KeyVault. You need to enable soft delete for keyvault."
  type        = string
}

variable "keyvault_id" {
  description = "Key Vault resource ID holding the ssl certificate used for enabling tls termination."
  type        = string
}

variable "user_identity_name" {
  description = "The managed user identity name for the Appication Gateway to be created"
  type        = string
}

variable "user_identity_rg" {
  description = "The managed user identity resource group"
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module.  By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "appgateway_frontend_port_name" {
  description = "The Frontend Port Name for the Appication Gateway to be created"
  type        = string
  default     = "http-frontend-port"
}

variable "appgateway_frontend_https_port_name" {
  description = "The Frontend Port Name for the Appication Gateway to be created"
  type        = string
  default     = "https-frontend-port"
}

variable "appgateway_public_ip_name" {
  description = "The Public IP Name for the Appication Gateway to be created"
  type        = string
  default     = "publicIp1"
}

variable "appgateway_sku_name" {
  description = "The SKU for the Appication Gateway to be created"
  type        = string
  default     = "WAF_v2"
}

variable "appgateway_tier" {
  description = "The tier of the application gateway. Small/Medium/Large. More details can be found at https://azure.microsoft.com/en-us/pricing/details/application-gateway/"
  type        = string
  default     = "WAF_v2"
}

variable "appgateway_capacity" {
  description = "The capacity of application gateway to be created"
  type        = number
  default     = 2
}

variable "appgateway_ipconfig_name" {
  description = "The IP Config Name for the Appication Gateway to be created"
  type        = string
  default     = "subnet"
}

variable "frontend_http_port" {
  description = "The frontend port for the Appication Gateway to be created"
  type        = number
  default     = 80
}

variable "frontend_https_port" {
  description = "The frontend port for the Appication Gateway to be created"
  type        = number
  default     = 443
}

variable "appgateway_frontend_ip_configuration_name" {
  description = "The Frontend IP configuration name for the Appication Gateway to be created"
  type        = string
  default     = "frontend"
}

variable "appgateway_backend_address_pool_name" {
  description = "The Backend Addres Pool Name for the Appication Gateway to be created"
  type        = string
  default     = "backend_pool"
}

variable "appgateway_backend_http_setting_name" {
  description = "The Backend Http Settings Name for the Appication Gateway to be created"
  type        = string
  default     = "http_backend_settings"
}

variable "appgateway_backend_https_setting_name" {
  description = "The Backend Http Settings Name for the Appication Gateway to be created"
  type        = string
  default     = "https_backend_settings"
}

variable "appgateway_ssl_certificate_name" {
  description = "The Name of the SSL certificate that is unique within this Application Gateway"
  type        = string
  default     = "ssl_cert"
}

variable "backend_http_cookie_based_affinity" {
  description = "The Backend Http cookie based affinity for the Appication Gateway to be created"
  type        = string
  default     = "Disabled"
}

variable "backend_http_port" {
  description = "The backend port for the Appication Gateway to be created"
  type        = number
  default     = 80
}

variable "backend_http_protocol" {
  description = "The backend protocol for the Appication Gateway to be created"
  type        = string
  default     = "Http"
}

variable "http_listener_protocol" {
  description = "The Http Listener protocol for the Appication Gateway to be created"
  type        = string
  default     = "Http"
}

variable "appgateway_listener_name" {
  description = "The Listener Name for the Appication Gateway to be created"
  type        = string
  default     = "proxy_listener"
}

variable "appgateway_request_routing_rule_name" {
  description = "The rule name to request routing for the Appication Gateway to be created"
  type        = string
  default     = "request_proxy_routing_rule"
}

variable "request_routing_rule_type" {
  description = "The rule type to request routing for the Appication Gateway to be created"
  type        = string
  default     = "Basic"
}

variable "appgateway_waf_config_firewall_mode" {
  description = "The firewall mode on the waf gateway"
  type        = string
  default     = "Prevention"
}

variable "backendpool_fqdns" {
  description = "A list of FQDN's which should be part of the Backend Address Pool."
  type        = list(string)
  default     = []
}

