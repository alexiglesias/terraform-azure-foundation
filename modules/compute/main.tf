locals {
  # Arm sizes have a "p" in their feature letters (B2pts_v2, D2ps_v5) and
  # need the arm64 Ubuntu image. B2ats_v2 / B2ts_v2 are x64.
  is_arm = can(regex("^Standard_[A-Za-z]+[0-9]+[a-z]*p[a-z]*_v[0-9]+$", var.vm_size))
}

# ---------------------------------------------------------------------------
# Network card: private IP only
# ---------------------------------------------------------------------------

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id: the VM has no address on the internet at all.
  }
}

# ---------------------------------------------------------------------------
# The VM
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "this" {
  # checkov:skip=CKV_AZURE_50:The VM agent extension is needed for Run Command - the only admin path, since there is no SSH and no public IP.
  name                  = "vm-${var.name}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.this.id]

  admin_username                  = var.admin_username
  disable_password_authentication = true # keys only - and no route in for SSH anyway

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS" # Premium SSD: the free disk type (P6)
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = local.is_arm ? "server-arm64" : "server"
    version   = "latest"
  }

  # Trusted Launch: secure boot + a virtual TPM protect the boot chain. Free.
  # Only on x64 sizes - not every Arm size supports it.
  secure_boot_enabled = !local.is_arm
  vtpm_enabled        = !local.is_arm

  # The VM's own identity in Entra ID. Azure manages its credentials - there
  # is no password or key anywhere for us to store or leak.
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Least privilege: the VM may read ONE secret - not the vault, not the others
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "read_one_secret" {
  scope                = var.secret_resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.this.identity[0].principal_id
}
