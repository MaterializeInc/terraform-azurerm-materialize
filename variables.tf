variable "namespace" {
  description = "Namespace for all resources, usually the organization or project name"
  type        = string
  validation {
    condition     = length(var.namespace) <= 18 && can(regex("^[a-z0-9-]+$", var.namespace))
    error_message = "Namespace must be lowercase alphanumeric and hyphens only, max 18 characters"
  }
  default = "materialize"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location where resources will be created"
  type        = string
  default     = "eastus2"
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
    service_cidr       = string
  })
  default = {
    vnet_address_space = "10.0.0.0/16"
    subnet_cidr        = "10.0.0.0/20"
    service_cidr       = "10.1.0.0/16"
    docker_bridge_cidr = "172.17.0.1/16"
  }
}

variable "aks_config" {
  description = "AKS cluster configuration"
  type = object({
    vm_size      = string
    disk_size_gb = number
    min_nodes    = number
    max_nodes    = number
  })
  default = {
    vm_size      = "Standard_E8ps_v6"
    disk_size_gb = 100
    min_nodes    = 1
    max_nodes    = 5
  }
}

variable "database_config" {
  description = "Azure Database for PostgreSQL configuration"
  type = object({
    sku_name         = optional(string, "GP_Standard_D2s_v3")
    postgres_version = optional(string, "15")
    password         = string
    username         = optional(string, "materialize")
    db_name          = optional(string, "materialize")
  })

  validation {
    condition     = var.database_config.password != null
    error_message = "database_config.password must be provided"
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Materialize Helm Chart Variables
variable "install_materialize_operator" {
  description = "Whether to install the Materialize operator"
  type        = bool
  default     = true
}

variable "helm_chart" {
  description = "Chart name from repository or local path to chart. For local charts, set the path to the chart directory."
  type        = string
  default     = "materialize-operator"
}

variable "use_local_chart" {
  description = "Whether to use a local chart instead of one from a repository"
  type        = bool
  default     = false
}

variable "operator_version" {
  description = "Version of the Materialize operator to install"
  type        = string
  default     = "v25.1.0"
}

variable "operator_namespace" {
  description = "Namespace for the Materialize operator"
  type        = string
  default     = "materialize"
}

variable "orchestratord_version" {
  description = "Version of the Materialize orchestrator to install"
  type        = string
  default     = "v0.130.3"
}

variable "helm_values" {
  description = "Additional Helm values to merge with defaults"
  type        = any
  default     = {}
}

variable "materialize_instances" {
  description = "Configuration for Materialize instances"
  type = list(object({
    name                 = string
    namespace            = optional(string)
    database_name        = string
    environmentd_version = optional(string, "v0.130.3")
    cpu_request          = optional(string, "1")
    memory_request       = optional(string, "1Gi")
    memory_limit         = optional(string, "1Gi")
    create_database      = optional(bool, true)
    in_place_rollout     = optional(bool, false)
    request_rollout      = optional(string)
    force_rollout        = optional(string)
  }))
  default = []
}
