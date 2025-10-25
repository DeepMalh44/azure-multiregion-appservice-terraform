# Outputs for the networking module

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "app_service_subnet_id" {
  description = "ID of the App Service subnet"
  value       = azurerm_subnet.app_service.id
}

output "application_gateway_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = azurerm_subnet.application_gateway.id
}

output "private_endpoints_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "app_service_subnet_address_prefix" {
  description = "Address prefix of the App Service subnet"
  value       = azurerm_subnet.app_service.address_prefixes[0]
}

output "application_gateway_subnet_address_prefix" {
  description = "Address prefix of the Application Gateway subnet"
  value       = azurerm_subnet.application_gateway.address_prefixes[0]
}