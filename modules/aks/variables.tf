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

variable "vnet_name" {
  description = "The name of the virtual network."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet for AKS"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet for AKS"
  type        = string
}

variable "service_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
}

variable "disk_size_gb" {
  description = "Size of the disk attached to each node"
  type        = number
}

variable "min_nodes" {
  description = "Minimum number of nodes in the node pool"
  type        = number
}

variable "max_nodes" {
  description = "Maximum number of nodes in the node pool"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
