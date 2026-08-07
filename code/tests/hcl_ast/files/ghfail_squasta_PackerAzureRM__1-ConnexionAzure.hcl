# Ce fichier .tf donne à Terraform les informations 
# du Service Principal pour faire des opérations
# sur l'abonnement Azure. Compléter ce fichier avec les 
# infos du SPN

# This .tf file gives all Service Principal Name info
# to allows Terraform to make operation on an Azure Subscription
# Complete this file with SPN info

provider "azurerm" {
  subscription_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  client_id       = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  client_secret   = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="
  tenant_id       = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
}