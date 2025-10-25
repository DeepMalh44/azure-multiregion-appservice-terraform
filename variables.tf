# Variables for the multi-region App Service deployment

variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
  default     = "hello-world-app"
  
  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 20 characters."
  }
}

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
  default     = "staging"
  
  validation {
    condition     = contains(["staging", "production", "development"], var.environment)
    error_message = "Environment must be one of: staging, production, development."
  }
}

variable "primary_region" {
  description = "Primary Azure region for deployment"
  type        = string
  default     = "eastus"
}

variable "secondary_region" {
  description = "Secondary Azure region for deployment"
  type        = string
  default     = "westus2"
}

variable "primary_vnet_address_space" {
  description = "Address space for primary region VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "secondary_vnet_address_space" {
  description = "Address space for secondary region VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "P1v3"
  
  validation {
    condition = contains([
      "P1v3", "P2v3", "P3v3",  # Premium v3 (supports zone redundancy)
      "S1", "S2", "S3",        # Standard (no zone redundancy)
      "B1", "B2", "B3"         # Basic (no zone redundancy)
    ], var.app_service_sku)
    error_message = "App Service SKU must be a valid Azure App Service plan size."
  }
}

variable "zone_balancing_enabled" {
  description = "Enable zone balancing for App Service Plan (requires Premium v3 SKU)"
  type        = bool
  default     = true
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for App Service"
  type        = bool
  default     = true
}

variable "application_gateway_sku" {
  description = "SKU for Application Gateway"
  type        = string
  default     = "Standard_v2"
  
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.application_gateway_sku)
    error_message = "Application Gateway SKU must be Standard_v2 or WAF_v2."
  }
}

variable "application_gateway_tier" {
  description = "Tier for Application Gateway"
  type        = string
  default     = "Standard_v2"
  
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.application_gateway_tier)
    error_message = "Application Gateway tier must be Standard_v2 or WAF_v2."
  }
}

variable "min_capacity" {
  description = "Minimum capacity for Application Gateway autoscaling"
  type        = number
  default     = 0
  
  validation {
    condition     = var.min_capacity >= 0 && var.min_capacity <= 125
    error_message = "Minimum capacity must be between 0 and 125."
  }
}

variable "max_capacity" {
  description = "Maximum capacity for Application Gateway autoscaling"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_capacity >= 2 && var.max_capacity <= 125
    error_message = "Maximum capacity must be between 2 and 125."
  }
}