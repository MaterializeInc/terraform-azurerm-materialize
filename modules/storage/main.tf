
resource "azurerm_storage_account" "materialize" {
  name                = replace("${var.prefix}storage${random_string.unique.result}", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  # https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-block-blob-premium#premium-scenarios
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "BlockBlobStorage"

  dynamic "network_rules" {
    for_each = length(var.subnets) == 0 ? [] : ["not_used"]
    content {
      default_action             = "Allow"
      bypass                     = ["AzureServices"]
      virtual_network_subnet_ids = var.subnets
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "materialize" {
  name                  = "materialize"
  storage_account_id    = azurerm_storage_account.materialize.id
  container_access_type = "private"
}

resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.materialize.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.identity_principal_id
}

data "azurerm_client_config" "this" {}

resource "azurerm_key_vault" "sas_token_vault" {
  name                = "${var.prefix}-sas-tv"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.this.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.this.tenant_id
    object_id = data.azurerm_client_config.this.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

# Call the Python script using Terraform's `external` provider
data "external" "sas_token" {
  program = ["python3", "${path.module}/generate_sas.py"]

  query = {
    subscription_id        = data.azurerm_client_config.this.subscription_id
    storage_account_name   = azurerm_storage_account.materialize.name
    resource_group         = var.resource_group_name
    key_vault_name         = azurerm_key_vault.sas_token_vault.name
    sas_secret_name        = "sas-token"
    sas_expiry_secret_name = "sas-expiry"
  }

}
