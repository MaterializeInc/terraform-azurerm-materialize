locals {
  common_labels = merge(var.tags, {
    managed_by = "terraform"
    module     = "materialize"
  })
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = var.resource_group_name
  location            = var.location
  prefix              = var.prefix
  vnet_address_space  = var.network_config.vnet_address_space
  subnet_cidr         = var.network_config.subnet_cidr

  node_count   = var.aks_config.node_count
  vm_size      = var.aks_config.vm_size
  disk_size_gb = var.aks_config.disk_size_gb
  min_nodes    = var.aks_config.min_nodes
  max_nodes    = var.aks_config.max_nodes

  namespace = var.namespace
  tags      = local.common_labels
}

module "database" {
  source = "./modules/database"

  depends_on = [module.aks]

  database_name       = var.database_config.db_name
  database_user       = var.database_config.username
  resource_group_name = var.resource_group_name
  location            = var.location
  prefix              = var.prefix
  vnet_id             = module.aks.vnet_id

  sku_name         = var.database_config.sku_name
  postgres_version = var.database_config.postgres_version
  password         = var.database_config.password

  tags = local.common_labels
}

module "storage" {
  source = "./modules/storage"

  resource_group_name   = var.resource_group_name
  location              = var.location
  prefix                = var.prefix
  identity_principal_id = module.aks.workload_identity_principal_id

  tags = local.common_labels
}
