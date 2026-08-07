# ======================================
# = Définition des composants Azure    =
# = Azure components definition        =
# ======================================
# - Ressource Group 
# - Storage Account
#
# Pour personnaliser recherchez et remplacez Stan par votre chaine !
# To Custom : find and replace Stan with your own string !
#

# Définition du ressource group
# Resource Group Definition
resource "azurerm_resource_group" "Terra-RG-Stan" {
  name     = "RG-Packer1-Stan"
  location = "West Europe"
}

# Compte de stockage
# update version with new required arguments
# Storage Account
resource "azurerm_storage_account" "Terra-StorageAccount1-Stan" {
  name                = "storageaccountpackerstan"
  resource_group_name = "${azurerm_resource_group.Terra-RG-Stan.name}"
  location            = "${azurerm_resource_group.Terra-RG-Stan.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container dans le compte de stockage
resource "azurerm_storage_container" "Terra-StorageContainer1-Stan" {
   name = "images"
   resource_group_name = "${azurerm_resource_group.Terra-RG-Stan.name}"
   storage_account_name = "${azurerm_storage_account.Terra-StorageAccount1-Stan.name}"
   container_access_type = "private"
}

