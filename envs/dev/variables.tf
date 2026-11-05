variable "project_name" {
  description = "Short name used to name and tag every resource."
  type        = string
  default     = "azure-foundation"
}

variable "environment" {
  description = "Environment name, used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "subscription_id" {
  description = "The only Azure subscription this configuration may touch (az account show --query id -o tsv)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a subscription GUID, e.g. 00000000-0000-0000-0000-000000000000."
  }
}

variable "location" {
  description = "Azure region for every resource. swedencentral is where the free VM sizes are open to this subscription."
  type        = string
  default     = "swedencentral"
}

variable "owner" {
  description = "Who to ask about these resources - goes in the owner tag."
  type        = string
  default     = "alex"
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

variable "allowed_ip_addresses" {
  description = "Your public IP in CIDR form (curl -s https://api.ipify.org, then add /32). Allowed through the Key Vault firewall."
  type        = list(string)
  default     = []
}

variable "secret_officer_principal_ids" {
  description = "Object IDs allowed to write Key Vault secrets: you (az ad signed-in-user show --query id -o tsv), later also the CI identity."
  type        = set(string)
}

variable "secret_expiration_date" {
  description = "When the demo secret expires (RFC 3339)."
  type        = string
  default     = "2027-12-31T00:00:00Z"
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------

variable "admin_ssh_public_key" {
  description = "SSH PUBLIC key for the VM admin user (cat ~/.ssh/gitlab_2026.pub). Never the private key."
  type        = string
}

variable "vm_size" {
  description = "VM size (free account: Standard_B2ats_v2, or Standard_B2pts_v2 with the arm64 image)."
  type        = string
  default     = "Standard_B2ats_v2"
}
