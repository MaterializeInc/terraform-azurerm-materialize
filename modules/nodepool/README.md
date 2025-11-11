## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster_node_pool.primary_nodes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [kubernetes_cluster_role.disk_setup](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.disk_setup](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_daemonset.disk_setup](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/daemonset) | resource |
| [kubernetes_namespace.disk_setup](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.disk_setup](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscaling_config"></a> [autoscaling\_config](#input\_autoscaling\_config) | Auto-scaling configuration for the node pool | <pre>object({<br/>    enabled    = bool<br/>    min_nodes  = optional(number)<br/>    max_nodes  = optional(number)<br/>    node_count = optional(number)<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "max_nodes": 10,<br/>  "min_nodes": 1,<br/>  "node_count": null<br/>}</pre> | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the AKS cluster | `string` | n/a | yes |
| <a name="input_disk_setup_container_resource_config"></a> [disk\_setup\_container\_resource\_config](#input\_disk\_setup\_container\_resource\_config) | Resource configuration for disk setup init container | <pre>object({<br/>    memory_limit   = string<br/>    memory_request = string<br/>    cpu_request    = string<br/>  })</pre> | <pre>{<br/>  "cpu_request": "50m",<br/>  "memory_limit": "128Mi",<br/>  "memory_request": "128Mi"<br/>}</pre> | no |
| <a name="input_disk_setup_image"></a> [disk\_setup\_image](#input\_disk\_setup\_image) | Docker image for the disk setup script | `string` | `"materialize/ephemeral-storage-setup-image:v0.4.0"` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Size of the disk attached to each node | `number` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to Kubernetes resources | `map(string)` | `{}` | no |
| <a name="input_node_taints"></a> [node\_taints](#input\_node\_taints) | Taints to apply to the node pool. Note: Once applied via Terraform, these taints cannot be manually removed by users due to AKS webhook restrictions. | <pre>list(object({<br/>    key    = string<br/>    value  = string<br/>    effect = string<br/>  }))</pre> | `[]` | no |
| <a name="input_pause_container_resource_config"></a> [pause\_container\_resource\_config](#input\_pause\_container\_resource\_config) | Resource configuration for pause container | <pre>object({<br/>    memory_limit   = string<br/>    memory_request = string<br/>    cpu_request    = string<br/>  })</pre> | <pre>{<br/>  "cpu_request": "1m",<br/>  "memory_limit": "8Mi",<br/>  "memory_request": "8Mi"<br/>}</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix to be used for resource names | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The ID of the subnet | `string` | n/a | yes |
| <a name="input_swap_enabled"></a> [swap\_enabled](#input\_swap\_enabled) | Whether to enable swap on the local NVMe disks. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | VM size for AKS nodes | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nodepool_id"></a> [nodepool\_id](#output\_nodepool\_id) | The ID of the node pool |
| <a name="output_nodepool_max_count"></a> [nodepool\_max\_count](#output\_nodepool\_max\_count) | The maximum count of nodes in the node pool |
| <a name="output_nodepool_min_count"></a> [nodepool\_min\_count](#output\_nodepool\_min\_count) | The minimum count of nodes in the node pool |
| <a name="output_nodepool_name"></a> [nodepool\_name](#output\_nodepool\_name) | The name of the node pool |
| <a name="output_nodepool_vm_size"></a> [nodepool\_vm\_size](#output\_nodepool\_vm\_size) | The VM size of the node pool |
