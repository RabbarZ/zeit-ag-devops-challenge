output "vnet_id" {
  value = module.networking.vnet_id
}

output "vm_public_ip" {
  value = module.vm.public_ip
}

output "vm_identity_principal_id" {
  description = "Read by the app environments to grant this VM access to their resources."
  value       = module.vm.identity_principal_id
}

output "keyvault_name" {
  value = module.keyvault.vault_name
}
