variable "name" {
  description = "Name prefix for every resource in this module, e.g. azure-foundation-dev."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the network in."
  type        = string
}

variable "tags" {
  description = "Tags added to every resource that supports them."
  type        = map(string)
  default     = {}
}

variable "address_space" {
  description = "Address range(s) of the virtual network."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "subnets" {
  description = "Subnets to create, keyed by name. Must contain \"web\" and \"app\"."
  type = map(object({
    cidr              = string
    service_endpoints = optional(list(string), [])
  }))

  validation {
    condition     = contains(keys(var.subnets), "web") && contains(keys(var.subnets), "app")
    error_message = "subnets must contain a \"web\" and an \"app\" subnet - the NSGs below are written for those two tiers."
  }
}
