locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Cost tags: every resource carries them, so Cost Management can group
  # and filter spend by project, environment or owner.
  tags = {
    project     = var.project_name
    environment = var.environment
    owner       = var.owner
    cost_center = "portfolio"
    managed_by  = "terraform"
  }
}

# A resource group is a folder in Azure: everything this environment
# creates goes inside it, so it can be listed, costed and deleted together.
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}
