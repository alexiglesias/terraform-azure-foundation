terraform {
  required_version = ">= 1.11.0, < 2.0.0" # write-only arguments need 1.11+

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7" # ephemeral random_password needs 3.7+
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
