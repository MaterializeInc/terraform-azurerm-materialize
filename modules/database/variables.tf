variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location where resources will be created"
  type        = string
}

variable "prefix" {
  description = "Prefix to be used for resource names"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet for PostgreSQL"
  type        = string
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  type        = string
}

variable "sku_name" {
  description = "The SKU name for the PostgreSQL server"
  type        = string
}

variable "postgres_version" {
  description = "The PostgreSQL version"
  type        = string
  validation {
    condition     = can(regex("^[0-9]+$", var.postgres_version))
    error_message = "Version must be a number (e.g., 15)"
  }
}

variable "password" {
  description = "The password for the database user"
  type        = string
  sensitive   = true
}

variable "database_user" {
  description = "The name of the database user"
  type        = string
  default     = "materialize"
}

variable "database_name" {
  description = "The name of the database"
  type        = string
  default     = "materialize"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
