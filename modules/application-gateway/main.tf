# Application Gateway Module - Creates Application Gateway for load balancing
# This module creates an Application Gateway with multi-region backend pools

# Public IP for Application Gateway
resource "azurerm_public_ip" "main" {
  name                = "pip-${var.application_gateway_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = lower("${var.application_gateway_name}-${random_id.pip_suffix.hex}")
  
  tags = var.tags
}

# Random suffix for unique public IP domain name
resource "random_id" "pip_suffix" {
  byte_length = 4
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = var.application_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  sku {
    name     = var.sku_name
    tier     = var.tier
  }
  
  # Autoscaling configuration
  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }
  
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }
  
  frontend_port {
    name = "frontend-port-80"
    port = 80
  }
  
  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  
  # Backend pools for both regions
  dynamic "backend_address_pool" {
    for_each = var.backend_pools
    content {
      name  = backend_address_pool.value.name
      fqdns = backend_address_pool.value.fqdns
    }
  }
  
  # Backend HTTP settings
  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    pick_host_name_from_backend_address = true
    
    # Health probe
    probe_name = "health-probe"
  }
  
  # Health probe
  probe {
    name                = "health-probe"
    protocol            = "Https"
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
    
    match {
      status_code = ["200-399"]
    }
  }
  
  # HTTP listener (main listener for now)
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }
  
  # SSL certificate (self-signed for demo) - DISABLED FOR NOW
  # ssl_certificate {
  #   name     = "ssl-certificate"
  #   data     = pkcs12_from_pem.ssl.result
  #   password = ""
  # }
  
  # Request routing rule for HTTP (main rule for now)
  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "primary-backend"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 100
  }
  
  # SSL policy to avoid deprecated TLS versions
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }
  
  # Redirect configuration for HTTP to HTTPS
  tags = var.tags
  
  depends_on = [
    azurerm_public_ip.main
  ]
}

# Generate SSL certificate for demo purposes
resource "tls_private_key" "ssl" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ssl" {
  private_key_pem = tls_private_key.ssl.private_key_pem
  
  subject {
    common_name  = azurerm_public_ip.main.fqdn
    organization = var.organization_name
  }
  
  dns_names = [azurerm_public_ip.main.fqdn]
  
  validity_period_hours = 8760 # 1 year
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}