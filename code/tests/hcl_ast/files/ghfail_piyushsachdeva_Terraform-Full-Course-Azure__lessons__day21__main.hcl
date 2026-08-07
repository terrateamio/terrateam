data "azurerm_subscription" "current" {}

resource "azurerm_policy_definition" "tag" {
  name         = "allowed-tag"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed tags policy"

  policy_rule = jsonencode({
    if = {
      anyOf = [
      {
        field = "tags[${var.allowed_tags[0]}]",
        exists = false
      },
      {
        field = "tags[${var.allowed_tags[1]}]",
        exists = false
      }
             ]
             }        
    then = {
      effect = "deny"
  }
  
})



}

resource "azurerm_subscription_policy_assignment" "example" {
  name                 = "tag-assignment"
  policy_definition_id = azurerm_policy_definition.tag.id
  subscription_id      = data.azurerm_subscription.current.id
}


resource "azurerm_policy_definition" "vm_size" {
  name         = "vm-size"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed vm policy"

  policy_rule = jsonencode({
    if = {
        field = "Microsoft.Compute/virtualMachines/sku.name",
        notIn = ["${var.vm_sizes[0]}","${var.vm_sizes[1]}"]
      },       
    then = {
      effect = "deny"
  }
  
})



}

resource "azurerm_subscription_policy_assignment" "example1" {
  name                 = "size-assignment"
  policy_definition_id = azurerm_policy_definition.vm_size.id
  subscription_id      = data.azurerm_subscription.current.id
}


resource "azurerm_policy_definition" "location" {
  name         = "location"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed location policy"

  policy_rule = jsonencode({
    if = {
        field = "location",
        notIn = ["${var.location[0]}","${var.location[1]}"]
      },       
    then = {
      effect = "deny"
  }
  
})



}

resource "azurerm_subscription_policy_assignment" "example2" {
  name                 = "location-assignment"
  policy_definition_id = azurerm_policy_definition.location.id
  subscription_id   = data.azurerm_subscription.current.id
}