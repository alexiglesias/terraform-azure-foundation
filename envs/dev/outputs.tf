output "resource_group_name" {
  description = "Resource group holding everything in this environment."
  value       = azurerm_resource_group.main.name
}
