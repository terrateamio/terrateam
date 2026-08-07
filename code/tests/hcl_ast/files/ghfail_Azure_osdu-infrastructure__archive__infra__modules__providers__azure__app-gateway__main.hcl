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
data "azurerm_client_config" "current" {}

locals {
  authentication_certificate_name = "gateway-public-key"
  backend_probe_http              = "http_probe"
  backend_probe_https             = "https_probe"
  ssl_certificate_name            = "gateway-certificate"
}

# Public Ip
resource "azurerm_public_ip" "appgw_pip" {
  name                = var.appgateway_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_user_assigned_identity" "app_gw_user_identity" {
  resource_group_name = var.user_identity_rg
  location            = var.location
  name                = var.user_identity_name
}

module "app_gw_keyvault_access_policy" {
  source    = "../../../../modules/providers/azure/keyvault-policy"
  vault_id  = var.keyvault_id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_ids = [
    azurerm_user_assigned_identity.app_gw_user_identity.principal_id
  ]
  key_permissions         = []
  secret_permissions      = ["get"]
  certificate_permissions = ["get"]
}

resource "azurerm_application_gateway" "appgateway" {
  name                = var.appgateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.resource_tags

  sku {
    name = var.appgateway_sku_name
    tier = var.appgateway_tier
  }

  autoscale_configuration {
    min_capacity = 2
  }

  gateway_ip_configuration {
    name      = var.appgateway_ipconfig_name
    subnet_id = var.virtual_network_subnet_id
  }

  frontend_port {
    name = var.appgateway_frontend_port_name
    port = var.frontend_http_port
  }

  frontend_port {
    name = var.appgateway_frontend_https_port_name
    port = var.frontend_https_port
  }

  frontend_ip_configuration {
    name                 = var.appgateway_frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = var.appgateway_backend_address_pool_name
  }

  backend_http_settings {
    name                  = var.appgateway_backend_http_setting_name
    cookie_based_affinity = var.backend_http_cookie_based_affinity
    port                  = var.backend_http_port
    protocol              = var.backend_http_protocol
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = var.appgateway_backend_https_setting_name
    cookie_based_affinity = var.backend_http_cookie_based_affinity
    port                  = var.frontend_https_port
    protocol              = "Https"
    request_timeout       = 1
  }

  http_listener {
    name                           = "https-${var.appgateway_listener_name}"
    frontend_ip_configuration_name = var.appgateway_frontend_ip_configuration_name
    frontend_port_name             = var.appgateway_frontend_https_port_name
    protocol                       = "Https"
    ssl_certificate_name           = var.appgateway_ssl_certificate_name
  }

  http_listener {
    name                           = "http-${var.appgateway_listener_name}"
    frontend_ip_configuration_name = var.appgateway_frontend_ip_configuration_name
    frontend_port_name             = var.appgateway_frontend_port_name
    protocol                       = "Http"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = var.appgateway_waf_config_firewall_mode
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"
  }

  request_routing_rule {
    name                       = var.appgateway_request_routing_rule_name
    http_listener_name         = "http-${var.appgateway_listener_name}"
    rule_type                  = var.request_routing_rule_type
    backend_address_pool_name  = var.appgateway_backend_address_pool_name
    backend_http_settings_name = var.appgateway_backend_http_setting_name
  }

  ssl_certificate {
    name                = var.appgateway_ssl_certificate_name
    key_vault_secret_id = var.ssl_key_vault_secret_id
  }

  identity {
    identity_ids = [azurerm_user_assigned_identity.app_gw_user_identity.id]
  }

  depends_on = [module.app_gw_keyvault_access_policy]

  lifecycle {
    ignore_changes = [
      ssl_certificate,
      request_routing_rule,
      http_listener,
      backend_http_settings,
      backend_address_pool,
      probe,
      tags,
      frontend_port,
      redirect_configuration,
      url_path_map
    ]
  }
}
