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

output "network" {
  description = "Network details"
  value = {
    vnet_id       = module.networking.vnet_id
    vnet_name     = module.networking.vnet_name
    aks_subnet_id = module.networking.aks_subnet_id
    pg_subnet_id  = module.networking.postgres_subnet_id
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
    "postgres://%s:%s@%s:5432/%s?sslmode=require",
    var.database_config.username,
    var.database_config.password,
    module.database.private_ip,
    var.database_config.db_name
  )

  persist_backend_url = format(
    "%s%s?%s",
    module.storage.primary_blob_endpoint,
    module.storage.container_name,
    module.storage.primary_blob_sas_token
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

output "kube_config" {
  description = "The kube_config for the AKS cluster"
  value       = module.aks.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "The kube_config for the AKS cluster"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "load_balancer_details" {
  description = "Details of the Materialize instance load balancers."
  value = {
    for load_balancer in module.load_balancers : load_balancer.instance_name => {
      console_load_balancer_ip   = load_balancer.console_load_balancer_ip
      balancerd_load_balancer_ip = load_balancer.balancerd_load_balancer_ip
    }
  }
}

output "operator" {
  description = "Materialize operator details"
  value = var.install_materialize_operator ? {
    namespace             = module.operator[0].operator_namespace
    release_name          = module.operator[0].operator_release_name
    release_status        = module.operator[0].operator_release_status
    instances             = module.operator[0].materialize_instances
    instance_resource_ids = module.operator[0].materialize_instance_resource_ids
  } : null
}
