locals {
  name = "${var.resource_name_prefix}-${var.env_name}"

  user_data = base64encode(templatefile(var.cloud_init_template, merge(var.cloud_init_vars, {
    docker_disk_lun    = tostring(var.docker_disk_lun)
    docker_disk_script = file("${path.module}/scripts/prepare-docker-disk.sh")
  })))
}

resource "azurerm_public_ip" "this" {
  name                = "${local.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "${local.name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "${local.name}-vm"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = "azureuser"
  network_interface_ids           = [azurerm_network_interface.this.id]
  disable_password_authentication = true
  user_data                       = local.user_data
  tags                            = var.tags

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${local.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  patch_mode                                             = var.patch_mode
  patch_assessment_mode                                  = var.patch_mode
  provision_vm_agent                                     = true
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule

  lifecycle {
    # cloud-init runs on first boot only; later changes reach the VM as run commands.
    ignore_changes = [user_data, source_image_reference]
  }
}

resource "azurerm_managed_disk" "data" {
  count                = var.data_disk_size_gb > 0 ? 1 : 0
  name                 = "${local.name}-datadisk"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.data_disk_size_gb > 0 ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = var.data_disk_lun
  caching            = "ReadWrite"

  lifecycle {
    ignore_changes = [caching]
  }
}

resource "azurerm_managed_disk" "docker" {
  name                 = "${local.name}-dockerdisk"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.docker_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "docker" {
  managed_disk_id    = azurerm_managed_disk.docker.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = var.docker_disk_lun
  caching            = "ReadWrite"

  lifecycle {
    ignore_changes = [caching]
  }
}

resource "azurerm_virtual_machine_run_command" "container_heal" {
  name               = "container-heal-install"
  location           = var.location
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  tags               = var.tags

  source {
    script = file("${path.module}/scripts/install-container-heal.sh")
  }
}

resource "azurerm_virtual_machine_run_command" "docker_mount_check" {
  name               = "docker-mount-check-install"
  location           = var.location
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  tags               = var.tags

  source {
    script = file("${path.module}/scripts/install-docker-mount-check.sh")
  }

  depends_on = [azurerm_virtual_machine_data_disk_attachment.docker]
}

# Secrets Officer rather than Secrets User: bootstrap.sh stores the host key fingerprint on first boot.
resource "azurerm_role_assignment" "keyvault" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_linux_virtual_machine.this.identity[0].principal_id
}
