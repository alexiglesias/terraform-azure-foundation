provider "azurerm" {
  features {
    key_vault {
      # On destroy, also purge the soft-deleted vault, so nothing is left
      # behind and the name is free again.
      purge_soft_delete_on_destroy = true
    }
  }

  # The only subscription this configuration may touch - stops Terraform
  # using whatever subscription `az` last picked.
  subscription_id = var.subscription_id

  # Use your Entra ID login for storage, never storage account keys.
  storage_use_azuread = true

  # Don't try to register Azure resource providers on every run: they are
  # already registered, and the CI identity deliberately has no
  # subscription-wide write permission to do it.
  resource_provider_registrations = "none"
}
