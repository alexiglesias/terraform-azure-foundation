# Guardrail: Azure itself refuses to create anything in this resource group
# outside var.location. Uses Microsoft's built-in "Allowed locations"
# policy, looked up by name instead of pasting its ID.
#
# Scoped to the resource group on purpose: at subscription level it could
# block unrelated work in the same account.

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Allowed locations: ${var.location} only"
  description          = "Only ${var.location} is allowed in ${azurerm_resource_group.main.name}."
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = { value = [var.location] }
  })
}
