output "nodepool_name" {
  description = "The name of the node pool"
  value       = azurerm_kubernetes_cluster_node_pool.primary_nodes.name
}

output "nodepool_id" {
  description = "The ID of the node pool"
  value       = azurerm_kubernetes_cluster_node_pool.primary_nodes.id
}

output "nodepool_vm_size" {
  description = "The VM size of the node pool"
  value       = azurerm_kubernetes_cluster_node_pool.primary_nodes.vm_size
}

output "nodepool_min_count" {
  description = "The minimum count of nodes in the node pool"
  value       = azurerm_kubernetes_cluster_node_pool.primary_nodes.min_count
}

output "nodepool_max_count" {
  description = "The maximum count of nodes in the node pool"
  value       = azurerm_kubernetes_cluster_node_pool.primary_nodes.max_count
}
