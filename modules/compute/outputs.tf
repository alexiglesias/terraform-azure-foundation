output "vm_name" {
  description = "Name of the VM."
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_id" {
  description = "ID of the VM."
  value       = azurerm_linux_virtual_machine.this.id
}

output "principal_id" {
  description = "Object ID of the VM's managed identity."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "private_ip" {
  description = "The VM's private IP inside the web subnet."
  value       = azurerm_network_interface.this.private_ip_address
}
