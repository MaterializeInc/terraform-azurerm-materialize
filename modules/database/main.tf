resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "${var.prefix}-${random_string.postgres_name_suffix.result}-pg"
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

  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "materialize" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
}

resource "random_string" "postgres_name_suffix" {
  length  = 4
  special = false
  upper   = false
}
