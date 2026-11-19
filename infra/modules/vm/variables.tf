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

# Without a schedule, Azure picks the patch and reboot time (incident 1: an evening reboot nobody expected).
# With a schedule, patches and reboots happen only inside this weekly window.
variable "patch_schedule" {
  description = "Weekly OS patch window. null leaves the timing to Azure. start_date_time is \"YYYY-MM-DD hh:mm\" in time_zone."
  type = object({
    start_date_time = string
    recur_every     = string
    duration        = optional(string, "03:00")
    time_zone       = optional(string, "W. Europe Standard Time")
  })
  default = null

  validation {
    condition     = var.patch_schedule == null || var.patch_mode == "AutomaticByPlatform"
    error_message = "A patch schedule only works when Azure does the patching (patch_mode = AutomaticByPlatform); the schedule then decides when."
  }

  validation {
    condition     = var.patch_schedule == null ? true : !strcontains(var.patch_schedule.recur_every, "Monday")
    error_message = "No patch window on Mondays: Monday morning is the planning peak (docs/product.md)."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
