provider "azurerm" {
  features {}

  # The only subscription this configuration may touch - stops Terraform
  # using whatever subscription `az` last picked.
  subscription_id = var.subscription_id

  # Use your Entra ID login for storage, never storage account keys.
  storage_use_azuread = true
}
