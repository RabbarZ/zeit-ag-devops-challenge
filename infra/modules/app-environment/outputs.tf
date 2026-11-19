output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

output "vm_public_ip" {
  value = module.vm.public_ip
}

output "vm_private_ip" {
  value = module.vm.private_ip
}

output "keyvault_id" {
  value = module.keyvault.vault_id
}

output "keyvault_name" {
  value = module.keyvault.vault_name
}

output "pg_server_id" {
  value = module.postgres.server_id
}

output "pg_fqdn" {
  value = module.postgres.fqdn
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "patch_window" {
  value = module.vm.patch_window
}
