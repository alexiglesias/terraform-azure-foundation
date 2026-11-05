output "state_storage_account" {
  description = "Storage account holding the envs/dev state."
  value       = azurerm_storage_account.state.name
}

output "backend_config_file" {
  description = "Generated backend settings for envs/dev."
  value       = local_file.dev_backend_config.filename
}

output "next_step" {
  description = "What to run next."
  value       = "terraform -chdir=envs/dev init -backend-config=backend.hcl"
}
