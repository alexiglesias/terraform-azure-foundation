# A private Ubuntu VM in the web subnet. Its managed identity can read exactly
# one Key Vault secret. No public IP, no SSH: admin access is Run Command.
# See modules/compute.
module "compute" {
  source = "../../modules/compute"

  name                = local.name_prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  subnet_id            = module.network.subnet_ids["web"]
  vm_size              = var.vm_size
  admin_ssh_public_key = var.admin_ssh_public_key
  secret_resource_id   = module.keyvault.secret_resource_id
}

output "vm_name" {
  description = "Name of the VM."
  value       = module.compute.vm_name
}

output "vm_private_ip" {
  description = "The VM's private IP (not reachable from the internet)."
  value       = module.compute.private_ip
}

output "read_secret_command" {
  description = "Run the secret-read test on the VM through Run Command (no SSH needed)."
  value       = "az vm run-command invoke -g ${azurerm_resource_group.main.name} -n ${module.compute.vm_name} --command-id RunShellScript --scripts @scripts/read-secret.sh --parameters ${module.keyvault.key_vault_name} ${module.keyvault.secret_name} --query 'value[0].message' -o tsv"
}
