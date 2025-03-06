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
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

provider "azurerm" {
  # Set the Azure subscription ID here or use the ARM_SUBSCRIPTION_ID environment variable
  # subscription_id = "XXXXXXXXXXXXXXXXXXX"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }

  }
}

resource "random_password" "pass" {
  length  = 20
  special = false
}

resource "azurerm_resource_group" "materialize" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

module "materialize" {
  # Referencing the root module directory:
  source = "../.."

  # Alternatively, you can use the GitHub source URL:
  # source              = "github.com/MaterializeInc/terraform-azurerm-materialize?ref=v0.1.4"

  resource_group_name = azurerm_resource_group.materialize.name
  location            = var.location
  prefix              = var.prefix

  materialize_instances = var.materialize_instances

  database_config = {
    sku_name = "GP_Standard_D2s_v3"
    version  = "15"
    password = random_password.pass.result
  }

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }

  providers = {
    azurerm = azurerm
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
  default     = "eastus2"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# This can only be populated after the initial Kubernetes cluster deployment
# due to provider limitations (hashicorp/terraform-provider-kubernetes#1775)
variable "materialize_instances" {
  description = "List of Materialize instances to be created."
  type = list(object({
    name                    = string
    namespace               = optional(string)
    database_name           = string
    environmentd_version    = optional(string, "v0.130.4")
    cpu_request             = optional(string, "1")
    memory_request          = optional(string, "1Gi")
    memory_limit            = optional(string, "1Gi")
    create_database         = optional(bool, true)
    in_place_rollout        = optional(bool, false)
    request_rollout         = optional(string)
    force_rollout           = optional(string)
    balancer_memory_request = optional(string, "256Mi")
    balancer_memory_limit   = optional(string, "256Mi")
    balancer_cpu_request    = optional(string, "100m")
  }))
  default = []
}

# Output the Materialize instance details
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

output "kube_config" {
  description = "The kube_config for the AKS cluster"
  value       = module.materialize.kube_config
  sensitive   = true
}

output "resource_group_name" {
  value = azurerm_resource_group.materialize.name
}
