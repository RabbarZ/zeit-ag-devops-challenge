resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Private access only: the server has no public endpoint and is reached through the delegated subnet.
resource "azurerm_postgresql_flexible_server" "this" {
  name                          = "${var.resource_name_prefix}-${var.env_name}-pg"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.pg_version
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login           = "pgadmin"
  administrator_password        = random_password.admin.result
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  tags                          = var.tags

  dynamic "high_availability" {
    for_each = var.high_availability_mode == "Disabled" ? [] : [1]
    content {
      mode = var.high_availability_mode
    }
  }

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = var.entra_tenant_id
  }

  lifecycle {
    ignore_changes = [administrator_password, zone, high_availability[0].standby_availability_zone]
  }
}

# Tenant migrations need these extensions; each new CREATE EXTENSION must be listed here.
resource "azurerm_postgresql_flexible_server_configuration" "azure_extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "PG_TRGM,PGCRYPTO"
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "this" {
  server_name         = azurerm_postgresql_flexible_server.this.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.entra_tenant_id
  object_id           = var.entra_admin_group_object_id
  principal_name      = var.entra_admin_group_name
  principal_type      = "Group"
}

resource "terraform_data" "keyvault_ready" {
  input = var.keyvault_rbac_ready_id
}

resource "azurerm_key_vault_secret" "admin_password" {
  name         = "pg-admin-password"
  value        = random_password.admin.result
  key_vault_id = var.keyvault_id
  depends_on   = [terraform_data.keyvault_ready]
}
