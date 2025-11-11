locals {
  # Azure has 12-character limit for node pool names
  nodepool_name = substr(replace(var.prefix, "-", ""), 0, 12)

  # Auto-scaling configuration - prioritize autoscaling_config object over individual variables
  auto_scaling_enabled = var.autoscaling_config.enabled
  min_nodes            = var.autoscaling_config.enabled ? var.autoscaling_config.min_nodes : null
  max_nodes            = var.autoscaling_config.enabled ? var.autoscaling_config.max_nodes : null
  node_count           = !var.autoscaling_config.enabled ? var.autoscaling_config.node_count : null

  node_labels = merge(
    var.labels,
    var.swap_enabled ? {
      "materialize.cloud/swap" = "true"
    } : {}
  )

  disk_setup_name = "disk-setup"

  disk_setup_labels = merge(
    var.labels,
    {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "materialize"
      "app"                          = local.disk_setup_name
    }
  )
}


resource "azurerm_kubernetes_cluster_node_pool" "primary_nodes" {
  name                        = local.nodepool_name
  temporary_name_for_rotation = "${substr(local.nodepool_name, 0, 9)}tmp"
  kubernetes_cluster_id       = var.cluster_id
  vm_size                     = var.vm_size
  auto_scaling_enabled        = local.auto_scaling_enabled
  min_count                   = local.min_nodes
  max_count                   = local.max_nodes
  node_count                  = local.node_count
  vnet_subnet_id              = var.subnet_id
  os_disk_size_gb             = var.disk_size_gb

  node_labels = local.node_labels

  # Apply taints if specified
  # Note: Once applied, these taints cannot be manually removed by users due to AKS webhook restrictions
  # Reference: https://github.com/Azure/AKS/issues/2934
  node_taints = [
    for taint in var.node_taints : "${taint.key}=${taint.value}:${taint.effect}"
  ]

  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 0
    node_soak_duration_in_minutes = 0
  }
  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "kubernetes_namespace" "disk_setup" {
  count = var.swap_enabled ? 1 : 0

  metadata {
    name   = local.disk_setup_name
    labels = local.disk_setup_labels
  }

}

resource "kubernetes_daemonset" "disk_setup" {
  count = var.swap_enabled ? 1 : 0

  depends_on = [
    kubernetes_namespace.disk_setup,
    azurerm_kubernetes_cluster_node_pool.primary_nodes
  ]

  metadata {
    name      = local.disk_setup_name
    namespace = kubernetes_namespace.disk_setup[0].metadata[0].name
    labels    = local.disk_setup_labels
  }

  spec {
    selector {
      match_labels = {
        app = local.disk_setup_name
      }
    }

    template {
      metadata {
        labels = local.disk_setup_labels
      }

      spec {
        security_context {
          run_as_non_root = false
          run_as_user     = 0
          fs_group        = 0
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "materialize.cloud/swap"
                  operator = "In"
                  values   = ["true"]
                }
              }
            }
          }
        }

        # Tolerate all taints (includes both user-provided and swap taints)
        dynamic "toleration" {
          for_each = var.node_taints
          content {
            key      = toleration.value.key
            operator = "Exists"
            effect   = toleration.value.effect
          }
        }

        # Use host network and PID namespace
        host_network = true
        host_pid     = true

        init_container {
          name    = local.disk_setup_name
          image   = var.disk_setup_image
          command = ["ephemeral-storage-setup"]
          args = [
            "swap",
            "--cloud-provider",
            "azure",
            "--hack-restart-kubelet-enable-swap",
            "--apply-sysctls",
            # Taints can not be removed: https://github.com/Azure/AKS/issues/2934
            #"--remove-taint",
            #"--taint-key",
            #local.node_taints[0].key,
          ]
          resources {
            limits = {
              memory = var.disk_setup_container_resource_config.memory_limit
            }
            requests = {
              memory = var.disk_setup_container_resource_config.memory_request
              cpu    = var.disk_setup_container_resource_config.cpu_request
            }
          }

          security_context {
            privileged  = true
            run_as_user = 0
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          volume_mount {
            name       = "dev"
            mount_path = "/dev"
          }

          volume_mount {
            name       = "host-root"
            mount_path = "/host"
          }
        }

        container {
          name    = "pause"
          image   = var.disk_setup_image
          command = ["ephemeral-storage-setup"]
          args    = ["sleep"]
          resources {
            limits = {
              memory = var.pause_container_resource_config.memory_limit
            }
            requests = {
              memory = var.pause_container_resource_config.memory_request
              cpu    = var.pause_container_resource_config.cpu_request
            }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 65534
          }
        }

        volume {
          name = "dev"
          host_path {
            path = "/dev"
          }
        }

        volume {
          name = "host-root"
          host_path {
            path = "/"
          }
        }

        service_account_name = kubernetes_service_account.disk_setup[0].metadata[0].name
      }
    }
  }
}

resource "kubernetes_service_account" "disk_setup" {
  count = var.swap_enabled ? 1 : 0

  depends_on = [
    kubernetes_namespace.disk_setup,
  ]

  metadata {
    name      = local.disk_setup_name
    namespace = kubernetes_namespace.disk_setup[0].metadata[0].name
  }
}

resource "kubernetes_cluster_role" "disk_setup" {
  count = var.swap_enabled ? 1 : 0

  metadata {
    name = local.disk_setup_name
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "patch", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "disk_setup" {
  count = var.swap_enabled ? 1 : 0

  depends_on = [
    kubernetes_namespace.disk_setup,
    kubernetes_cluster_role.disk_setup,
    kubernetes_service_account.disk_setup,
  ]

  metadata {
    name = local.disk_setup_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.disk_setup[0].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.disk_setup[0].metadata[0].name
    namespace = kubernetes_namespace.disk_setup[0].metadata[0].name
  }
}
