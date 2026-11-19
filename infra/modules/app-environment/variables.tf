variable "env_name" {
  description = "staging or production, for example."
  type        = string
}

variable "resource_name_prefix" {
  type    = string
  default = "rg-acme"
}

variable "location" {
  type    = string
  default = "switzerlandnorth"
}

variable "vnet_cidr" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "docker_disk_size_gb" {
  type    = number
  default = 512
}

variable "pg_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "pg_storage_mb" {
  type    = number
  default = 32768
}

variable "pg_backup_retention_days" {
  type    = number
  default = 7
}

variable "pg_geo_redundant_backup" {
  type    = bool
  default = false
}

variable "pg_high_availability_mode" {
  type    = string
  default = "Disabled"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "acr_name" {
  type = string
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

variable "github_actions_principal_id" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "dns_zone_resource_group_name" {
  type = string
}

variable "dns_suffix" {
  description = "Full environment domain, for example staging.planner.example. Tenants become <tenant>.<dns_suffix>."
  type        = string
}

variable "seed_secrets" {
  type      = map(string)
  sensitive = true
  default   = {}
}

variable "peer_vnet_ids" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
