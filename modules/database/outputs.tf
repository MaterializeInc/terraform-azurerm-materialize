
output "server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.postgres.name
}

output "database_name" {
  description = "The name of the database"
  value       = azurerm_postgresql_flexible_server_database.materialize.name
}

output "private_ip" {
  description = "The private IP address of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "connection_url" {
  description = "The connection URL for the database"
  value = format(
    "postgres://%s:%s@%s/%s?sslmode=verify-full",
    var.database_user,
    var.password,
    azurerm_postgresql_flexible_server.postgres.fqdn,
    azurerm_postgresql_flexible_server_database.materialize.name
  )
  sensitive = true
}
