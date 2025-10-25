# Variables for the Application Gateway module

variable "resource_group_name" {
  description = "Name of the resource group where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "application_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where Application Gateway will be deployed"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "tier" {
  description = "Tier for the Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "min_capacity" {
  description = "Minimum capacity for autoscaling"
  type        = number
  default     = 0
}

variable "max_capacity" {
  description = "Maximum capacity for autoscaling"
  type        = number
  default     = 10
}

variable "backend_pools" {
  description = "List of backend pools with their FQDNs"
  type = list(object({
    name  = string
    fqdns = list(string)
  }))
  default = []
}

variable "organization_name" {
  description = "Organization name for SSL certificate"
  type        = string
  default     = "Demo Organization"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}