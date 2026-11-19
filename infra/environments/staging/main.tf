provider "azurerm" {
  features {}
}

locals {
  state_config = {
    resource_group_name  = var.terraform_state_resource_group_name
    storage_account_name = var.terraform_state_storage_account_name
    container_name       = var.terraform_state_container_name
  }

  observability_private_ip = data.terraform_remote_state.observability.outputs.vm_private_ip
  observability_secrets = local.observability_private_ip == null ? {} : {
    "otlp-endpoint" = "http://${local.observability_private_ip}:4317"
    "loki-endpoint" = "http://${local.observability_private_ip}:3100/loki/api/v1/push"
  }

  peer_states = {
    observability = data.terraform_remote_state.observability.outputs
    control       = data.terraform_remote_state.control.outputs
  }
  peer_vnet_ids = { for name, outputs in local.peer_states : name => outputs.vnet_id if outputs.vnet_id != null }

  control_vm_principal_id = data.terraform_remote_state.control.outputs.vm_identity_principal_id
}

# Cross-state reads: apply order matters. Observability must exist before the apps,
# and observability has to be applied again after the apps to add the reverse peerings.
data "terraform_remote_state" "observability" {
  backend  = "azurerm"
  config   = merge(local.state_config, { key = "observability.tfstate" })
  defaults = { vnet_id = null, vm_private_ip = null }
}

data "terraform_remote_state" "control" {
  backend  = "azurerm"
  config   = merge(local.state_config, { key = "control.tfstate" })
  defaults = { vnet_id = null, vm_identity_principal_id = null }
}

module "app" {
  source = "../../modules/app-environment"

  env_name                     = "staging"
  resource_name_prefix         = var.resource_name_prefix
  location                     = var.location
  vnet_cidr                    = var.vnet_cidr
  vm_size                      = var.vm_size
  docker_disk_size_gb          = var.docker_disk_size_gb
  pg_sku                       = var.pg_sku
  pg_storage_mb                = var.pg_storage_mb
  pg_backup_retention_days     = var.pg_backup_retention_days
  pg_geo_redundant_backup      = var.pg_geo_redundant_backup
  pg_high_availability_mode    = var.pg_high_availability_mode
  ssh_public_key               = var.ssh_public_key
  acr_name                     = var.acr_name
  entra_tenant_id              = var.entra_tenant_id
  entra_admin_group_object_id  = var.entra_admin_group_object_id
  entra_admin_group_name       = var.entra_admin_group_name
  github_actions_principal_id  = var.github_actions_principal_id
  dns_zone_name                = var.dns_zone_name
  dns_zone_resource_group_name = var.dns_zone_resource_group_name
  dns_suffix                   = var.dns_suffix
  seed_secrets                 = merge(var.seed_secrets, local.observability_secrets)
  peer_vnet_ids                = local.peer_vnet_ids
  patch_schedule               = var.patch_schedule
  tags                         = var.tags
}

# The control VM provisions tenants, so it gets access to this environment's secrets, resource group and database.
resource "azurerm_role_assignment" "control_vm_keyvault" {
  count                = local.control_vm_principal_id == null ? 0 : 1
  scope                = module.app.keyvault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = local.control_vm_principal_id
}

resource "azurerm_role_assignment" "control_vm_resource_group" {
  count                = local.control_vm_principal_id == null ? 0 : 1
  scope                = module.app.resource_group_id
  role_definition_name = "Reader"
  principal_id         = local.control_vm_principal_id
}

resource "azurerm_role_assignment" "control_vm_postgres" {
  count                = local.control_vm_principal_id == null ? 0 : 1
  scope                = module.app.pg_server_id
  role_definition_name = "Contributor"
  principal_id         = local.control_vm_principal_id
}

