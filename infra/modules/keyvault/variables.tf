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

variable "entra_tenant_id" {
  type = string
}

variable "admin_group_object_id" {
  description = "Entra group that receives Key Vault Administrator."
  type        = string
}

variable "github_actions_principal_id" {
  description = "Service principal used by CI."
  type        = string
}

variable "seed_secrets" {
  description = "Secret name to value. Non-generated values only."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
