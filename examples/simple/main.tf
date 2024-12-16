
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.45.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

resource "azurerm_resource_group" "materialize" {
  name     = "rg-${var.prefix}"
  location = var.location
  tags     = var.tags
}

module "materialize" {
  source = "../.." # Update this path based on your directory structure

  resource_group_name = azurerm_resource_group.materialize.name
  location            = var.location
  prefix              = var.prefix

  database_config = {
    sku_name = "GP_Standard_D2s_v3"
    version  = "15"
    password = var.database_password
  }

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}


variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "mz-dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "database_password" {
  description = "Password for PostgreSQL database user"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

output "aks_cluster" {
  description = "AKS cluster details"
  value       = module.materialize.aks_cluster
  sensitive   = true
}

output "connection_strings" {
  description = "Connection strings for Materialize"
  value       = module.materialize.connection_strings
  sensitive   = true
}
