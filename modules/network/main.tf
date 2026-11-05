# ---------------------------------------------------------------------------
# Virtual network and subnets
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets # for_each, not count: adding a subnet never renumbers the others

  name                 = "snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = each.value.service_endpoints

  # Private subnet: no hidden "default" route to the internet. Anything that
  # needs to get out must be given an explicit path (here: service endpoints).
  default_outbound_access_enabled = false
}

# ---------------------------------------------------------------------------
# Network security groups (firewalls on each subnet)
#
# Azure's built-in rules also let in all traffic from inside the VNet and
# from Azure's load balancer. The deny-all rule at priority 4000 closes that,
# so each tier really only accepts what is listed above it.
# ---------------------------------------------------------------------------

resource "azurerm_network_security_group" "web" {
  # checkov:skip=CKV_AZURE_160:Intended - this is the web tier, and 80/443 are the only ports it opens. Everything else is denied at priority 4000.
  name                = "nsg-${var.name}-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-http-https-from-internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["80", "443"]
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.name}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-8080-from-web-subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = var.subnets["web"].cidr
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "8080"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.this["web"].id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.this["app"].id
  network_security_group_id = azurerm_network_security_group.app.id
}
