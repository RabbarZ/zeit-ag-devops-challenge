resource "azurerm_key_vault" "this" {
  name                       = "${var.resource_name_prefix}-${var.env_name}-kv"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.entra_tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
}

resource "azurerm_role_assignment" "admin_group" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_group_object_id
}

# CI writes generated credentials, so it needs Secrets Officer.
resource "azurerm_role_assignment" "github_actions" {
  scope                            = azurerm_key_vault.this.id
  role_definition_name             = "Key Vault Secrets Officer"
  principal_id                     = var.github_actions_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "time_sleep" "rbac_propagation" {
  depends_on      = [azurerm_role_assignment.admin_group, azurerm_role_assignment.github_actions]
  create_duration = "60s"
}

resource "azurerm_key_vault_secret" "seed" {
  for_each     = nonsensitive(toset(keys(var.seed_secrets)))
  name         = each.key
  value        = var.seed_secrets[each.key]
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [time_sleep.rbac_propagation]
}
