output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "vm_public_ip" {
  value = module.vm.public_ip
}

output "vm_private_ip" {
  description = "Apps send OTLP to this address over VNet peering."
  value       = module.vm.private_ip
}

output "keyvault_name" {
  value = module.keyvault.vault_name
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "grafana_fqdn" {
  value = var.grafana_hostname
}
