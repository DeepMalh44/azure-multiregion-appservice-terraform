# Staging Environment Configuration
# Environment-specific variables
project_name     = "hello-world-app"
environment      = "staging"
primary_region   = "eastus"
secondary_region = "westus2"

# Network configuration
primary_vnet_address_space   = ["10.0.0.0/16"]
secondary_vnet_address_space = ["10.1.0.0/16"]

# App Service configuration
app_service_sku        = "S1"  # Standard S1 for staging
zone_balancing_enabled = false # Standard SKU doesn't support zone balancing
enable_private_endpoints = true

# Application Gateway configuration
application_gateway_sku  = "Standard_v2"
application_gateway_tier = "Standard_v2"
min_capacity = 0
max_capacity = 5  # Lower capacity for staging