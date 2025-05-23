locals {
  default_helm_values = {
    operator = {
      image = var.orchestratord_version == null ? {} : {
        tag = var.orchestratord_version
      },
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
        var.database_config.host,
        var.database_config.db_name
      )

      // the endpoint by default ends in `/` we want to remove that
      # persist_backend_url = substr(module.storage.primary_blob_endpoint, 0, length(module.storage.primary_blob_endpoint) - 1)
      persist_backend_url = format(
        "%s%s?%s",
        var.storage_config.primary_blob_endpoint,
        var.storage_config.container_name,
        var.storage_config.primary_blob_sas_token
      )

      license_key = instance.license_key

      create_load_balancer   = instance.create_load_balancer
      internal_load_balancer = instance.internal_load_balancer

      cpu_request      = instance.cpu_request
      memory_request   = instance.memory_request
      memory_limit     = instance.memory_limit
      create_database  = instance.create_database
      in_place_rollout = instance.in_place_rollout
      request_rollout  = instance.request_rollout
      force_rollout    = instance.force_rollout

      balancer_cpu_request    = instance.balancer_cpu_request
      balancer_memory_request = instance.balancer_memory_request
      balancer_memory_limit   = instance.balancer_memory_limit
    }
  ]
}

module "operator" {
  source = "../terraform-helm-materialize/."

  count = var.install_materialize_operator ? 1 : 0

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

module "load_balancers" {
  source = "./modules/load_balancers"

  for_each = { for idx, instance in local.instances : instance.name => instance if lookup(instance, "create_load_balancer", false) }

  instance_name = each.value.name
  namespace     = module.operator[0].materialize_instances[each.value.name].namespace
  resource_id   = module.operator[0].materialize_instance_resource_ids[each.value.name]
  internal      = each.value.internal_load_balancer

  depends_on = [
    module.operator
  ]
}
