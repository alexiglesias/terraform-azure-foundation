# Unit tests for the network module. They run with a *mock* azurerm provider:
# no Azure login, no cost - Terraform only evaluates the plan.
#   terraform -chdir=modules/network init -backend=false
#   terraform -chdir=modules/network test

mock_provider "azurerm" {}

variables {
  name                = "test"
  location            = "swedencentral"
  resource_group_name = "rg-test"
  subnets = {
    web = { cidr = "10.20.1.0/24", service_endpoints = ["Microsoft.KeyVault"] }
    app = { cidr = "10.20.2.0/24" }
  }
}

run "subnets_are_private" {
  command = plan

  assert {
    condition     = alltrue([for s in azurerm_subnet.this : s.default_outbound_access_enabled == false])
    error_message = "Every subnet must be private (no default outbound internet access)."
  }

  assert {
    condition     = contains(azurerm_subnet.this["web"].service_endpoints, "Microsoft.KeyVault")
    error_message = "The web subnet needs the Key Vault service endpoint - it is the VM's only path to Key Vault."
  }
}

run "web_nsg_allows_only_80_and_443" {
  command = plan

  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.web.security_rule :
      r.access == "Allow" && r.direction == "Inbound" && r.source_address_prefix == "Internet" && toset(r.destination_port_ranges) == toset(["80", "443"])
    ])
    error_message = "The web NSG must allow 80 and 443 from the internet."
  }

  assert {
    condition = length([
      for r in azurerm_network_security_group.web.security_rule : r
      if r.access == "Allow" && r.direction == "Inbound"
    ]) == 1
    error_message = "The web NSG must have exactly one inbound allow rule (80/443)."
  }

  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.web.security_rule :
      r.access == "Deny" && r.direction == "Inbound" && r.priority == 4000 && r.source_address_prefix == "*"
    ])
    error_message = "The web NSG must end with a deny-all inbound rule, overriding Azure's allow-VNet default."
  }
}

run "app_nsg_only_accepts_the_web_subnet" {
  command = plan

  assert {
    condition = alltrue([
      for r in azurerm_network_security_group.app.security_rule :
      r.source_address_prefix == "10.20.1.0/24" if r.access == "Allow"
    ])
    error_message = "The app NSG may only allow traffic from the web subnet."
  }
}

run "rejects_missing_web_subnet" {
  command = plan

  variables {
    subnets = {
      app = { cidr = "10.20.2.0/24" }
    }
  }

  expect_failures = [var.subnets]
}
