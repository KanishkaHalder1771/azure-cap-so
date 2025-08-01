# Public IP for Application Gateway
resource "azurerm_public_ip" "main" {
  name                = "selfhost-appgw-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway Subnet (required separate subnet)
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.appgw_subnet_address_prefixes
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "selfhost-application-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_port {
    name = "port-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  # Backend Address Pools
  backend_address_pool {
    name = "cap-backend-pool"
  }

  backend_address_pool {
    name = "minio-backend-pool"
  }

  # Backend HTTP Settings
  backend_http_settings {
    name                  = "cap-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = ""
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 60
  }

  backend_http_settings {
    name                  = "minio-api-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = ""
    port                  = 9000
    protocol              = "Http"
    request_timeout       = 300
    # Important for MinIO S3 API
    pick_host_name_from_backend_address = false
  }

  backend_http_settings {
    name                  = "minio-console-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = ""
    port                  = 9001
    protocol              = "Http"
    request_timeout       = 60
    # Important for MinIO Console
    pick_host_name_from_backend_address = false
  }

  # HTTP Listeners
  http_listener {
    name                           = "cap-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.cap_domain
  }

  http_listener {
    name                           = "minio-api-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.minio_api_domain
  }

  http_listener {
    name                           = "minio-console-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.minio_console_domain
  }

  # Request Routing Rules
  request_routing_rule {
    name                       = "cap-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "cap-listener"
    backend_address_pool_name  = "cap-backend-pool"
    backend_http_settings_name = "cap-http-settings"
    priority                   = 100
  }

  request_routing_rule {
    name                       = "minio-api-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "minio-api-listener"
    backend_address_pool_name  = "minio-backend-pool"
    backend_http_settings_name = "minio-api-http-settings"
    priority                   = 200
  }

  request_routing_rule {
    name                       = "minio-console-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "minio-console-listener"
    backend_address_pool_name  = "minio-backend-pool"
    backend_http_settings_name = "minio-console-http-settings"
    priority                   = 300
  }
} 