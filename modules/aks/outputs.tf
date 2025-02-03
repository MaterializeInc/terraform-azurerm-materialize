
output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_endpoint" {
  description = "The endpoint of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.location
}

output "vnet_id" {
  description = "The ID of the VNet"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = azurerm_subnet.aks.id
}

output "cluster_identity" {
  description = "The identity of the AKS cluster"
  value       = azurerm_user_assigned_identity.aks_identity.principal_id
}

output "workload_identity" {
  description = "The workload identity"
  value       = azurerm_user_assigned_identity.workload_identity.principal_id
}

output "workload_identity_principal_id" {
  description = "The principal ID of the workload identity"
  value       = azurerm_user_assigned_identity.workload_identity.principal_id
}

output "kube_config" {
  description = "The kube_config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "The kube_config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
