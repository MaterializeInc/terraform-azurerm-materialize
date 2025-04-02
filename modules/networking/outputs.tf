output "vnet_id" {
  description = "The ID of the VNet"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the VNet"
  value       = azurerm_virtual_network.vnet.name
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "The name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "postgres_subnet_id" {
  description = "The ID of the PostgreSQL subnet"
  value       = azurerm_subnet.postgres.id
}

output "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  value       = azurerm_private_dns_zone.postgres.id
}

output "vnet_address_space" {
  description = "The address space of the VNet"
  value       = var.vnet_address_space
}
