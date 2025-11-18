<!-- BEGIN_TF_DOCS -->
# Materialize on Azure

Terraform module for deploying Materialize on Azure with all required infrastructure components.

This module sets up:
- AKS cluster for Materialize workloads
- Azure Database for PostgreSQL Flexible Server for metadata storage
- Azure Blob Storage for persistence
- Required networking and security configurations
- Managed identities with proper RBAC permissions

> [!WARNING]
> This module is intended for demonstration/evaluation purposes as well as for serving as a template when building your own production deployment of Materialize.
>
> This module should not be directly relied upon for production deployments: **future releases of the module will contain breaking changes.** Instead, to use as a starting point for your own production deployment, either:
> - Fork this repo and pin to a specific version, or
> - Use the code as a reference when developing your own deployment.

The module has been tested with:
- AKS version 1.28
- PostgreSQL 15
- terraform-helm-materialize v0.1.12 (Materialize Operator v25.1.7)

## Setup Notes:

This module requires active Azure credentials in your environment, either set up through environment variables containing the required keys or by logging in with the Azure CLI using:

```sh
az login
```

You also need to set an Azure subscription ID in the `subscription_id` variable or set the `ARM_SUBSCRIPTION_ID` environment variable, eg:

```sh
export ARM_SUBSCRIPTION_ID="your-subscription-id"
```

Additionally, this module runs a Python script to generate Azure SAS tokens for the storage account. This requires **Python 3.12 or greater**.

### Installing Dependencies

Before running the module, ensure you have the necessary Python dependencies installed:

1. Install Python 3.12+ if you haven't already.
2. Install the required dependencies using `pip`:

    ```sh
    pip install -r requirements.txt
    ```

    Or alternatively, you can install the dependencies manually:

    ```sh
    pip install azure-identity azure-storage-blob azure-keyvault-secrets azure-mgmt-storage
    ```

If you are using a virtual environment, you can set it up as follows:

```sh
python -m venv venv
source venv/bin/activate  # On macOS/Linux
venv\Scripts\activate  # On Windows
pip install -r requirements.txt
```

This will install the required Python packages in a virtual environment.

## Resource Group

This module requires an existing Azure Resource Group. You can either:

1. Create one with Terraform before running this module:

    ```hcl
    resource "azurerm_resource_group" "materialize" {
      name     = var.resource_group_name
      location = var.location
    }
    ```

    Then set the `resource_group_name` variable in your `terraform.tfvars` file:

    ```hcl
    resource_group_name = "your-desired-rg-name"
    ```

2. Use an existing one by just setting the name in your `terraform.tfvars` file:

    ```hcl
    resource_group_name = "your-existing-rg"
    ```

## Disk Support for Materialize on Azure

This module supports configuring disks for Materialize on Azure using **local NVMe SSDs** available in specific VM families, along with **OpenEBS** and LVM for volume management.

### Recommended Azure VM Types with Local NVMe Disks

