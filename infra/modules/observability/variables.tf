variable "resource_name_prefix" {
  type    = string
  default = "rg-acme"
}

variable "location" {
  type    = string
  default = "switzerlandnorth"
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2ms"
}

variable "data_disk_size_gb" {
  description = "LGTM data disk, mounted at /mnt/logs."
  type        = number
  default     = 128
}

variable "docker_disk_size_gb" {
  type    = number
  default = 256
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "acr_login_server" {
  type = string
}

variable "entra_tenant_id" {
  type = string
}

variable "entra_admin_group_object_id" {
  type = string
}

variable "github_actions_principal_id" {
  type = string
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

variable "dns_zone_name" {
  type = string
}

variable "dns_zone_resource_group_name" {
  type = string
}

variable "grafana_hostname" {
  description = "Public Grafana hostname, for example grafana.planner.example."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
