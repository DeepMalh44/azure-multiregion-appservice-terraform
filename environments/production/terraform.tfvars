# Production Environment Configuration
# Environment-specific variables
project_name     = "hello-world-app"
environment      = "production"
primary_region   = "eastus"
secondary_region = "westus2"

# Network configuration
primary_vnet_address_space   = ["10.10.0.0/16"]
secondary_vnet_address_space = ["10.11.0.0/16"]

# App Service configuration
app_service_sku        = "S1"  # Standard S1 (more widely available)
zone_balancing_enabled = false # Standard SKU doesn't support zone balancing
enable_private_endpoints = true

# Application Gateway configuration
application_gateway_sku  = "WAF_v2"  # WAF for production security
application_gateway_tier = "WAF_v2"
min_capacity = 2   # Minimum instances for production
max_capacity = 20  # Higher capacity for production