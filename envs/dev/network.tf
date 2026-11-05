# The network for this environment: a VNet with a web and an app subnet,
# each with its own firewall (NSG). See modules/network.
module "network" {
  source = "../../modules/network"

  name                = local.name_prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  address_space = ["10.20.0.0/16"]
  subnets = {
    # The VM goes here. The Key Vault service endpoint is its free, private
    # path to Key Vault (the subnet has no internet route).
    web = { cidr = "10.20.1.0/24", service_endpoints = ["Microsoft.KeyVault"] }
    # Reserved for a later app tier; only reachable from web on 8080.
    app = { cidr = "10.20.2.0/24" }
  }
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = module.network.vnet_name
}

output "nsg_names" {
  description = "NSG names keyed by tier (web, app)."
  value       = module.network.nsg_names
}
