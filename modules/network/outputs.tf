output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name (web, app)."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "nsg_names" {
  description = "NSG names keyed by tier (web, app)."
  value = {
    web = azurerm_network_security_group.web.name
    app = azurerm_network_security_group.app.name
  }
}
