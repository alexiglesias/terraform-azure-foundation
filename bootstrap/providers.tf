provider "azurerm" {
  features {}

  # The only subscription this configuration may touch. azurerm 4.x requires
  # it, and it stops Terraform using whatever subscription `az` last picked.
  subscription_id = var.subscription_id

  # Talk to storage with your Entra ID login, never with storage account
  # keys - the account below has keys switched off.
  storage_use_azuread = true
}

# Entra ID (formerly Azure AD): used by ci.tf to create the identity GitLab CI
# signs in as. Uses the same `az login` and tenant as azurerm.
provider "azuread" {}
