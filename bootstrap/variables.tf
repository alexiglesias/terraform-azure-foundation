variable "project_name" {
  description = "Short name used to name and tag every resource."
  type        = string
  default     = "azure-foundation"
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
  description = "Azure region. swedencentral is where the free VM sizes are open to this subscription."
  type        = string
  default     = "swedencentral"
}

variable "budget_amount" {
  description = "Monthly spend (in the billing currency, GBP for this account) that triggers the alerts. The whole project is designed to cost 0."
  type        = number
  default     = 5

  validation {
    condition     = var.budget_amount > 0
    error_message = "budget_amount must be greater than 0."
  }
}

variable "budget_alert_email" {
  description = "Email that receives the budget alerts."
  type        = string

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.budget_alert_email))
    error_message = "budget_alert_email must be a valid email address - an alert nobody receives is not an alert."
  }
}
