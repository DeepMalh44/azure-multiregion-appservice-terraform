# Multi-Region Azure App Service with Application Gateway
# This configuration deploys a highly available, multi-region setup

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Generate random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values for common configurations
locals {
  name_suffix = random_id.suffix.hex
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Primary Resource Group
resource "azurerm_resource_group" "primary" {
  name     = "rg-${var.project_name}-${var.primary_region}-${local.name_suffix}"
  location = var.primary_region
  tags     = local.common_tags
}

# Secondary Resource Group
resource "azurerm_resource_group" "secondary" {
  name     = "rg-${var.project_name}-${var.secondary_region}-${local.name_suffix}"
  location = var.secondary_region
  tags     = local.common_tags
}

# Primary Region Networking
module "networking_primary" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.primary.name
  location           = azurerm_resource_group.primary.location
  vnet_name          = "vnet-${var.project_name}-${var.primary_region}-${local.name_suffix}"
  address_space      = var.primary_vnet_address_space
  
  tags = local.common_tags
}

# Secondary Region Networking
module "networking_secondary" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.secondary.name
  location           = azurerm_resource_group.secondary.location
  vnet_name          = "vnet-${var.project_name}-${var.secondary_region}-${local.name_suffix}"
  address_space      = var.secondary_vnet_address_space
  
  tags = local.common_tags
}

# Primary Region App Service
module "app_service_primary" {
  source = "./modules/app-service"
  
  resource_group_name = azurerm_resource_group.primary.name
  location           = azurerm_resource_group.primary.location
  app_service_name   = "app-${var.project_name}-${var.primary_region}-${local.name_suffix}"
  app_service_plan_name = "asp-${var.project_name}-${var.primary_region}-${local.name_suffix}"
  
  subnet_id = module.networking_primary.app_service_subnet_id
  
  zone_balancing_enabled = var.zone_balancing_enabled
  sku_name              = var.app_service_sku
  
  tags = local.common_tags
}

# Secondary Region App Service
module "app_service_secondary" {
  source = "./modules/app-service"
  
  resource_group_name = azurerm_resource_group.secondary.name
  location           = azurerm_resource_group.secondary.location
  app_service_name   = "app-${var.project_name}-${var.secondary_region}-${local.name_suffix}"
  app_service_plan_name = "asp-${var.project_name}-${var.secondary_region}-${local.name_suffix}"
  
  subnet_id = module.networking_secondary.app_service_subnet_id
  
  zone_balancing_enabled = var.zone_balancing_enabled
  sku_name              = var.app_service_sku
  
  tags = local.common_tags
}

# Application Gateway (deployed in primary region for cross-region load balancing)
module "application_gateway" {
  source = "./modules/application-gateway"
  
  resource_group_name = azurerm_resource_group.primary.name
  location           = azurerm_resource_group.primary.location
  
  application_gateway_name = "agw-${var.project_name}-${local.name_suffix}"
  subnet_id               = module.networking_primary.application_gateway_subnet_id
  
  backend_pools = [
    {
      name = "primary-backend"
      fqdns = [module.app_service_primary.default_hostname]
    },
    {
      name = "secondary-backend"
      fqdns = [module.app_service_secondary.default_hostname]
    }
  ]
  
  tags = local.common_tags
}