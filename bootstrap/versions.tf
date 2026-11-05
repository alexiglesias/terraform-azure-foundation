terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # No backend block: the bootstrap creates the storage account that holds
  # the state, so it can't keep its own state there before it exists. Its
  # state stays local (bootstrap/terraform.tfstate, gitignored). Losing it is
  # not a disaster: the resources can be re-imported with `terraform import`.
}
