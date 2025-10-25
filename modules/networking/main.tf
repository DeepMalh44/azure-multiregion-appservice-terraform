# Networking Module - Creates VNet and Subnets
# This module creates the networking infrastructure for the App Service and Application Gateway

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# App Service Subnet (for VNet integration)
resource "azurerm_subnet" "app_service" {
  name                 = "snet-appservice"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 4, 1)] # /20 subnet
  
  # Delegate subnet to App Service
  delegation {
    name = "app-service-delegation"
    
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

# Application Gateway Subnet
resource "azurerm_subnet" "application_gateway" {
  name                 = "snet-appgateway"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 4, 2)] # /20 subnet
}

# Private Endpoint Subnet
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-privateendpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space[0], 4, 3)] # /20 subnet
  
  # Disable private endpoint network policies
  private_endpoint_network_policies = "Disabled"
}

# Network Security Group for App Service Subnet
resource "azurerm_network_security_group" "app_service" {
  name                = "nsg-appservice-${var.vnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Allow inbound HTTP/HTTPS from Application Gateway subnet
  security_rule {
    name                       = "AllowApplicationGateway"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = azurerm_subnet.application_gateway.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.app_service.address_prefixes[0]
  }
  
  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = var.tags
}

# Network Security Group for Application Gateway Subnet
resource "azurerm_network_security_group" "application_gateway" {
  name                = "nsg-appgateway-${var.vnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Allow inbound HTTPS from Internet
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Allow inbound HTTP from Internet (for redirect to HTTPS)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Allow Application Gateway management traffic
  security_rule {
    name                       = "AllowGatewayManager"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  
  tags = var.tags
}

# Associate NSG with App Service Subnet
resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                 = azurerm_subnet.app_service.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}

# Associate NSG with Application Gateway Subnet
resource "azurerm_subnet_network_security_group_association" "application_gateway" {
  subnet_id                 = azurerm_subnet.application_gateway.id
  network_security_group_id = azurerm_network_security_group.application_gateway.id
}