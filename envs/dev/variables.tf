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
