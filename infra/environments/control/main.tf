provider "azurerm" {
  features {}
}

locals {
  state_config = {
    resource_group_name  = var.terraform_state_resource_group_name
    storage_account_name = var.terraform_state_storage_account_name
    container_name       = var.terraform_state_container_name
  }
  peer_states = merge(
    { observability = data.terraform_remote_state.observability.outputs },
    { for name, state in data.terraform_remote_state.app : name => state.outputs },
  )
  peer_vnet_ids = { for name, outputs in local.peer_states : name => outputs.vnet_id if outputs.vnet_id != null }
}

data "terraform_remote_state" "observability" {
  backend  = "azurerm"
  config   = merge(local.state_config, { key = "observability.tfstate" })
  defaults = { vnet_id = null }
}

# Tenant provisioning runs SSH from this VM into each app VM, so control peers with them.
data "terraform_remote_state" "app" {
  for_each = toset(["staging", "production"])

  backend  = "azurerm"
  config   = merge(local.state_config, { key = "${each.key}.tfstate" })
  defaults = { vnet_id = null }
}

resource "azurerm_resource_group" "this" {
  name     = "${var.resource_name_prefix}-control"
  location = var.location
  tags     = var.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  env_name                    = "control"
  resource_name_prefix        = var.resource_name_prefix
  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  entra_tenant_id             = var.entra_tenant_id
  admin_group_object_id       = var.entra_admin_group_object_id
  github_actions_principal_id = var.github_actions_principal_id
  seed_secrets                = var.seed_secrets
  tags                        = var.tags
}

module "networking" {
  source = "../../modules/networking"

  env_name             = "control"
  resource_name_prefix = var.resource_name_prefix
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  vnet_cidr            = var.vnet_cidr
  enable_pg_subnet     = false
  peer_vnet_ids        = local.peer_vnet_ids
  tags                 = var.tags

  nsg_inbound_rules = [
    { name = "AllowHTTP", priority = 100, source = "Internet", port = "80", protocol = "Tcp" },
    { name = "AllowHTTPS", priority = 110, source = "Internet", port = "443", protocol = "Tcp" },
    { name = "AllowSSH", priority = 200, source = "Internet", port = "22", protocol = "Tcp" },
    { name = "DenyAllInbound", priority = 4096, source = "*", port = "*", protocol = "*" },
  ]
}

module "vm" {
  source = "../../modules/vm"

  env_name             = "control"
  resource_name_prefix = var.resource_name_prefix
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  vm_size              = var.vm_size
  subnet_id            = module.networking.vm_subnet_id
  ssh_public_key       = var.ssh_public_key
  keyvault_id          = module.keyvault.vault_id
  docker_disk_size_gb  = var.docker_disk_size_gb
  tags                 = var.tags

  cloud_init_template = "${path.module}/../../modules/vm/cloud-init/control.yml.tpl"
  cloud_init_vars = {
    keyvault_name    = module.keyvault.vault_name
    acr_login_server = "${var.acr_name}.azurecr.io"
    github_repo      = var.github_repo
    control_hostname = var.control_hostname
    compose_yml      = file("${path.module}/../../../runtime/control/compose.yml")
  }
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group
}

resource "azurerm_role_assignment" "ci_acr_pull" {
  scope                            = data.azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.github_actions_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# Contributor is broader than the single action the control plane needs (listCredentials).
resource "azurerm_role_assignment" "control_vm_acr" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "Contributor"
  principal_id         = module.vm.identity_principal_id
}

data "azurerm_dns_zone" "public" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_role_assignment" "control_vm_dns" {
  scope                = data.azurerm_dns_zone.public.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.vm.identity_principal_id
}

resource "azurerm_dns_a_record" "control" {
  name                = trimsuffix(var.control_hostname, ".${var.dns_zone_name}")
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  records             = [module.vm.public_ip]
  tags                = var.tags
}
