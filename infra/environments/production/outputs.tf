output "vnet_id" {
  value = module.app.vnet_id
}

output "vm_public_ip" {
  value = module.app.vm_public_ip
}

output "pg_fqdn" {
  value = module.app.pg_fqdn
}

output "keyvault_name" {
  value = module.app.keyvault_name
}
