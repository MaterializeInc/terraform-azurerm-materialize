resource "kubernetes_service" "console_load_balancer" {
  metadata {
    name      = "mz${var.resource_id}-console-lb"
    namespace = var.namespace
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-internal" = var.internal ? "true" : "false"
    }
  }

  spec {
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
    selector = {
      "materialize.cloud/name" = "mz${var.resource_id}-console"
    }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }

  wait_for_load_balancer = true
}

resource "kubernetes_service" "balancerd_load_balancer" {
  metadata {
    name      = "mz${var.resource_id}-balancerd-lb"
    namespace = var.namespace
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-internal" = var.internal ? "true" : "false"
    }
  }

  spec {
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
    selector = {
      "materialize.cloud/name" = "mz${var.resource_id}-balancerd"
    }
    port {
      name        = "sql"
      port        = 6875
      target_port = 6875
      protocol    = "TCP"
    }
    port {
      name        = "https"
      port        = 6876
      target_port = 6876
      protocol    = "TCP"
    }
  }

  wait_for_load_balancer = true
}
