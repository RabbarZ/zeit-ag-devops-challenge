variable "env_name" {
  type = string
}

variable "resource_name_prefix" {
  type    = string
  default = "rg-acme"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "pg_version" {
  type    = string
  default = "16"
}

variable "delegated_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "backup_retention_days" {
  type    = number
  default = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}

variable "high_availability_mode" {
  description = "Disabled, ZoneRedundant or SameZone."
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "ZoneRedundant", "SameZone"], var.high_availability_mode)
    error_message = "high_availability_mode must be Disabled, ZoneRedundant or SameZone."
  }
}

variable "entra_tenant_id" {
  type = string
}

variable "entra_admin_group_object_id" {
  type = string
}

variable "entra_admin_group_name" {
  type = string
}

variable "keyvault_id" {
  description = "Key Vault where the generated admin password is stored."
  type        = string
}

variable "keyvault_rbac_ready_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
