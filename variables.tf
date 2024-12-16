
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location where resources will be created"
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix to be used for resource names"
  type        = string
  default     = "materialize"
}

variable "network_config" {
  description = "Network configuration for the AKS cluster"
  type = object({
    vnet_address_space = string
    subnet_cidr        = string
  })
  default = {
    vnet_address_space = "10.0.0.0/16"
    subnet_cidr        = "10.0.0.0/20"
  }
}

variable "aks_config" {
  description = "AKS cluster configuration"
  type = object({
    node_count   = number
    vm_size      = string
    disk_size_gb = number
    min_nodes    = number
    max_nodes    = number
  })
  default = {
    node_count   = 3
    vm_size      = "Standard_D2s_v3"
    disk_size_gb = 100
    min_nodes    = 1
    max_nodes    = 5
  }
}

variable "database_config" {
  description = "Azure Database for PostgreSQL configuration"
  type = object({
    sku_name = optional(string, "GP_Standard_D2s_v3")
    version  = optional(string, "15")
    password = string
    username = optional(string, "materialize")
    db_name  = optional(string, "materialize")
  })

  validation {
    condition     = var.database_config.password != null
    error_message = "database_config.password must be provided"
  }
}

variable "namespace" {
  description = "Kubernetes namespace for Materialize"
  type        = string
  default     = "materialize"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
