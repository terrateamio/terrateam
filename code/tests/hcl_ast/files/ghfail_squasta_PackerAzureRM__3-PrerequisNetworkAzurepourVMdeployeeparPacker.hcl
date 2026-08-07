# définition des pre-requis à déploiement VM depuis template généré par Packer 
# Definition of prerequisite mandatory for Packer to deploy a VM 
# - VNet Azure / Azure VNet
# - Network Security Group (appliqué au Subnet / apply to Subnet)
# - SubNet
# - Une IP publique / a Public IP
# - Une carte réseau associée au SubNet et à l'IP publique / a NIC associated to Subnet and Public IP
#
# More infos
# https://github.com/Azure/packer-azure/issues/201 
#
#
# Pour personnaliser recherchez et remplacez Stan par votre chaine !
# To Custom : find and replace Stan with your own string !
#

# Variable pour définir la région Azure où déployer la plateforme
# Variable to define Azure Location where to deploy
# Pour obtenir la liste des valeurs possible via la ligne de commande Azure, executer la commande suivante :
# To list available Azure Location using CLI : 
# az account list-locations
variable "AzureRegion" {
    description = "choix de la region Azure"
    type = "string"
    default = "West Europe"
}

# Définition du ressource group
# Resource Group Definition
resource "azurerm_resource_group" "Terra-RG-PackerStan1" {
  name     = "RG-DeploiementPacker1"
  location = "${var.AzureRegion}"
}


# Définition d un VNet
# plus d info : https://www.terraform.io/docs/providers/azurerm/r/virtual_network.html
resource "azurerm_virtual_network" "Terra-VNet-PackerStan1" {
  name                = "VNet-PackerStan1"
  resource_group_name = "${azurerm_resource_group.Terra-RG-PackerStan1.name}"
  address_space       = ["10.0.0.0/8"]
  location            = "${var.AzureRegion}"
  dns_servers         = ["8.8.8.8", "10.0.0.5"]
}


# Définition des Network Security Group : you pouvez ici personnalisé en fonction du type de VM
# Network Security Group Definition : you can customize here depending on your type of VM
# More info : https://www.terraform.io/docs/providers/azurerm/r/network_security_group.html
resource "azurerm_network_security_group" "Terra-NSG-PackerStan1" {
  name                = "NSG-PackerStan1"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.Terra-RG-PackerStan1.name}"
  # regle  autorisant SSH
  security_rule {
    name                       = "OK-SSH-entrant"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # regle  autorisant HTTP 
  security_rule {
    name                       = "OK-HTTP-entrant"
    priority                   = 1300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # regle  autorisant RDP (TCP 3389) 
  security_rule {
    name                       = "OK-RDP-entrant"
    priority                   = 1400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Définition du subnet Subnet-PackerStan1
# SubNet Definition
# More info : https://www.terraform.io/docs/providers/azurerm/r/subnet.html 
resource "azurerm_subnet" "Terra-Subnet-PackerStan1" {
  name                      = "Subnet-PackerStan1"
  resource_group_name       = "${azurerm_resource_group.Terra-RG-PackerStan1.name}"
  virtual_network_name      = "${azurerm_virtual_network.Terra-VNet-PackerStan1.name}"
  address_prefix            = "10.0.0.0/16"
  network_security_group_id = "${azurerm_network_security_group.Terra-NSG-PackerStan1.id}"
}

# Définition IP publique pour le Load Balancer permettant d accéder à la PackerStan1
# Definition of Public IP 
# more info : https://www.terraform.io/docs/providers/azurerm/r/public_ip.html
resource "azurerm_public_ip" "Terra-PublicIp-PackerStan1" {
  name                         = "PublicIp-PackerStan1"
  location                     = "${var.AzureRegion}"
  resource_group_name          = "${azurerm_resource_group.Terra-RG-PackerStan1.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "publicpackerstan1"
}

# Définition d une carte reseau pour la VM PackerStan1
# Network Card Interface definition for PackerStan1 VM
# More info : https://www.terraform.io/docs/providers/azurerm/r/network_interface.html
resource "azurerm_network_interface" "Terra-NIC1-PackerStan1" {
  name                = "NIC1-PackerStan1"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.Terra-RG-PackerStan1.name}"

  ip_configuration {
    name                          = "configIPNIC1-PackerStan1"
    subnet_id                     = "${azurerm_subnet.Terra-Subnet-PackerStan1.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.Terra-PublicIp-PackerStan1.id}"
    }
}

# --------------------
# - Output
# --------------------

output "IP Publique de la VM" {
  value = "${azurerm_public_ip.Terra-PublicIp-PackerStan1.ip_address}"
}

output "FQDN de la VM" {
  value = "${azurerm_public_ip.Terra-PublicIp-PackerStan1.fqdn}"
}

output "NICid de la VM" {
  value = "${azurerm_network_interface.Terra-NIC1-PackerStan1.id}"
}