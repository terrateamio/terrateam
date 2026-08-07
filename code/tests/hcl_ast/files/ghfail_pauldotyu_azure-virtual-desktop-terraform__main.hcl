terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.98.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_pet" "p" {
  length    = 1
  separator = ""
}

resource "random_integer" "i" {
  min = 100
  max = 999
}

locals {
  resource_name        = format("%s%s", "avd", random_pet.p.id)
  resource_name_unique = format("%s%s%s", "avd", random_pet.p.id, random_integer.i.result)
}

resource "azurerm_resource_group" "avd" {
  name     = "rg-${local.resource_name}"
  location = var.location
  tags     = var.tags
}

##############################################
# VIRTUAL NETWORKING
##############################################

resource "azurerm_virtual_network" "avd" {
  name                = "vn-${local.resource_name}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  tags                = var.tags
  address_space       = var.vnet_address_space
  dns_servers         = var.vnet_custom_dns_servers
}

resource "azurerm_subnet" "avd" {
  name                 = "sn-${local.resource_name}"
  resource_group_name  = azurerm_resource_group.avd.name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = var.snet_address_space
}

resource "azurerm_network_security_group" "avd" {
  name                = "nsg-${local.resource_name}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "avd" {
  subnet_id                 = azurerm_subnet.avd.id
  network_security_group_id = azurerm_network_security_group.avd.id
}

##########################################
# VIRTUAL NETWORK PEERING - NETOPS
##########################################

provider "azurerm" {
  features {}
  alias           = "netops"
  subscription_id = var.netops_subscription_id
}

# Get resources by type, create vnet peerings
data "azurerm_resources" "vnets" {
  provider = azurerm.netops
  type     = "Microsoft.Network/virtualNetworks"

  required_tags = {
    role = var.netops_role_tag_value
  }
}

# this will peer out to all the virtual networks tagged with a role of azops
resource "azurerm_virtual_network_peering" "out" {
  count                        = length(data.azurerm_resources.vnets.resources)
  name                         = data.azurerm_resources.vnets.resources[count.index].name
  remote_virtual_network_id    = data.azurerm_resources.vnets.resources[count.index].id
  resource_group_name          = azurerm_resource_group.avd.name
  virtual_network_name         = azurerm_virtual_network.avd.name
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# this will peer in from all the virtual networks tagged with the role of azops
# this also needs work. right now it is using variables when it should be using the data resource pulled from above;
# howver, the challenge is that the data resource does not return the resrouces' resource group which is required for peering
resource "azurerm_virtual_network_peering" "in" {
  provider                     = azurerm.netops
  count                        = length(data.azurerm_resources.vnets.resources)
  name                         = azurerm_virtual_network.avd.name
  remote_virtual_network_id    = azurerm_virtual_network.avd.id
  resource_group_name          = split("/", data.azurerm_resources.vnets.resources[count.index].id)[4]
  virtual_network_name         = data.azurerm_resources.vnets.resources[count.index].name
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

##########################################
# VIRTUAL NETWORK PEERING - DEVOPS
##########################################

provider "azurerm" {
  features {}
  alias           = "devops"
  subscription_id = var.devops_subscription_id
}

# Get resources by type, create vnet peerings
data "azurerm_resources" "devops_vnets" {
  provider = azurerm.devops
  type     = "Microsoft.Network/virtualNetworks"

  required_tags = {
    role = var.devops_role_tag_value
  }
}

# this will peer out to all the virtual networks tagged with a role of azops
resource "azurerm_virtual_network_peering" "devops_vnet_peer_out" {
  count                        = length(data.azurerm_resources.devops_vnets.resources)
  name                         = data.azurerm_resources.devops_vnets.resources[count.index].name
  remote_virtual_network_id    = data.azurerm_resources.devops_vnets.resources[count.index].id
  resource_group_name          = azurerm_resource_group.avd.name
  virtual_network_name         = azurerm_virtual_network.avd.name
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# this will peer in from all the virtual networks tagged with the role of azops
# this also needs work. right now it is using variables when it should be using the data resource pulled from above;
# howver, the challenge is that the data resource does not return the resrouces' resource group which is required for peering
resource "azurerm_virtual_network_peering" "devops_vnet_peer_in" {
  provider                     = azurerm.devops
  count                        = length(data.azurerm_resources.devops_vnets.resources)
  name                         = azurerm_virtual_network.avd.name
  remote_virtual_network_id    = azurerm_virtual_network.avd.id
  resource_group_name          = split("/", data.azurerm_resources.devops_vnets.resources[count.index].id)[4]
  virtual_network_name         = data.azurerm_resources.devops_vnets.resources[count.index].name
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

##############################################
# AZURE VIRTUAL DESKTOP
##############################################

resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                     = "hp-${local.resource_name}"
  resource_group_name      = azurerm_resource_group.avd.name
  location                 = var.desktopvirtualization_location #azurerm_resource_group.avd.location
  type                     = var.host_pool_type
  load_balancer_type       = var.host_pool_load_balancer_type
  validate_environment     = var.host_pool_validate_environment
  maximum_sessions_allowed = var.host_pool_max_sessions_allowed
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = timeadd(timestamp(), "2h")
}

# Both desktop and remote app application groups are being joined to a single host pool however, in production scenario, these should join to separate host pools

resource "azurerm_virtual_desktop_application_group" "avd" {
  name                = "ag-${local.resource_name}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = var.desktopvirtualization_location #azurerm_resource_group.avd.location
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd.id
  type                = var.desktop_app_group_type
  friendly_name       = upper(local.resource_name)
}

resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = "ws-${local.resource_name}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = var.desktopvirtualization_location #azurerm_resource_group.avd.location
  friendly_name       = upper(local.resource_name)
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd.id
}

# Build session hosts
data "azurerm_shared_image" "avd" {
  name                = var.acg_image_name
  gallery_name        = var.acg_name
  resource_group_name = var.acg_resource_group_name
}

module "sessionhosts" {
  source = "./modules/sessionhosts"

  for_each = { for sh in var.session_hosts : sh.batch => sh }

  session_host_status = each.value["status"]
  vm_count            = each.value["count"]
  vm_custom_image_id  = "${data.azurerm_shared_image.avd.id}/versions/${each.value["acg_image_version"]}"
  vm_name_prefix      = format("%s-%s", upper(substr(local.resource_name, 0, 8)), each.value["batch"])

  resource_group_name     = azurerm_resource_group.avd.name
  location                = azurerm_resource_group.avd.location
  subnet_id               = azurerm_subnet.avd.id
  tags                    = var.tags
  host_pool_name          = azurerm_virtual_desktop_host_pool.avd.name
  host_pool_token         = azurerm_virtual_desktop_host_pool_registration_info.avd.token
  vm_sku                  = var.vm_sku
  vm_username             = var.vm_username
  vm_password             = var.vm_password
  vm_os_disk_caching      = var.vm_os_disk_caching
  vm_marketplace_image    = null
  configure_using_ansible = var.configure_using_ansible
  domain_name             = var.domain_name
  domain_ou_path          = var.domain_ou_path
  domain_username         = var.domain_username
  domain_password         = var.domain_password

  depends_on = [
    azurerm_virtual_desktop_host_pool.avd,
    azurerm_virtual_network_peering.out,
    azurerm_virtual_network_peering.in
  ]
}

########################################
# APPLICATION GROUP RBAC ASSIGNMENT
########################################

data "azuread_group" "avd" {
  display_name     = var.aad_group_name
  security_enabled = true
}

resource "azurerm_role_assignment" "avd" {
  scope                = azurerm_virtual_desktop_application_group.avd.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azuread_group.avd.id
}
