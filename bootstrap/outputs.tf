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

output "ci_client_id" {
  description = "Client ID of the GitLab CI identity -> GitLab CI/CD variable ARM_CLIENT_ID."
  value       = azuread_application.gitlab_ci.client_id
}

output "ci_tenant_id" {
  description = "Entra ID tenant -> GitLab CI/CD variable ARM_TENANT_ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "ci_principal_object_id" {
  description = "Object ID of the CI service principal -> add it to secret_officer_principal_ids in envs/dev."
  value       = azuread_service_principal.gitlab_ci.object_id
}

output "ci_federated_subject" {
  description = "The only GitLab token Azure accepts for this identity."
  value       = azuread_application_federated_identity_credential.gitlab_main.subject
}
