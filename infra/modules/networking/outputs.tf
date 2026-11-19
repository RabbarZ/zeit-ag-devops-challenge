output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vm_subnet_id" {
  value = azurerm_subnet.vm.id
}

output "pg_subnet_id" {
  value = one(azurerm_subnet.pg[*].id)
}

output "pg_private_dns_zone_id" {
  value = one(azurerm_private_dns_zone.pg[*].id)
}
