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

variable "identity_principal_id" {
  description = "The principal ID of the workload identity"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "the subnet of the vnet that should be able to access this storage account"
  type        = list(string)
  default     = []
}
