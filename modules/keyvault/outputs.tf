output "key_vault_id" {
  description = "ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault, e.g. https://kv-....vault.azure.net/."
  value       = azurerm_key_vault.this.vault_uri
}

output "secret_name" {
  description = "Name of the demo secret."
  value       = azurerm_key_vault_secret.this.name
}

output "secret_resource_id" {
  description = "Azure resource ID of the secret (no version) - used to give the VM access to this one secret only."
  value       = azurerm_key_vault_secret.this.resource_versionless_id
}
