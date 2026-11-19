# Legacy per-tenant provisioning. Not referenced by any environment; see README.md.
resource "azurerm_postgresql_flexible_server_database" "tenant" {
  name      = var.database_name
  server_id = var.pg_server_id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_dns_a_record" "tenant" {
  name                = var.subdomain
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_resource_group
  ttl                 = 300
  records             = [var.target_ip]
}
