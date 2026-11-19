provider "azurerm" {
  features {}
}

locals {
  state_config = {
    resource_group_name  = var.terraform_state_resource_group_name
    storage_account_name = var.terraform_state_storage_account_name
    container_name       = var.terraform_state_container_name
  }
}

# Observability peers back to every environment, so it reads their VNet IDs (second apply).
data "terraform_remote_state" "peer" {
  for_each = toset(["control", "staging", "production"])

  backend  = "azurerm"
  config   = merge(local.state_config, { key = "${each.key}.tfstate" })
  defaults = { vnet_id = null }
}

module "observability" {
  source = "../../modules/observability"

  resource_name_prefix         = var.resource_name_prefix
  location                     = var.location
  vnet_cidr                    = var.vnet_cidr
  vm_size                      = var.vm_size
  data_disk_size_gb            = var.data_disk_size_gb
  docker_disk_size_gb          = var.docker_disk_size_gb
  ssh_public_key               = var.ssh_public_key
  acr_login_server             = "${var.acr_name}.azurecr.io"
  entra_tenant_id              = var.entra_tenant_id
  entra_admin_group_object_id  = var.entra_admin_group_object_id
  github_actions_principal_id  = var.github_actions_principal_id
  seed_secrets                 = var.seed_secrets
  dns_zone_name                = var.dns_zone_name
  dns_zone_resource_group_name = var.dns_zone_resource_group_name
  grafana_hostname             = var.grafana_hostname
  peer_vnet_ids = {
    for name, state in data.terraform_remote_state.peer : name => state.outputs.vnet_id
    if state.outputs.vnet_id != null
  }
  tags = var.tags
}
