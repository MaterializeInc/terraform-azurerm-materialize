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

### Advanced Configuration

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
