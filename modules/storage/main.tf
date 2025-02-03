
resource "azurerm_storage_account" "materialize" {
  name                     = replace("${var.prefix}storage${random_string.unique.result}", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  # network_rules {
  #   default_action = "Allow"
  #   bypass         = ["AzureServices"]
  # }

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

# # Generate a Storage Account SAS Tokenj
# data "azurerm_storage_account_sas" "token" {
#   connection_string = azurerm_storage_account.materialize.primary_connection_string
#   https_only        = true

#   resource_types {
#     object    = true
#     container = true
#     service   = true
#   } # "s" for service-level access, "o" for object

#   services {
#     blob  = true
#     table = false
#     queue = false
#     file  = false
#   }

#   permissions {
#     read    = true
#     write   = true
#     delete  = true
#     list    = true
#     add     = true
#     create  = true
#     update  = true
#     process = true
#     tag     = true
#     filter  = true
#   }

#   start  = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timestamp())
#   expiry = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timeadd(timestamp(), "8760h")) # 1 year validity
# }
data "azurerm_client_config" "this" {}

resource "azurerm_key_vault" "sas_token_vault" {
  name                = "${var.prefix}-sas-token-vault"
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

