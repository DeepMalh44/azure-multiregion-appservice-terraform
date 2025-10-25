# App Service Module - Creates App Service Plan and App Service
# This module creates a highly available App Service with zone redundancy and VNet integration

# App Service Plan with zone redundancy
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  
  # Enable zone balancing for high availability (requires Premium v3 SKU)
  zone_balancing_enabled = var.zone_balancing_enabled && can(regex("^P[123]v3$", var.sku_name))
  
  tags = var.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id
  
  # Enable HTTPS only
  https_only = true
  
  # Configure VNet integration
  virtual_network_subnet_id = var.subnet_id
  
  site_config {
    # Always on for production workloads
    always_on = true
    
    # Use HTTP 2.0
    http2_enabled = true
    
    # Application stack configuration for Hello World
    application_stack {
      node_version = "18-lts"
    }
    
    # Security headers
    ftps_state = "Disabled"
    
    # Health check path
    health_check_path = "/health"
    
    # Minimum TLS version
    minimum_tls_version = "1.2"
  }
  
  # App settings for the Hello World application
  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "18.17.1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD" = "true"
    # Environment-specific settings
    "APP_ENV" = var.environment
    "APP_REGION" = var.location
    # Application Insights configuration
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  }
  
  # Connection strings (if needed for database connectivity)
  # connection_string {
  #   name  = "DefaultConnection"
  #   type  = "SQLAzure"
  #   value = var.database_connection_string
  # }
  
  # Configure logging
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    
    application_logs {
      file_system_level = "Information"
    }
    
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
  
  # Identity for accessing other Azure services
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to app_settings during deployment
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Create Log Analytics Workspace for Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.app_service_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = var.tags
}

# Create Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.app_service_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "Node.JS"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  
  tags = var.tags
}

# Configure Application Insights for the App Service
resource "azurerm_linux_web_app_slot" "staging" {
  count          = var.enable_staging_slot ? 1 : 0
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id
  
  site_config {
    always_on = true
    http2_enabled = true
    
    application_stack {
      node_version = "18-lts"
    }
    
    health_check_path = "/health"
    minimum_tls_version = "1.2"
  }
  
  app_settings = merge(azurerm_linux_web_app.main.app_settings, {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  })
  
  tags = var.tags
}

# Private endpoint for App Service (if enabled)
resource "azurerm_private_endpoint" "app_service" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${var.app_service_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  
  private_service_connection {
    name                           = "psc-${var.app_service_name}"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
  
  tags = var.tags
}