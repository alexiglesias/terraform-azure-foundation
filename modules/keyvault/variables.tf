variable "short_name" {
  description = "Short name for the vault, e.g. azfdn-dev. Becomes kv-<short_name>-<6 random chars> (Key Vault names: max 24, globally unique)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,14}$", var.short_name))
    error_message = "short_name must be 1-14 lowercase letters, digits or hyphens, so the full vault name stays within 24 characters."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the vault in."
  type        = string
}

variable "tags" {
  description = "Tags added to every resource that supports them."
  type        = map(string)
  default     = {}
}

variable "allowed_ip_addresses" {
  description = "Public IPs (CIDR, e.g. 81.2.3.4/32) allowed through the vault firewall - your laptop."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for ip in var.allowed_ip_addresses : can(cidrhost(ip, 0))])
    error_message = "Each entry must be in CIDR form, e.g. 81.2.3.4/32 (Azure stores /32 and would otherwise show a change on every plan)."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnets allowed through the vault firewall (they need the Microsoft.KeyVault service endpoint)."
  type        = list(string)
  default     = []
}

variable "secret_officer_principal_ids" {
  description = "Object IDs allowed to create and update secrets (you, and later the CI identity). Passed in explicitly so it doesn't change with who runs Terraform."
  type        = set(string)

  validation {
    condition     = length(var.secret_officer_principal_ids) > 0
    error_message = "At least one secret officer is needed, or nobody can write the secret."
  }
}

variable "secret_name" {
  description = "Name of the demo secret the VM will read."
  type        = string
  default     = "app-db-password"
}

variable "secret_expiration_date" {
  description = "When the secret expires (RFC 3339), e.g. 2027-12-31T00:00:00Z."
  type        = string

  validation {
    condition     = can(formatdate("YYYY", var.secret_expiration_date))
    error_message = "secret_expiration_date must be an RFC 3339 timestamp, e.g. 2027-12-31T00:00:00Z."
  }
}

variable "secret_version" {
  description = "Bump this number to generate and store a new password (the value itself is never kept in state)."
  type        = number
  default     = 1
}

variable "network_default_action" {
  description = "Key Vault firewall default: Deny (only allowed IPs and subnets) or Allow (any network, RBAC still required)."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Deny", "Allow"], var.network_default_action)
    error_message = "network_default_action must be Deny or Allow."
  }
}
