
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
