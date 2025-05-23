variable "namespace" {
  description = "Namespace for all resources, usually the organization or project name"
  type        = string
  validation {
    condition     = length(var.namespace) <= 12 && can(regex("^[a-z0-9-]+$", var.namespace))
    error_message = "Namespace must be lowercase alphanumeric and hyphens only, max 12 characters"
  }
  default = "materialize"
}

variable "location" {
  description = "The location where resources will be created"
  type        = string
  default     = "norwayeast"
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
variable "database_config" {
  description = "Azure Database for PostgreSQL configuration"
  type = object({
    postgres_version = optional(string, "13")
    host             = string
    password         = string
    username         = optional(string, "materialize")
    db_name          = optional(string, "materialize")
  })

  validation {
    condition     = var.database_config.password != null
    error_message = "database_config.password must be provided"
  }
}

variable "storage_config" {
  description = "Azure Storage Account Blob Storage"
  type = object({
    primary_blob_endpoint  = string
    container_name         = optional(string, "materialize")
    primary_blob_sas_token = string
  })

  validation {
    condition     = var.storage_config.primary_blob_endpoint != null
    error_message = "storage_config.primary_blob_endpoint must be provided"
  }
  validation {
    condition     = var.storage_config.primary_blob_sas_token != null
    error_message = "storage_config.password must be provided"
  }
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
    environmentd_version    = optional(string)
    cpu_request             = optional(string, "1")
    memory_request          = optional(string, "1Gi")
    memory_limit            = optional(string, "1Gi")
    create_database         = optional(bool, true)
    create_load_balancer    = optional(bool, true)
    internal_load_balancer  = optional(bool, true)
    in_place_rollout        = optional(bool, false)
    request_rollout         = optional(string)
    force_rollout           = optional(string)
    balancer_memory_request = optional(string, "256Mi")
    balancer_memory_limit   = optional(string, "256Mi")
    balancer_cpu_request    = optional(string, "100m")
    license_key             = optional(string)
  }))
  default = []
}
