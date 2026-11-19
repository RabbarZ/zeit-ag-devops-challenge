output "vnet_id" {
  value = module.observability.vnet_id
}

output "vm_private_ip" {
  value = module.observability.vm_private_ip
}

output "grafana_fqdn" {
  value = module.observability.grafana_fqdn
}
