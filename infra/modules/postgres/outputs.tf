output "fqdn" {
  description = "Private FQDN, resolved through the private DNS zone."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "server_id" {
  value = azurerm_postgresql_flexible_server.this.id
}

output "admin_login" {
  value = azurerm_postgresql_flexible_server.this.administrator_login
}
