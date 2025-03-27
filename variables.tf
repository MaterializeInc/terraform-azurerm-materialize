variable "namespace" {
  description = "Namespace for all resources, usually the organization or project name"
  type        = string
  validation {
    condition     = length(var.namespace) <= 12 && can(regex("^[a-z0-9-]+$", var.namespace))
    error_message = "Namespace must be lowercase alphanumeric and hyphens only, max 12 characters"
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
  validation {
    condition     = length(var.prefix) >= 3 && length(var.prefix) <= 16 && can(regex("^[a-z0-9-]+$", var.prefix))
    error_message = "Prefix must be between 3-16 characters, lowercase alphanumeric and hyphens only."
  }
}

variable "network_config" {
  description = "Network configuration for the AKS cluster"
  type = object({
    vnet_address_space   = string
    subnet_cidr          = string
    postgres_subnet_cidr = string
    service_cidr         = string
    docker_bridge_cidr   = string
  })
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
  default     = null
}

variable "operator_namespace" {
  description = "Namespace for the Materialize operator"
  type        = string
  default     = "materialize"
}

variable "orchestratord_version" {
  description = "Version of the Materialize orchestrator to install"
  type        = string
  default     = null
}

variable "helm_values" {
  description = "Additional Helm values to merge with defaults"
  type        = any
  default     = {}
}

variable "materialize_instances" {
  description = "Configuration for Materialize instances"
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

variable "install_cert_manager" {
  description = "Whether to install cert-manager."
  type        = bool
  default     = false
}

variable "use_self_signed_cluster_issuer" {
  description = "Whether to install and use a self-signed ClusterIssuer for TLS. Due to limitations in Terraform, this may not be enabled before the cert-manager CRDs are installed."
  type        = bool
  default     = false
}

variable "cert_manager_namespace" {
  description = "The name of the namespace in which cert-manager is or will be installed."
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_install_timeout" {
  description = "Timeout for installing the cert-manager helm chart, in seconds."
  type        = number
  default     = 300
}

variable "cert_manager_chart_version" {
  description = "Version of the cert-manager helm chart to install."
  type        = string
  default     = "v1.17.1"
}
