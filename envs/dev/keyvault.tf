# The password safe: an RBAC Key Vault behind a firewall, holding one demo
# secret that the VM (step 5) is allowed to read. See modules/keyvault.
module "keyvault" {
  source = "../../modules/keyvault"

  short_name          = "azfdn-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  allowed_ip_addresses         = var.allowed_ip_addresses
  allowed_subnet_ids           = [module.network.subnet_ids["web"]]
  secret_officer_principal_ids = var.secret_officer_principal_ids
  secret_expiration_date       = var.secret_expiration_date
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = module.keyvault.key_vault_name
}

output "secret_name" {
  description = "Name of the demo secret."
  value       = module.keyvault.secret_name
}
