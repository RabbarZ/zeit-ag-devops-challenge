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

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "subnet_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "keyvault_id" {
  description = "Key Vault the VM identity may write to."
  type        = string
}

variable "cloud_init_template" {
  type = string
}

variable "cloud_init_vars" {
  description = "Extra template variables. docker_disk_lun and docker_disk_script are added by the module."
  type        = map(string)
  default     = {}
}

variable "data_disk_size_gb" {
  description = "Optional data disk. 0 disables it."
  type        = number
  default     = 0
}

variable "data_disk_lun" {
  type    = number
  default = 10
}

variable "docker_disk_size_gb" {
  type    = number
  default = 512
}

variable "docker_disk_lun" {
  type    = number
  default = 10
}

variable "patch_mode" {
  description = "AutomaticByPlatform lets Azure install updates and reboot the VM. ImageDefault leaves patching to us."
  type        = string
  default     = "AutomaticByPlatform"

  validation {
    condition     = contains(["ImageDefault", "AutomaticByPlatform"], var.patch_mode)
    error_message = "patch_mode must be ImageDefault or AutomaticByPlatform."
  }
}

variable "bypass_platform_safety_checks_on_user_schedule" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