Materialize benefits from fast ephemeral storage and recommends a **minimum 2:1 disk-to-RAM ratio**. The [Epdsv6-series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/memory-optimized/epdsv6-series?tabs=sizebasic#sizes-in-series) virtual machines offer a balanced combination of **high memory, local NVMe storage**.

#### Epdsv6-series

| VM Size              | vCPUs | Memory  | Ephemeral Disk | Disk-to-RAM Ratio |
| -------------------- | ----- | ------- | -------------- | ----------------- |
| `Standard_E2pds_v6`  | 2     | 16 GiB  | 75 GiB         | ~4.7:1            |
| `Standard_E4pds_v6`  | 4     | 32 GiB  | 150 GiB        | ~4.7:1            |
| `Standard_E8pds_v6`  | 8     | 64 GiB  | 300 GiB        | ~4.7:1            |
| `Standard_E16pds_v6` | 16    | 128 GiB | 600 GiB        | ~4.7:1            |
| `Standard_E32pds_v6` | 32    | 256 GiB | 1,200 GiB      | ~4.7:1            |

> [!NOTE]
> These VM types provide **ephemeral local NVMe SSD disks**. Data is lost when the VM is stopped or deleted, so they should only be used for **temporary or performance-critical data** managed by Materialize.

### Enabling Disk Support on Azure

When `enable_disk_support` is set to `true`, the module:

1. Uses a bootstrap container to identify and configure available NVMe disks
1. Sets up **OpenEBS** with `lvm-localpv` to manage the ephemeral disks
1. Creates a StorageClass for Materialize

Example configuration:

```hcl
enable_disk_support = true

aks_config = {
  node_count   = 2
  vm_size      = "Standard_E4pds_v6"
  os_disk_size_gb = 100
  min_nodes    = 2
  max_nodes    = 4
}

disk_support_config = {
  install_openebs = true
  run_disk_setup_script = true
  create_storage_class = true

  openebs_version = "4.3.3"
  openebs_namespace = "openebs"
  storage_class_name = "openebs-lvm-instance-store-ext4"
}
```

## `materialize_instances` variable

The `materialize_instances` variable is a list of objects that define the configuration for each Materialize instance.

### `environmentd_extra_args`

Optional list of additional command-line arguments to pass to the `environmentd` container. This can be used to override default system parameters or enable specific features.

```hcl
environmentd_extra_args = [
  "--system-parameter-default=max_clusters=1000",
  "--system-parameter-default=max_connections=1000",
  "--system-parameter-default=max_tables=1000",
]
```

These flags configure default limits for clusters, connections, and tables. You can provide any supported arguments [here](https://materialize.com/docs/sql/alter-system-set/#other-configuration-parameters).

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.45.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.75.0 |
| <a name="requirement_deepmerge"></a> [deepmerge](#requirement\_deepmerge) | ~> 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aks"></a> [aks](#module\_aks) | ./modules/aks | n/a |
| <a name="module_certificates"></a> [certificates](#module\_certificates) | ./modules/certificates | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_load_balancers"></a> [load\_balancers](#module\_load\_balancers) | ./modules/load_balancers | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_operator"></a> [operator](#module\_operator) | github.com/MaterializeInc/terraform-helm-materialize | v0.1.35 |
| <a name="module_storage"></a> [storage](#module\_storage) | ./modules/storage | n/a |
| <a name="module_swap_nodepool"></a> [swap\_nodepool](#module\_swap\_nodepool) | ./modules/nodepool | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_config"></a> [aks\_config](#input\_aks\_config) | AKS cluster configuration | <pre>object({<br/>    vm_size      = string<br/>    disk_size_gb = number<br/>    min_nodes    = number<br/>    max_nodes    = number<br/>  })</pre> | <pre>{<br/>  "disk_size_gb": 100,<br/>  "max_nodes": 5,<br/>  "min_nodes": 1,<br/>  "vm_size": "Standard_E4pds_v6"<br/>}</pre> | no |
| <a name="input_cert_manager_chart_version"></a> [cert\_manager\_chart\_version](#input\_cert\_manager\_chart\_version) | Version of the cert-manager helm chart to install. | `string` | `"v1.17.1"` | no |
| <a name="input_cert_manager_install_timeout"></a> [cert\_manager\_install\_timeout](#input\_cert\_manager\_install\_timeout) | Timeout for installing the cert-manager helm chart, in seconds. | `number` | `300` | no |
| <a name="input_cert_manager_namespace"></a> [cert\_manager\_namespace](#input\_cert\_manager\_namespace) | The name of the namespace in which cert-manager is or will be installed. | `string` | `"cert-manager"` | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Azure Database for PostgreSQL configuration | <pre>object({<br/>    sku_name         = optional(string, "GP_Standard_D2s_v3")<br/>    postgres_version = optional(string, "15")<br/>    password         = string<br/>    username         = optional(string, "materialize")<br/>    db_name          = optional(string, "materialize")<br/>  })</pre> | n/a | yes |
| <a name="input_disk_setup_image"></a> [disk\_setup\_image](#input\_disk\_setup\_image) | Docker image for the disk setup script | `string` | `"materialize/ephemeral-storage-setup-image:v0.4.0"` | no |
| <a name="input_disk_support_config"></a> [disk\_support\_config](#input\_disk\_support\_config) | Advanced configuration for disk support (only used when enable\_disk\_support = true) | <pre>object({<br/>    install_openebs       = optional(bool, true)<br/>    run_disk_setup_script = optional(bool, true)<br/>    create_storage_class  = optional(bool, true)<br/>    openebs_version       = optional(string, "4.3.3")<br/>    openebs_namespace     = optional(string, "openebs")<br/>    storage_class_name    = optional(string, "openebs-lvm-instance-store-ext4")<br/>  })</pre> | `{}` | no |
| <a name="input_enable_disk_support"></a> [enable\_disk\_support](#input\_enable\_disk\_support) | Enable disk support for Materialize using OpenEBS and local SSDs. When enabled, this configures OpenEBS, runs the disk setup script, and creates appropriate storage classes. | `bool` | `true` | no |
| <a name="input_helm_chart"></a> [helm\_chart](#input\_helm\_chart) | Chart name from repository or local path to chart. For local charts, set the path to the chart directory. | `string` | `"materialize-operator"` | no |
| <a name="input_helm_values"></a> [helm\_values](#input\_helm\_values) | Additional Helm values to merge with defaults | `any` | `{}` | no |
| <a name="input_install_cert_manager"></a> [install\_cert\_manager](#input\_install\_cert\_manager) | Whether to install cert-manager. | `bool` | `true` | no |
| <a name="input_install_materialize_operator"></a> [install\_materialize\_operator](#input\_install\_materialize\_operator) | Whether to install the Materialize operator | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | The location where resources will be created | `string` | `"eastus2"` | no |
| <a name="input_materialize_instances"></a> [materialize\_instances](#input\_materialize\_instances) | Configuration for Materialize instances | <pre>list(object({<br/>    name                              = string<br/>    namespace                         = optional(string)<br/>    database_name                     = string<br/>    environmentd_version              = optional(string)<br/>    cpu_request                       = optional(string, "1")<br/>    memory_request                    = optional(string, "1Gi")<br/>    memory_limit                      = optional(string, "1Gi")<br/>    create_database                   = optional(bool, true)<br/>    create_load_balancer              = optional(bool, true)<br/>    internal_load_balancer            = optional(bool, true)<br/>    in_place_rollout                  = optional(bool, false)<br/>    request_rollout                   = optional(string)<br/>    force_rollout                     = optional(string)<br/>    balancer_memory_request           = optional(string, "256Mi")<br/>    balancer_memory_limit             = optional(string, "256Mi")<br/>    balancer_cpu_request              = optional(string, "100m")<br/>    license_key                       = optional(string)<br/>    authenticator_kind                = optional(string, "None")<br/>    external_login_password_mz_system = optional(string, null)<br/>    environmentd_extra_args           = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for all resources, usually the organization or project name | `string` | `"materialize"` | no |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | Network configuration for the AKS cluster | <pre>object({<br/>    vnet_address_space   = string<br/>    subnet_cidr          = string<br/>    postgres_subnet_cidr = string<br/>    service_cidr         = string<br/>    docker_bridge_cidr   = string<br/>  })</pre> | n/a | yes |
| <a name="input_operator_namespace"></a> [operator\_namespace](#input\_operator\_namespace) | Namespace for the Materialize operator | `string` | `"materialize"` | no |
| <a name="input_operator_version"></a> [operator\_version](#input\_operator\_version) | Version of the Materialize operator to install | `string` | `null` | no |
| <a name="input_orchestratord_version"></a> [orchestratord\_version](#input\_orchestratord\_version) | Version of the Materialize orchestrator to install | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix to be used for resource names | `string` | `"materialize"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of an existing resource group to use | `string` | n/a | yes |
| <a name="input_swap_enabled"></a> [swap\_enabled](#input\_swap\_enabled) | Enable swap for Materialize. When enabled, this configures swap on a new nodepool, and adds it to the clusterd node selectors. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_use_local_chart"></a> [use\_local\_chart](#input\_use\_local\_chart) | Whether to use a local chart instead of one from a repository | `bool` | `false` | no |
| <a name="input_use_self_signed_cluster_issuer"></a> [use\_self\_signed\_cluster\_issuer](#input\_use\_self\_signed\_cluster\_issuer) | Whether to install and use a self-signed ClusterIssuer for TLS. To work around limitations in Terraform, this will be treated as `false` if no materialize instances are defined. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aks_cluster"></a> [aks\_cluster](#output\_aks\_cluster) | AKS cluster details |
| <a name="output_connection_strings"></a> [connection\_strings](#output\_connection\_strings) | Formatted connection strings for Materialize |
| <a name="output_database"></a> [database](#output\_database) | Azure Database for PostgreSQL details |
| <a name="output_identities"></a> [identities](#output\_identities) | Managed Identity details |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | The kube\_config for the AKS cluster |
| <a name="output_kube_config_raw"></a> [kube\_config\_raw](#output\_kube\_config\_raw) | The kube\_config for the AKS cluster |
| <a name="output_load_balancer_details"></a> [load\_balancer\_details](#output\_load\_balancer\_details) | Details of the Materialize instance load balancers. |
| <a name="output_network"></a> [network](#output\_network) | Network details |
| <a name="output_operator"></a> [operator](#output\_operator) | Materialize operator details |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_storage"></a> [storage](#output\_storage) | Azure Storage Account details |

## Accessing the AKS cluster

The AKS cluster can be accessed using the `kubectl` command-line tool. To authenticate with the cluster, run the following command:

```sh
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -json aks_cluster | jq -r '.name')
```

This command retrieves the AKS cluster credentials and merges them into the `~/.kube/config` file. You can now interact with the AKS cluster using `kubectl`.

## Connecting to Materialize instances

By default, two `LoadBalancer` `Services` are created for each Materialize instance:
1. One for balancerd, listening on:
    1. Port 6875 for SQL connections to the database.
    1. Port 6876 for HTTP(S) connections to the database.
1. One for the web console, listening on:
    1. Port 8080 for HTTP(S) connections.

The IP addresses of these load balancers will be in the `terraform output` as `load_balancer_details`.

#### TLS support

TLS support is provided by using `cert-manager` and a self-signed `ClusterIssuer`.

More advanced TLS support using user-provided CAs or per-Materialize `Issuer`s are out of scope for this Terraform module. Please refer to the [cert-manager documentation](https://cert-manager.io/docs/configuration/) for detailed guidance on more advanced usage.

## Upgrade Notes

#### v0.6.1

We recommend upgrading to at least v0.5.10 before upgrading to v0.6.x of this terraform code.

To use swap:
1. Set `swap_enabled` to `true`.
2. Ensure your `environmentd_version` is at least `v26.0.0`.
3. Update your `request_rollout` (and `force_rollout` if already at the correct `environmentd_version`).
4. Run `terraform apply`.

This will create a new node group configured for swap, and migrate your clusterd pods there.

#### v0.6.0

This version is missing the updated helm chart.
Skip this version, go to v0.6.1.

#### v0.3.0

We now install `cert-manager` and configure a self-signed `ClusterIssuer` by default.

Due to limitations in Terraform, it cannot plan Kubernetes resources using CRDs that do not exist yet. We have worked around this for new users by only generating the certificate resources when creating Materialize instances that use them, which also cannot be created on the first run.

For existing users upgrading Materialize instances not previously configured for TLS:
1. Leave `install_cert_manager` at its default of `true`.
2. Set `use_self_signed_cluster_issuer` to `false`.
3. Run `terraform apply`. This will install cert-manager and its CRDs.
4. Set `use_self_signed_cluster_issuer` back to `true` (the default).
5. Update the `request_rollout` field of the Materialize instance.
6. Run `terraform apply`. This will generate the certificates and configure your Materialize instance to use them.
<!-- END_TF_DOCS -->
