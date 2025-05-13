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

  openebs_version = "4.2.0"
  openebs_namespace = "openebs"
  storage_class_name = "openebs-lvm-instance-store-ext4"
}
```
