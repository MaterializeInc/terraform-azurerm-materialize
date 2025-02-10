<!-- BEGIN_TF_DOCS -->
# Materialize on Azure

Terraform module for deploying Materialize on Azure with all required infrastructure components.

This module sets up:
- AKS cluster for Materialize workloads
- Azure Database for PostgreSQL Flexible Server for metadata storage
- Azure Blob Storage for persistence
- Required networking and security configurations
- Managed identities with proper RBAC permissions

> **Warning** This is provided on a best-effort basis and Materialize cannot offer support for this module.

The module has been tested with:
- AKS version 1.28
- PostgreSQL 15
- Materialize Operator v0.1.0

## Setup Notes:
This module requires active azure credentials in your environment either setup through keys in the environment variable or through
`az login` with azure's CLI.

This module also runs an python script to generate Azure SAS tokens for the storage account. This requires python 3.12 or greater. Dependencies
for the script can be found in the `requirements.txt` file.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.45.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.75.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aks"></a> [aks](#module\_aks) | ./modules/aks | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_operator"></a> [operator](#module\_operator) | github.com/MaterializeInc/terraform-helm-materialize | v0.1.1 |
| <a name="module_storage"></a> [storage](#module\_storage) | ./modules/storage | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_config"></a> [aks\_config](#input\_aks\_config) | AKS cluster configuration | <pre>object({<br/>    vm_size      = string<br/>    disk_size_gb = number<br/>    min_nodes    = number<br/>    max_nodes    = number<br/>  })</pre> | <pre>{<br/>  "disk_size_gb": 100,<br/>  "max_nodes": 5,<br/>  "min_nodes": 1,<br/>  "vm_size": "Standard_D4s_v3"<br/>}</pre> | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Azure Database for PostgreSQL configuration | <pre>object({<br/>    sku_name         = optional(string, "GP_Standard_D2s_v3")<br/>    postgres_version = optional(string, "15")<br/>    password         = string<br/>    username         = optional(string, "materialize")<br/>    db_name          = optional(string, "materialize")<br/>  })</pre> | n/a | yes |
| <a name="input_helm_values"></a> [helm\_values](#input\_helm\_values) | Additional Helm values to merge with defaults | `any` | `{}` | no |
| <a name="input_install_materialize_operator"></a> [install\_materialize\_operator](#input\_install\_materialize\_operator) | Whether to install the Materialize operator | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | The location where resources will be created | `string` | `"eastus2"` | no |
| <a name="input_materialize_instances"></a> [materialize\_instances](#input\_materialize\_instances) | Configuration for Materialize instances | <pre>list(object({<br/>    name                 = string<br/>    namespace            = optional(string)<br/>    database_name        = string<br/>    environmentd_version = optional(string, "v0.130.1")<br/>    cpu_request          = optional(string, "1")<br/>    memory_request       = optional(string, "1Gi")<br/>    memory_limit         = optional(string, "1Gi")<br/>    create_database      = optional(bool, true)<br/>    in_place_rollout     = optional(bool, false)<br/>    request_rollout      = optional(string)<br/>    force_rollout        = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for all resources, usually the organization or project name | `string` | `"materialize"` | no |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | Network configuration for the AKS cluster | <pre>object({<br/>    vnet_address_space = string<br/>    subnet_cidr        = string<br/>    service_cidr       = string<br/>  })</pre> | <pre>{<br/>  "docker_bridge_cidr": "172.17.0.1/16",<br/>  "service_cidr": "10.1.0.0/16",<br/>  "subnet_cidr": "10.0.0.0/20",<br/>  "vnet_address_space": "10.0.0.0/16"<br/>}</pre> | no |
| <a name="input_operator_namespace"></a> [operator\_namespace](#input\_operator\_namespace) | Namespace for the Materialize operator | `string` | `"materialize"` | no |
| <a name="input_operator_version"></a> [operator\_version](#input\_operator\_version) | Version of the Materialize operator to install | `string` | `"v25.1.0"` | no |
| <a name="input_orchestratord_version"></a> [orchestratord\_version](#input\_orchestratord\_version) | Version of the Materialize orchestrator to install | `string` | `"v0.130.1"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix to be used for resource names | `string` | `"materialize"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aks_cluster"></a> [aks\_cluster](#output\_aks\_cluster) | AKS cluster details |
| <a name="output_connection_strings"></a> [connection\_strings](#output\_connection\_strings) | Formatted connection strings for Materialize |
| <a name="output_database"></a> [database](#output\_database) | Azure Database for PostgreSQL details |
| <a name="output_identities"></a> [identities](#output\_identities) | Managed Identity details |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | The kube\_config for the AKS cluster |
| <a name="output_storage"></a> [storage](#output\_storage) | Azure Storage Account details |
<!-- END_TF_DOCS -->
