output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.this.private_ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}

output "identity_principal_id" {
  value = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "patch_window" {
  description = "The weekly patch window assigned to this VM, or null when Azure picks the time."
  value = var.patch_schedule == null ? null : {
    recur_every         = azurerm_maintenance_configuration.patch[0].window[0].recur_every
    duration            = azurerm_maintenance_configuration.patch[0].window[0].duration
    vm_uses_user_window = azurerm_linux_virtual_machine.this.bypass_platform_safety_checks_on_user_schedule_enabled
    assigned_to_this_vm = length(azurerm_maintenance_assignment_virtual_machine.patch) == 1
  }
}
