resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "${var.prefix}-pg"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgres_version
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  public_network_access_enabled = false

  administrator_login    = var.database_user
  administrator_password = var.password

  storage_mb = 32768
  sku_name   = var.sku_name

  backup_retention_days = 7

  zone = "1"

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "materialize" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
}
