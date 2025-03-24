# Materialize on Azure

Terraform module for deploying Materialize on Azure with all required infrastructure components.

This module sets up:
- AKS cluster for Materialize workloads
- Azure Database for PostgreSQL Flexible Server for metadata storage
- Azure Blob Storage for persistence
- Required networking and security configurations
- Managed identities with proper RBAC permissions

> [!WARNING]
> This module is intended to be used for demonstrations, simple evaluations, and as a template for building your own production deployment of Materialize.
>
> This module should not be relied upon for production deployments directly: future releases of the module will contain breaking changes. When used as a starting point for a production deployment, you must either fork this repo and pin to a specific version, or use the code as a reference when developing your own deployment.

The module has been tested with:
- AKS version 1.28
- PostgreSQL 15
- Materialize Operator v0.1.0

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
