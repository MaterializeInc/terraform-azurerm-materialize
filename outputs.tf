
output "aks_cluster" {
  description = "AKS cluster details"
  value = {
    name     = module.aks.cluster_name
    endpoint = module.aks.cluster_endpoint
    location = module.aks.cluster_location
  }
  sensitive = true
}

output "database" {
  description = "Azure Database for PostgreSQL details"
  value = {
    name           = module.database.server_name
    connection_url = module.database.connection_url
    private_ip     = module.database.private_ip
  }
  sensitive = true
}

output "storage" {
  description = "Azure Storage Account details"
  value = {
    name           = module.storage.storage_account_name
    blob_endpoint  = module.storage.primary_blob_endpoint
    container_name = module.storage.container_name
  }
}

output "identities" {
  description = "Managed Identity details"
  value = {
    aks_identity      = module.aks.cluster_identity
    workload_identity = module.aks.workload_identity
  }
}

locals {
  metadata_backend_url = format(
    "postgres://%s:%s@%s:5432/%s?sslmode=verify-full",
    var.database_config.username,
    var.database_config.password,
    module.database.private_ip,
    var.database_config.db_name
  )

  persist_backend_url = format(
    "azblob://%s/%s?account=%s&container=%s",
    module.storage.storage_account_key,
    module.storage.container_name,
    module.storage.storage_account_name,
    module.storage.container_name
  )
}

output "connection_strings" {
  description = "Formatted connection strings for Materialize"
  value = {
    metadata_backend_url = local.metadata_backend_url
    persist_backend_url  = local.persist_backend_url
  }
  sensitive = true
}
