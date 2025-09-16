locals {
  nodepool_name = substr(replace(var.prefix, "-", ""), 0, 12)
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${var.prefix}-aks-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "aks_network_contributer" {
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}/subnets/${var.subnet_name}"
  role_definition_name = "Network Contributor"
  principal_id         = resource.azurerm_user_assigned_identity.aks_identity.principal_id
}

resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "${var.prefix}-workload-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "${var.prefix}-aks"

  default_node_pool {
    temporary_name_for_rotation = "default2"
    name                        = "default"
    vm_size                     = "Standard_D2s_v3"
    node_count                  = 1
    vnet_subnet_id              = var.subnet_id

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = var.service_cidr
    dns_service_ip = cidrhost(var.service_cidr, 10)
  }

  tags = var.tags

  depends_on = [
    resource.azurerm_role_assignment.aks_network_contributer,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "materialize" {
  name                        = local.nodepool_name
  temporary_name_for_rotation = "${local.nodepool_name}2"
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.aks.id
  vm_size                     = var.vm_size
  auto_scaling_enabled        = true
  min_count                   = var.min_nodes
  max_count                   = var.max_nodes
  vnet_subnet_id              = var.subnet_id
  os_disk_size_gb             = var.disk_size_gb

  node_labels = {
    "materialize.cloud/disk"                 = var.enable_disk_setup ? "true" : "false"
    "materialize.cloud/scratch-fs"           = var.enable_disk_setup ? "true" : "false"
    "workload"                               = "materialize-instance"
    "materialize.cloud/disk-config-required" = var.enable_disk_setup ? "true" : "false"
  }

  # Taints can not be removed: https://github.com/Azure/AKS/issues/2934
  # node_taints = var.enable_disk_setup ? ["materialize.cloud/disk-unconfigured=true:NoSchedule"] : []

  tags = var.tags
}

resource "kubernetes_namespace" "openebs" {
  count = var.install_openebs ? 1 : 0

  metadata {
    name = var.openebs_namespace
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "helm_release" "openebs" {
  count = var.install_openebs ? 1 : 0

  name       = "openebs"
  namespace  = kubernetes_namespace.openebs[0].metadata[0].name
  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = var.openebs_version

  set {
    name  = "engines.replicated.mayastor.enabled"
    value = "false"
  }

  set {
    name  = "openebs-crds.csi.volumeSnapshots.enabled"
    value = "false"
  }

  depends_on = [
    kubernetes_namespace.openebs
  ]
}

resource "kubernetes_namespace" "disk_setup" {
  count = var.enable_disk_setup ? 1 : 0

  metadata {
    name = "disk-setup"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "materialize"
    }
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "kubernetes_daemonset" "disk_setup" {
  count = var.enable_disk_setup ? 1 : 0

  metadata {
    name      = "disk-setup"
    namespace = kubernetes_namespace.disk_setup[0].metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "materialize"
      "app"                          = "disk-setup"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "disk-setup"
      }
    }

    template {
      metadata {
        labels = {
          app = "disk-setup"
        }
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
                  key      = "materialize.cloud/disk"
                  operator = "In"
                  values   = ["true"]
                }
              }
            }
          }
        }

        toleration {
          key      = "materialize.cloud/disk-unconfigured"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        # Use host network and PID namespace
        host_network = true
        host_pid     = true

        init_container {
          name    = "disk-setup"
          image   = var.disk_setup_image
          command = ["ephemeral-storage-setup"]
          args = [
            "lvm",
            "--cloud-provider",
            "azure",
            # Taints can not be removed: https://github.com/Azure/AKS/issues/2934
            #"--remove-taint",
          ]
          resources {
            limits = {
              memory = "128Mi"
            }
            requests = {
              memory = "128Mi"
              cpu    = "50m"
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
              memory = "8Mi"
            }
            requests = {
              memory = "8Mi"
              cpu    = "1m"
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
  count = var.enable_disk_setup ? 1 : 0
  metadata {
    name      = "disk-setup"
    namespace = kubernetes_namespace.disk_setup[0].metadata[0].name
  }
}

resource "kubernetes_cluster_role" "disk_setup" {
  count = var.enable_disk_setup ? 1 : 0
  metadata {
    name = "disk-setup"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "patch", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "disk_setup" {
  count = var.enable_disk_setup ? 1 : 0
  metadata {
    name = "disk-setup"
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
