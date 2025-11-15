locals {
  common_labels = merge(var.tags, {
    managed_by = "terraform"
    module     = "materialize"
  })

  # Disk support configuration
  disk_config = {
    install_openebs           = var.enable_disk_support ? lookup(var.disk_support_config, "install_openebs", true) : false
    run_disk_setup_script     = var.enable_disk_support ? lookup(var.disk_support_config, "run_disk_setup_script", true) : false
    create_storage_class      = var.enable_disk_support ? lookup(var.disk_support_config, "create_storage_class", true) : false
    openebs_version           = lookup(var.disk_support_config, "openebs_version", "4.3.3")
    openebs_namespace         = lookup(var.disk_support_config, "openebs_namespace", "openebs")
    storage_class_name        = lookup(var.disk_support_config, "storage_class_name", "openebs-lvm-instance-store-ext4")
    storage_class_provisioner = "local.csi.openebs.io"
    storage_class_parameters = {
      storage  = "lvm"
      fsType   = "ext4"
      volgroup = "instance-store-vg"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  resource_group_name  = var.resource_group_name
  location             = var.location
  prefix               = var.prefix
  vnet_address_space   = var.network_config.vnet_address_space
  subnet_cidr          = var.network_config.subnet_cidr
  postgres_subnet_cidr = var.network_config.postgres_subnet_cidr

  tags = local.common_labels
}

module "aks" {
  source = "./modules/aks"

  depends_on = [module.networking]

  resource_group_name = var.resource_group_name
  location            = var.location
  prefix              = var.prefix
  vnet_name           = module.networking.vnet_name
  subnet_name         = module.networking.aks_subnet_name
  subnet_id           = module.networking.aks_subnet_id
  service_cidr        = var.network_config.service_cidr

  vm_size      = var.aks_config.vm_size
  disk_size_gb = var.aks_config.disk_size_gb
  min_nodes    = var.aks_config.min_nodes
  max_nodes    = var.aks_config.max_nodes

  # Disk support configuration
  enable_disk_setup = local.disk_config.run_disk_setup_script
  install_openebs   = local.disk_config.install_openebs
  openebs_namespace = local.disk_config.openebs_namespace
  openebs_version   = local.disk_config.openebs_version
  disk_setup_image  = var.disk_setup_image

  tags = local.common_labels
}

module "swap_nodepool" {
  count      = var.swap_enabled ? 1 : 0
  source     = "./modules/nodepool"
  depends_on = [module.aks]

  prefix     = "${var.prefix}-mz-swap"
  cluster_id = module.aks.cluster_id
  subnet_id  = module.networking.aks_subnet_id

  vm_size      = var.aks_config.vm_size
  disk_size_gb = var.aks_config.disk_size_gb

  autoscaling_config = {
    enabled   = true
    min_nodes = var.aks_config.min_nodes
    max_nodes = var.aks_config.max_nodes
  }

  swap_enabled     = true
  disk_setup_image = var.disk_setup_image

  labels = local.common_labels
  tags   = local.common_labels
}

module "database" {
  source = "./modules/database"

  depends_on = [module.networking]

  database_name       = var.database_config.db_name
  database_user       = var.database_config.username
  resource_group_name = var.resource_group_name
  location            = var.location
  prefix              = var.prefix
  subnet_id           = module.networking.postgres_subnet_id
  private_dns_zone_id = module.networking.private_dns_zone_id

  sku_name         = var.database_config.sku_name
  postgres_version = var.database_config.postgres_version
  password         = var.database_config.password

  tags = local.common_labels
}

// TODO we should be generating one storage container per materialize_instance
module "storage" {
  source = "./modules/storage"

  depends_on = [module.aks, module.networking]

  resource_group_name   = var.resource_group_name
  location              = var.location
  prefix                = var.prefix
  identity_principal_id = module.aks.workload_identity_principal_id
  subnets               = [module.networking.aks_subnet_id]

  tags = local.common_labels
}

module "certificates" {
  source = "./modules/certificates"

  install_cert_manager           = var.install_cert_manager
  cert_manager_install_timeout   = var.cert_manager_install_timeout
  cert_manager_chart_version     = var.cert_manager_chart_version
  use_self_signed_cluster_issuer = var.use_self_signed_cluster_issuer && length(var.materialize_instances) > 0
  cert_manager_namespace         = var.cert_manager_namespace
  name_prefix                    = var.prefix

  depends_on = [
    module.aks,
  ]
}

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
      clusters = {
        swap_enabled = var.swap_enabled
      }
    }
    observability = {
      podMetrics = {
        enabled = true
      }
    }
    tls = (var.use_self_signed_cluster_issuer && length(var.materialize_instances) > 0) ? {
      defaultCertificateSpecs = {
        balancerdExternal = {
          dnsNames = [
            "balancerd",
          ]
          issuerRef = {
            name = module.certificates.cluster_issuer_name
            kind = "ClusterIssuer"
          }
        }
        consoleExternal = {
          dnsNames = [
            "console",
          ]
          issuerRef = {
            name = module.certificates.cluster_issuer_name
            kind = "ClusterIssuer"
          }
        }
        internal = {
          issuerRef = {
            name = module.certificates.cluster_issuer_name
            kind = "ClusterIssuer"
          }
        }
      }
    } : {}
    storage = var.enable_disk_support ? {
      storageClass = {
        create      = local.disk_config.create_storage_class
        name        = local.disk_config.storage_class_name
        provisioner = local.disk_config.storage_class_provisioner
        parameters  = local.disk_config.storage_class_parameters
      }
    } : {}
  }

  merged_helm_values = provider::deepmerge::mergo(local.default_helm_values, var.helm_values)

  instances = [
    for instance in var.materialize_instances : {
      name                 = instance.name
      namespace            = instance.namespace
      database_name        = instance.database_name
      environmentd_version = instance.environmentd_version

      environmentd_extra_args = instance.environmentd_extra_args

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

      license_key = instance.license_key

      authenticator_kind = instance.authenticator_kind

      external_login_password_mz_system = instance.external_login_password_mz_system != null ? instance.external_login_password_mz_system : null

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
  source = "github.com/MaterializeInc/terraform-helm-materialize?ref=v0.1.32"

  count = var.install_materialize_operator ? 1 : 0

  depends_on = [
    module.aks,
    module.swap_nodepool,
    module.database,
    module.storage,
    module.certificates,
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

module "load_balancers" {
  source = "./modules/load_balancers"

  for_each = { for idx, instance in local.instances : instance.name => instance if lookup(instance, "create_load_balancer", false) }

  instance_name = each.value.name
  namespace     = module.operator[0].materialize_instances[each.value.name].namespace
  resource_id   = module.operator[0].materialize_instance_resource_ids[each.value.name]
  internal      = each.value.internal_load_balancer

  depends_on = [
    module.operator,
    module.aks,
  ]
}
