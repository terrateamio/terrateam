data "azurerm_resource_group" "tmrg" {
  name = var.resource_group_name
}

resource "azurerm_traffic_manager_profile" "profile" {
  name                   = var.traffic_manager_profile_name
  resource_group_name    = data.azurerm_resource_group.tmrg.name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = var.traffic_manager_dns_name
    ttl           = 30
  }

  monitor_config {
    protocol = var.traffic_manager_monitor_protocol
    port     = var.traffic_manager_monitor_port
    path     = "/"
  }

  tags = var.tags
}

resource "azurerm_public_ip" "pip" {
  name                = var.public_ip_name
  location            = data.azurerm_resource_group.tmrg.location
  resource_group_name = data.azurerm_resource_group.tmrg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.public_ip_name}-dns"
  tags                = var.tags
}

resource "azurerm_traffic_manager_endpoint" "endpoint" {
  name                = "${var.endpoint_name}-ep"
  resource_group_name = data.azurerm_resource_group.tmrg.name
  profile_name        = var.traffic_manager_profile_name
  target              = "${var.endpoint_name}-dns"
  target_resource_id  = azurerm_public_ip.pip.id
  type                = "azureEndpoints"
  weight              = 1

  depends_on = [azurerm_traffic_manager_profile.profile]
}