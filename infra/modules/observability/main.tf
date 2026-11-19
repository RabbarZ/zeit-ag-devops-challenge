locals {
  resource_group_name = "${var.resource_name_prefix}-observability"
  grafana_record      = trimsuffix(var.grafana_hostname, ".${var.dns_zone_name}")
  tags = merge({
    environment = "observability"
    managed_by  = "terraform"
    product     = "acme-planner"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

module "keyvault" {
  source = "../keyvault"

  env_name                    = "observability"
  resource_name_prefix        = var.resource_name_prefix
  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  entra_tenant_id             = var.entra_tenant_id
  admin_group_object_id       = var.entra_admin_group_object_id
  github_actions_principal_id = var.github_actions_principal_id
  seed_secrets                = var.seed_secrets
  tags                        = local.tags
}

# Apps and the control plane send OTLP and Loki pushes from 10.0.0.0/16 over VNet peering.
module "networking" {
  source = "../networking"

  env_name             = "observability"
  resource_name_prefix = var.resource_name_prefix
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  vnet_cidr            = var.vnet_cidr
  enable_pg_subnet     = false
  peer_vnet_ids        = var.peer_vnet_ids
  tags                 = local.tags

  nsg_inbound_rules = [
    { name = "AllowHTTPS", priority = 100, source = "Internet", port = "443", protocol = "Tcp" },
    { name = "AllowHTTP", priority = 110, source = "Internet", port = "80", protocol = "Tcp" },
    { name = "AllowSSH", priority = 200, source = "Internet", port = "22", protocol = "Tcp" },
    { name = "AllowOTLPgRPC", priority = 300, source = "10.0.0.0/16", port = "4317", protocol = "Tcp" },
    { name = "AllowOTLPHTTP", priority = 310, source = "10.0.0.0/16", port = "4318", protocol = "Tcp" },
    { name = "AllowLokiPush", priority = 320, source = "10.0.0.0/16", port = "3100", protocol = "Tcp" },
    { name = "DenyAllInbound", priority = 4096, source = "*", port = "*", protocol = "*" },
  ]
}

module "vm" {
  source = "../vm"

  env_name             = "observability"
  resource_name_prefix = var.resource_name_prefix
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  vm_size              = var.vm_size
  subnet_id            = module.networking.vm_subnet_id
  ssh_public_key       = var.ssh_public_key
  keyvault_id          = module.keyvault.vault_id
  data_disk_size_gb    = var.data_disk_size_gb
  data_disk_lun        = 10
  docker_disk_size_gb  = var.docker_disk_size_gb
  docker_disk_lun      = 11
  tags                 = local.tags

  cloud_init_template = "${path.module}/../vm/cloud-init/observability.yml.tpl"
  cloud_init_vars = {
    keyvault_name    = module.keyvault.vault_name
    acr_login_server = var.acr_login_server
    grafana_hostname = var.grafana_hostname
    data_disk_lun    = "10"
  }
}

resource "azurerm_dns_a_record" "grafana" {
  name                = local.grafana_record
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  records             = [module.vm.public_ip]
  tags                = local.tags
}
