resource "azurerm_resource_group" "rg_01" {
  location = "eastus"
  name     = "resource-group-01"
}

resource "azurerm_resource_group" "rg_02" {
  location = "eastus"
  name     = "resource-group-02"
}

resource "azurerm_virtual_network" "vnet_01" {
  name                = "vnet-01"
  address_space       = ["10.0.0.0/16"]
  location            = (azurerm_resource_group
                          .rg_01.location)
  resource_group_name = (azurerm_resource_group
                          .rg_01.name)
}

resource "azurerm_subnet" "subnet_01" {
  name                 = "subnet-01"
  resource_group_name  = (azurerm_resource_group
                          .rg_01.name)
  virtual_network_name = (azurerm_virtual_network
                          .vnet_01.name)
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_application_security_group" "asg_01" {
  name                = "asg-01"
  location            = (azurerm_resource_group
                          .rg_01.location)
  resource_group_name = (azurerm_resource_group
                          .rg_01.name)
}

resource "azurerm_network_security_group" "nsg_01" {
  name                = "nsg-01"
  location            = (azurerm_resource_group
                          .rg_01.location)
  resource_group_name = (azurerm_resource_group
                          .rg_01.name)
}

resource "azurerm_virtual_network" "vnet_02" {
  name                = "vnet-02"
  address_space       = ["192.168.0.0/16"]
  location            = (azurerm_resource_group
                          .rg_02.location)
  resource_group_name = (azurerm_resource_group
                          .rg_02.name)
}

resource "azurerm_subnet" "subnet_02" {
  name                 = "subnet-02"
  resource_group_name  = (azurerm_resource_group
                          .rg_02.name)
  virtual_network_name = (azurerm_virtual_network
                          .vnet_02.name)
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_application_security_group" "asg_02" {
  name                = "asg-02"
  location            = (azurerm_resource_group
                          .rg_02.location)
  resource_group_name = (azurerm_resource_group
                          .rg_02.name)
}

resource "azurerm_network_security_group" "nsg_02" {
  name                = "nsg-02"
  location            = (azurerm_resource_group
                          .rg_02.location)
  resource_group_name = (azurerm_resource_group
                          .rg_02.name)
}

resource "azurerm_virtual_network_peering" "peer_1_to_2" {
  name                      = "peer1to2"
  resource_group_name       = (azurerm_resource_group
                                .rg_01.name)
  virtual_network_name      = (azurerm_virtual_network
                                .vnet_01.name)
  remote_virtual_network_id = (azurerm_virtual_network
                                .vnet_02.id)
}

resource "azurerm_virtual_network_peering" "peer_2_to_1" {
  name                      = "peer2to1"
  resource_group_name       = (azurerm_resource_group
                                .rg_02.name)
  virtual_network_name      = (azurerm_virtual_network
                                .vnet_02.name)
  remote_virtual_network_id = (azurerm_virtual_network
                                .vnet_01.id)
}

resource "azurerm_network_security_rule" "desktop-access" {
  name                        = "Desktop-Access"
  priority                    = 900
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "8081"
  source_address_prefix       = "${var.my_ip}/32"
  destination_address_prefix  = (
    azurerm_subnet.subnet_02.address_prefix
  )
  resource_group_name         = (
    azurerm_resource_group.rg_02.name
  )
  network_security_group_name = (
    azurerm_network_security_group.nsg_02.name
  )
}

resource "azurerm_network_security_rule" "ssh-access" {
  name                        = "SSH-Access"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${var.my_ip}/32"
  destination_address_prefix  = (
    azurerm_subnet.subnet_02.address_prefix
  )
  resource_group_name         = (
    azurerm_resource_group.rg_02.name
  )
  network_security_group_name = (
    azurerm_network_security_group.nsg_02.name
  )
}

resource "azurerm_network_security_rule" "rdp-access" {
  name                        = "RDP-Access"
  priority                    = 800
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "${var.my_ip}/32"
  destination_address_prefix  = (
    azurerm_subnet.subnet_01.address_prefix
  )
  resource_group_name         = (
    azurerm_resource_group.rg_01.name
  )
  network_security_group_name = (
    azurerm_network_security_group.nsg_01.name
  )
}