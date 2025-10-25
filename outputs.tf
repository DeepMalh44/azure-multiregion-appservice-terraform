# Output values for the multi-region deployment

# Resource Group outputs
output "primary_resource_group" {
  description = "Primary resource group details"
  value = {
    name     = azurerm_resource_group.primary.name
    location = azurerm_resource_group.primary.location
    id       = azurerm_resource_group.primary.id
  }
}

output "secondary_resource_group" {
  description = "Secondary resource group details"
  value = {
    name     = azurerm_resource_group.secondary.name
    location = azurerm_resource_group.secondary.location
    id       = azurerm_resource_group.secondary.id
  }
}

# Networking outputs
output "primary_vnet" {
  description = "Primary region VNet details"
  value = {
    name          = module.networking_primary.vnet_name
    id            = module.networking_primary.vnet_id
    address_space = module.networking_primary.vnet_address_space
  }
}

output "secondary_vnet" {
  description = "Secondary region VNet details"
  value = {
    name          = module.networking_secondary.vnet_name
    id            = module.networking_secondary.vnet_id
    address_space = module.networking_secondary.vnet_address_space
  }
}

# App Service outputs
output "primary_app_service" {
  description = "Primary App Service details"
  value = {
    name              = module.app_service_primary.app_service_name
    id                = module.app_service_primary.app_service_id
    default_hostname  = module.app_service_primary.default_hostname
    outbound_ips      = module.app_service_primary.outbound_ip_addresses
    possible_outbound_ips = module.app_service_primary.possible_outbound_ip_addresses
  }
}

output "secondary_app_service" {
  description = "Secondary App Service details"
  value = {
    name              = module.app_service_secondary.app_service_name
    id                = module.app_service_secondary.app_service_id
    default_hostname  = module.app_service_secondary.default_hostname
    outbound_ips      = module.app_service_secondary.outbound_ip_addresses
    possible_outbound_ips = module.app_service_secondary.possible_outbound_ip_addresses
  }
}

# Application Gateway outputs
output "application_gateway" {
  description = "Application Gateway details"
  value = {
    name       = module.application_gateway.application_gateway_name
    id         = module.application_gateway.application_gateway_id
    public_ip  = module.application_gateway.public_ip_address
    fqdn       = module.application_gateway.public_ip_fqdn
  }
}

# Application URLs
output "application_urls" {
  description = "URLs to access the application"
  value = {
    application_gateway_url = "https://${module.application_gateway.public_ip_fqdn}"
    primary_app_direct_url  = "https://${module.app_service_primary.default_hostname}"
    secondary_app_direct_url = "https://${module.app_service_secondary.default_hostname}"
  }
}

# Deployment information
output "deployment_info" {
  description = "Information about the deployment"
  value = {
    name_suffix       = local.name_suffix
    primary_region    = var.primary_region
    secondary_region  = var.secondary_region
    environment       = var.environment
    project_name      = var.project_name
  }
}