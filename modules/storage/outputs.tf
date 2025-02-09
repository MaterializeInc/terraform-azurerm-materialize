output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.materialize.name
}

output "storage_account_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.materialize.primary_access_key
  sensitive   = true
}

output "container_name" {
  description = "The name of the storage container"
  value       = azurerm_storage_container.materialize.name
}

output "primary_blob_endpoint" {
  description = "The primary blob endpoint"
  value       = azurerm_storage_account.materialize.primary_blob_endpoint
}

output "primary_blob_sas_token" {
  description = "access key to the storage account"
  value       = data.external.sas_token.result.sas_token
  sensitive   = true
}

