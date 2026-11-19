locals {
  resource_group_name = "${var.resource_name_prefix}-${var.env_name}"
  dns_subdomain       = var.dns_suffix == var.dns_zone_name ? "" : trimsuffix(var.dns_suffix, ".${var.dns_zone_name}")
  wildcard_record     = local.dns_subdomain == "" ? "*" : "*.${local.dns_subdomain}"
  tags = merge({
    environment = var.env_name
    managed_by  = "terraform"
    product     = "acme-planner"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# CI runs VM run commands to validate the bootstrap, so it needs VM Contributor on the group.
resource "azurerm_role_assignment" "ci_vm_contributor" {
  scope                            = azurerm_resource_group.this.id
  role_definition_name             = "Virtual Machine Contributor"
  principal_id                     = var.github_actions_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "time_sleep" "rbac_propagation" {
  depends_on      = [azurerm_role_assignment.ci_vm_contributor]
  create_duration = "120s"
}

module "keyvault" {
  source = "../keyvault"

  env_name                    = var.env_name
  resource_name_prefix        = var.resource_name_prefix
  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  entra_tenant_id             = var.entra_tenant_id
  admin_group_object_id       = var.entra_admin_group_object_id
  github_actions_principal_id = var.github_actions_principal_id
  seed_secrets                = var.seed_secrets
  tags                        = local.tags
}

module "networking" {
  source = "../networking"

  env_name             = var.env_name
  resource_name_prefix = var.resource_name_prefix
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  vnet_cidr            = var.vnet_cidr
  peer_vnet_ids        = var.peer_vnet_ids
  tags                 = local.tags

  nsg_inbound_rules = [
    { name = "AllowHTTP", priority = 100, source = "Internet", port = "80", protocol = "Tcp" },
    { name = "AllowHTTPS", priority = 110, source = "Internet", port = "443", protocol = "Tcp" },
    { name = "AllowSSH", priority = 200, source = "Internet", port = "22", protocol = "Tcp" },
    { name = "AllowVNetSSH", priority = 210, source = "VirtualNetwork", port = "22", protocol = "Tcp" },
    { name = "DenyAllInbound", priority = 4096, source = "*", port = "*", protocol = "*" },
  ]
}

module "vm" {
  source = "../vm"

  env_name             = var.env_name
  resource_name_prefix = var.resource_name_prefix
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  vm_size              = var.vm_size
  subnet_id            = module.networking.vm_subnet_id
  ssh_public_key       = var.ssh_public_key
  keyvault_id          = module.keyvault.vault_id
  docker_disk_size_gb  = var.docker_disk_size_gb
  patch_schedule       = var.patch_schedule
  tags                 = local.tags

  cloud_init_template = "${path.module}/../vm/cloud-init/app.yml.tpl"
  cloud_init_vars = {
    env_name         = var.env_name
    keyvault_name    = module.keyvault.vault_name
    acr_login_server = "${var.acr_name}.azurecr.io"
    compose_yml      = file("${path.module}/../../../runtime/app/compose.yml")
    alloy_config     = file("${path.module}/../../../runtime/app/alloy/config.alloy")
  }

  depends_on = [time_sleep.rbac_propagation]
}

module "postgres" {
  source = "../postgres"

  env_name                     = var.env_name
  resource_name_prefix         = var.resource_name_prefix
  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  sku_name                     = var.pg_sku
  storage_mb                   = var.pg_storage_mb
  backup_retention_days        = var.pg_backup_retention_days
  geo_redundant_backup_enabled = var.pg_geo_redundant_backup
  high_availability_mode       = var.pg_high_availability_mode
  delegated_subnet_id          = module.networking.pg_subnet_id
  private_dns_zone_id          = module.networking.pg_private_dns_zone_id
  entra_tenant_id              = var.entra_tenant_id
  entra_admin_group_object_id  = var.entra_admin_group_object_id
  entra_admin_group_name       = var.entra_admin_group_name
  keyvault_id                  = module.keyvault.vault_id
  keyvault_rbac_ready_id       = module.keyvault.rbac_ready_id
  tags                         = local.tags
}

resource "azurerm_dns_a_record" "wildcard" {
  name                = local.wildcard_record
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  records             = [module.vm.public_ip]
  tags                = local.tags
}
