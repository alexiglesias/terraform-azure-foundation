# Unit tests for the compute module, with a mock provider (no Azure, no cost).
#   terraform -chdir=modules/compute init -backend=false
#   terraform -chdir=modules/compute test

mock_provider "azurerm" {}

variables {
  name                = "test"
  location            = "swedencentral"
  resource_group_name = "rg-test"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-web"
  # A correctly encoded but random public key: Azure checks the format, and
  # nobody holds a private key for it.
  admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOv6FXo1Hl5afDwoOS6rWc8E/2JITYBfKbAa77ISKdrv test-only-not-used"
  secret_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test/secrets/app-db-password"
}

run "secure_free_defaults" {
  command = plan

  assert {
    condition     = azurerm_network_interface.this.ip_configuration[0].public_ip_address_id == null
    error_message = "The VM must have no public IP."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.disable_password_authentication == true
    error_message = "Password login must be off."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.os_disk[0].storage_account_type == "Premium_LRS" && azurerm_linux_virtual_machine.this.os_disk[0].disk_size_gb == 64
    error_message = "OS disk must be a 64 GB Premium SSD (P6) - the free-account disk."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.identity[0].type == "SystemAssigned"
    error_message = "The VM needs a system-assigned managed identity."
  }

  assert {
    condition     = azurerm_role_assignment.read_one_secret.role_definition_name == "Key Vault Secrets User" && azurerm_role_assignment.read_one_secret.scope == var.secret_resource_id
    error_message = "The VM may only read secrets, and only the one secret it was given."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.source_image_reference[0].sku == "server" && azurerm_linux_virtual_machine.this.secure_boot_enabled == true
    error_message = "x64 sizes use the x64 image with Trusted Launch (secure boot) on."
  }
}

run "arm_size_uses_arm_image" {
  command = plan

  variables {
    vm_size = "Standard_B2pts_v2"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.source_image_reference[0].sku == "server-arm64"
    error_message = "Arm sizes must use the arm64 Ubuntu image."
  }
}

run "rejects_billed_size" {
  command = plan

  variables {
    vm_size = "Standard_B2ts_v2"
  }

  expect_failures = [var.vm_size]
}

run "rejects_non_public_key" {
  command = plan

  variables {
    admin_ssh_public_key = "this is not a public key line"
  }

  expect_failures = [var.admin_ssh_public_key]
}

run "rejects_big_disk" {
  command = plan

  variables {
    os_disk_size_gb = 128
  }

  expect_failures = [var.os_disk_size_gb]
}
