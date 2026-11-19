variable "env_name" {
  description = "Short environment name used in resource names, e.g. staging."
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for Azure resource names."
  type        = string
  default     = "rg-acme"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_cidr" {
  description = "VNet CIDR. Must be a /24: it is split into a VM /25 and a PostgreSQL /25."
  type        = string
}

variable "nsg_inbound_rules" {
  description = "Inbound NSG rules. DenyAllInbound must have the lowest priority."
  type = list(object({
    name     = string
    priority = number
    source   = string
    port     = string
    protocol = string
  }))
}

variable "enable_pg_subnet" {
  description = "Create the delegated PostgreSQL subnet and its private DNS zone."
  type        = bool
  default     = true
}

variable "peer_vnet_ids" {
  description = "Peer name to remote VNet ID."
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
