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
  service_cidr        = var.network_config.service_cidr

  vm_size      = var.aks_config.vm_size
  disk_size_gb = var.aks_config.disk_size_gb
  min_nodes    = var.aks_config.min_nodes
  max_nodes    = var.aks_config.max_nodes

  tags = local.common_labels
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

// TODO we should be generating one storage container per materialize_instance
module "storage" {
  source = "./modules/storage"

  resource_group_name   = var.resource_group_name
  location              = var.location
  prefix                = var.prefix
  identity_principal_id = module.aks.workload_identity_principal_id
  subnets               = [module.aks.subnet_id]

  tags = local.common_labels

  # This seems to help us get through some timing 
  # issues that required multiple deploys, but truly
  # shouldn't be needed.
  depends_on = [module.aks.subnet_id]
}

locals {
  default_helm_values = {
    operator = {
      image = {
        tag = var.orchestratord_version
      }
      cloudProvider = {
        type   = "azure"
        region = var.location
      }
    }
    observability = {
      podMetrics = {
        enabled = true
      }
    }
  }

  merged_helm_values = merge(local.default_helm_values, var.helm_values)

  instances = [
    for instance in var.materialize_instances : {
      name                 = instance.name
      namespace            = instance.namespace
      database_name        = instance.database_name
      environmentd_version = instance.environmentd_version

      metadata_backend_url = format(
        "postgres://%s@%s/%s?sslmode=require",
        "${var.database_config.username}:${var.database_config.password}",
        module.database.database_host,
        coalesce(instance.database_name, instance.name)
      )

      // the endpoint by default ends in `/` we want to remove that
      # persist_backend_url = substr(module.storage.primary_blob_endpoint, 0, length(module.storage.primary_blob_endpoint) - 1)
      persist_backend_url = format(
        "%s%s?%s",
        module.storage.primary_blob_endpoint,
        module.storage.container_name,
        module.storage.primary_blob_sas_token
      )

      cpu_request      = instance.cpu_request
      memory_request   = instance.memory_request
      memory_limit     = instance.memory_limit
      create_database  = instance.create_database
      in_place_rollout = instance.in_place_rollout
      request_rollout  = instance.request_rollout
      force_rollout    = instance.force_rollout
    }
  ]
}

module "operator" {
  source = "github.com/MaterializeInc/terraform-helm-materialize?ref=v0.1.5"

  count = var.install_materialize_operator ? 1 : 0

  depends_on = [
    module.aks,
    module.database,
    module.storage
  ]

  namespace          = var.namespace
  environment        = var.prefix
  operator_version   = var.operator_version
  operator_namespace = var.operator_namespace

  # The metrics server already exists in the AKS cluster
  install_metrics_server = false

  helm_values = local.merged_helm_values
  instances   = local.instances

  // For development purposes, you can use a local Helm chart instead of fetching it from the Helm repository
  use_local_chart = var.use_local_chart
  helm_chart      = var.helm_chart

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}
