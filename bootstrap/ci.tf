# ---------------------------------------------------------------------------
# The identity GitLab CI signs in to Azure as - with NO password or secret.
#
# OIDC "workload identity federation": every GitLab job gets a short-lived,
# signed token describing who it is (project, branch). Azure is told to trust
# tokens from gitlab.com, but only this exact project's main branch. A job on
# any other branch - or any other project - gets nothing.
#
# This lives in bootstrap/ on purpose: CI must never manage its own
# permissions.
# ---------------------------------------------------------------------------

locals {
  ci_subject = "project_path:${var.gitlab_project_path}:ref_type:branch:ref:main"
  dev_rg_id  = "/subscriptions/${var.subscription_id}/resourceGroups/${var.dev_resource_group_name}"

  # Built-in role IDs the CI identity is allowed to hand out (see ci_rbac).
  key_vault_secrets_user_role    = "4633458b-17de-408a-b874-0445c86b69e6"
  key_vault_secrets_officer_role = "b86a8fe4-44ce-4948-aee5-eccb2c155cd7"
}

resource "azuread_application" "gitlab_ci" {
  display_name = "gitlab-ci-${var.project_name}"
}

resource "azuread_service_principal" "gitlab_ci" {
  client_id = azuread_application.gitlab_ci.client_id
}

resource "azuread_application_federated_identity_credential" "gitlab_main" {
  application_id = azuread_application.gitlab_ci.id
  display_name   = "gitlab-main-branch"
  description    = "GitLab CI jobs on the main branch of ${var.gitlab_project_path}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://gitlab.com"
  subject        = local.ci_subject
}

# ---------------------------------------------------------------------------
# What CI may do - least privilege
# ---------------------------------------------------------------------------

# Read and write the Terraform state (data plane - account keys are off).
resource "azurerm_role_assignment" "ci_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.gitlab_ci.object_id
  principal_type       = "ServicePrincipal"
}

# Read-only view of the subscription, e.g. to look up the built-in policy.
resource "azurerm_role_assignment" "ci_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.gitlab_ci.object_id
  principal_type       = "ServicePrincipal"
}

# Create, change and delete resources - in the dev resource group only.
resource "azurerm_role_assignment" "ci_contributor" {
  scope                = local.dev_rg_id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.gitlab_ci.object_id
  principal_type       = "ServicePrincipal"
}

# Manage the allowed-locations policy assignment - dev resource group only.
resource "azurerm_role_assignment" "ci_policy" {
  scope                = local.dev_rg_id
  role_definition_name = "Resource Policy Contributor"
  principal_id         = azuread_service_principal.gitlab_ci.object_id
  principal_type       = "ServicePrincipal"
}

# Create role assignments (the VM's access to its secret, the secret officers)
# - but ONLY for the two Key Vault secret roles. The condition stops CI from
# ever granting itself, or anyone else, Owner or Contributor.
resource "azurerm_role_assignment" "ci_rbac" {
  scope                = local.dev_rg_id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.gitlab_ci.object_id
  principal_type       = "ServicePrincipal"

  condition_version = "2.0"
  condition         = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.key_vault_secrets_user_role}, ${local.key_vault_secrets_officer_role}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.key_vault_secrets_user_role}, ${local.key_vault_secrets_officer_role}}
     )
    )
  EOT
}
