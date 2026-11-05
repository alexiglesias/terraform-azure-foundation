variable "name" {
  description = "Name prefix for every resource in this module, e.g. azure-foundation-dev."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the VM in."
  type        = string
}

variable "tags" {
  description = "Tags added to every resource that supports them."
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "Subnet for the VM's network card (the private web subnet)."
  type        = string
}

variable "vm_size" {
  description = "VM size. Free account (750 hours/month for 12 months): Standard_B2ats_v2 (x64), Standard_B2pts_v2 (Arm) or Standard_B1s."
  type        = string
  default     = "Standard_B2ats_v2"

  validation {
    condition     = contains(["Standard_B2ats_v2", "Standard_B2pts_v2", "Standard_B1s"], var.vm_size)
    error_message = "Use a free-account size: Standard_B2ats_v2, Standard_B2pts_v2 or Standard_B1s. Other sizes (e.g. Standard_B2ts_v2) are billed."
  }
}

variable "admin_username" {
  description = "Linux admin user. Azure requires one even though nothing can reach the VM over SSH."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "SSH PUBLIC key for the admin user (the .pub file). Never the private key."
  type        = string

  validation {
    condition     = can(regex("^ssh-(ed25519|rsa) ", var.admin_ssh_public_key))
    error_message = "admin_ssh_public_key must be a public key line starting with ssh-ed25519 or ssh-rsa - the contents of a .pub file."
  }
}

variable "secret_resource_id" {
  description = "Resource ID of the ONE Key Vault secret the VM may read."
  type        = string
}

variable "os_disk_size_gb" {
  description = "OS disk size. 64 GB Premium SSD = a P6 disk, which is in the free account (2 x P6 for 12 months)."
  type        = number
  default     = 64

  validation {
    condition     = var.os_disk_size_gb <= 64
    error_message = "Keep the OS disk at 64 GB or less - bigger disks are not in the free allowance."
  }
}
