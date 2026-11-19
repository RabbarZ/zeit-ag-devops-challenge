locals {
  name_prefix    = "${var.resource_name_prefix}-${var.env_name}"
  vm_subnet_cidr = cidrsubnet(var.vnet_cidr, 1, 0)
  pg_subnet_cidr = cidrsubnet(var.vnet_cidr, 1, 1)
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.name_prefix}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "vm" {
  name                 = "vm-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.vm_subnet_cidr]
}

resource "azurerm_network_security_group" "this" {
  name                = "${local.name_prefix}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = var.nsg_inbound_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = security_rule.value.name == "DenyAllInbound" ? "Deny" : "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.port
      source_address_prefix      = security_rule.value.source
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet" "pg" {
  count                = var.enable_pg_subnet ? 1 : 0
  name                 = "pg-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.pg_subnet_cidr]

  delegation {
    name = "pg-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# VNet-integrated PostgreSQL resolves names below "<env>.postgres.database.azure.com".
resource "azurerm_private_dns_zone" "pg" {
  count               = var.enable_pg_subnet ? 1 : 0
  name                = "${local.name_prefix}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
  count                 = var.enable_pg_subnet ? 1 : 0
  name                  = "pg-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.pg[0].name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_virtual_network_peering" "to_peer" {
  for_each = var.peer_vnet_ids

  name                         = "peer-to-${each.key}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = each.value
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
