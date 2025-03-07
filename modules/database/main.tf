resource "azurerm_subnet" "postgres" {
  name                 = "${var.prefix}-pg-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(data.azurerm_virtual_network.vnet.address_space[0], 4, 1)]

  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "postgres-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "random_id" "dns_zone_suffix" {
  byte_length = 4
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "materialize${random_id.dns_zone_suffix.hex}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.prefix}-pg-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
  registration_enabled  = true
  tags                  = var.tags
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "${var.prefix}-pg"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgres_version
  delegated_subnet_id = azurerm_subnet.postgres.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  public_network_access_enabled = false

  administrator_login    = var.database_user
  administrator_password = var.password

  storage_mb = 32768
  sku_name   = var.sku_name

  backup_retention_days = 7

  zone = "1"

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "materialize" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
}

data "azurerm_virtual_network" "vnet" {
  name                = split("/", var.vnet_id)[8]
  resource_group_name = var.resource_group_name
}
