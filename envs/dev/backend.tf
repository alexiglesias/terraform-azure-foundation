# Remote state in Azure Blob Storage (created by bootstrap/). This is a
# *partial* backend config: the subscription, resource group, storage account
# and container live in backend.hcl, which bootstrap/ generates and git
# ignores, so the names never have to be copied by hand.
#
#   terraform -chdir=envs/dev init -backend-config=backend.hcl
#
# Locking: the azurerm backend takes a lease on the state blob while a plan
# or apply runs, so two runs can never write the state at the same time -
# no extra lock table needed (unlike the old S3 + DynamoDB setup).

terraform {
  backend "azurerm" {
    key = "terraform-azure-foundation/dev/terraform.tfstate"
  }
}
