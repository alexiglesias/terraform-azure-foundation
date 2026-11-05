# Unit tests for the keyvault module, with mock providers (no Azure, no cost).
#   terraform -chdir=modules/keyvault init -backend=false
#   terraform -chdir=modules/keyvault test

mock_provider "azurerm" {
  # Key Vault validates tenant_id as a GUID, so the mock must return one.
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000000"
      object_id = "11111111-1111-1111-1111-111111111111"
    }
  }

  # On a (fake) apply, the mock invents random strings for IDs. The role
  # assignment and the secret check that the vault ID looks like a real Azure
  # ID, so give the fake vault a realistic one.
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
    }
  }
}
mock_provider "time" {}

# The random provider is NOT mocked: mock providers can't fake ephemeral
# resources yet, and random runs entirely on your machine anyway (no cloud,
# no cost). It also means the vault name is known, so its length can be tested.

variables {
  short_name                   = "test-dev"
  location                     = "swedencentral"
  resource_group_name          = "rg-test"
  allowed_ip_addresses         = ["203.0.113.10/32"]
  allowed_subnet_ids           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-web"]
  secret_officer_principal_ids = ["22222222-2222-2222-2222-222222222222"]
  secret_expiration_date       = "2027-12-31T00:00:00Z"
}

run "secure_defaults" {
  # apply, not plan: the random suffix only gets its value at apply time.
  # Azure is still fake here - only the local random provider is real.
  command = apply

  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled == true
    error_message = "The vault must use Azure RBAC, not access policies."
  }

  assert {
    condition     = azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "The vault firewall must deny by default."
  }

  assert {
    condition     = length(azurerm_key_vault.this.name) <= 24
    error_message = "Key Vault names are limited to 24 characters."
  }

  assert {
    condition     = azurerm_key_vault.this.sku_name == "standard"
    error_message = "Use the standard SKU - premium costs more and isn't needed."
  }

  assert {
    condition     = azurerm_key_vault_secret.this.expiration_date == "2027-12-31T00:00:00Z"
    error_message = "The secret must have an expiry date."
  }

  assert {
    condition     = azurerm_key_vault_secret.this.value == null
    error_message = "The secret must be sent write-only (value_wo) - its value must never be in state."
  }
}

run "rejects_long_name" {
  command = plan

  variables {
    short_name = "this-name-is-far-too-long"
  }

  expect_failures = [var.short_name]
}

run "rejects_ip_without_cidr" {
  command = plan

  variables {
    allowed_ip_addresses = ["203.0.113.10"]
  }

  expect_failures = [var.allowed_ip_addresses]
}

run "rejects_no_secret_officer" {
  command = plan

  variables {
    secret_officer_principal_ids = []
  }

  expect_failures = [var.secret_officer_principal_ids]
}
