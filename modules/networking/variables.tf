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

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the AKS subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
