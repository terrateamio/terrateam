# Add all local concatenation and values here
locals {

  # Creating a local value to support using existing resource group or creating a new one.
  resource_group_name = var.existing_resource_group_name != "" ? var.existing_resource_group_name : var.sub_resource_group_name

  # Creating local value to handle empty tuple of azurerm_route_table when var.route_table_id is supplied.
  created_route_table_id = var.create_route_table == true && var.route_table_name != "" ? try(azurerm_route_table.route_table[0].id) : ""

  # Creating local value to handle empty tuple of azurerm_network_security_group when var.network_security_group_id is supplied.
  created_network_security_group_id = var.create_network_security_group == true && var.network_security_group_name != "" ? try(azurerm_network_security_group.nsg[0].id) : ""

  # Creating privateEndpointNetworkPolicies value based on true or false.
  private_link_and_endpoint_network_policies_enabled_map = {
    true  = "Enabled"
    false = "Disabled"
  }

  # Creating the delegation block to be used in the subnet resource if var.delegation is supplied with valid service_name.
  delegations = [
    {
      name = "delegation"
      properties = {
        serviceName = var.delegation_service_name
      }
    }
  ]

  # Creating the service_endpoint block to be used in the subnet resource if var.service_endpoint_name is supplied with valid service_name.
  serviceEndpoints = [
    for serviceEndpoint in var.service_endpoint_names :
    {
      service = serviceEndpoint
    }
  ]

}
