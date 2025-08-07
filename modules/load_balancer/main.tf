# Public IP for Application Gateway
resource "azurerm_public_ip" "main" {
  name                = "selfhost-appgw-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway Subnet
data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.appgw_subnet_address_prefixes
}

# User-Assigned Managed Identity for Application Gateway (when SSL is enabled)
resource "azurerm_user_assigned_identity" "appgw_identity" {
  count               = var.ssl_enabled == 1 ? 1 : 0
  name                = "selfhost-appgw-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Data source for existing Key Vault (when SSL is enabled)
data "azurerm_key_vault" "ssl_kv" {
  count               = var.ssl_enabled == 1 ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group != "" ? var.key_vault_resource_group : var.resource_group_name
}

data "azurerm_key_vault_certificate" "ssl_cert" {
  count        = var.ssl_enabled == 1 ? 1 : 0
  name         = var.ssl_certificate_name
  key_vault_id = data.azurerm_key_vault.ssl_kv[0].id
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

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

  # Add HTTPS port when SSL is enabled
  dynamic "frontend_port" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name = "port-443"
      port = 443
    }
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  # SSL Certificate from Key Vault (when SSL is enabled)
  dynamic "ssl_certificate" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name                = "keyvault-ssl-cert"
      key_vault_secret_id = data.azurerm_key_vault_certificate.ssl_cert[0].secret_id
    }
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
    
    probe_name = "minio-api-health-probe"
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
    
    probe_name = "minio-console-health-probe"
  }

  # HTTP Listeners (always present)
  http_listener {
    name                           = "cap-listener-http"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.cap_domain
  }

  http_listener {
    name                           = "minio-api-listener-http"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.minio_api_domain
  }

  http_listener {
    name                           = "minio-console-listener-http"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
    host_name                      = var.minio_console_domain
  }

  # HTTPS Listeners (when SSL is enabled)
  dynamic "http_listener" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name                           = "cap-listener-https"
      frontend_ip_configuration_name = "appgw-frontend-ip"
      frontend_port_name             = "port-443"
      protocol                       = "Https"
      host_name                      = var.cap_domain
      ssl_certificate_name           = "keyvault-ssl-cert"
    }
  }

  dynamic "http_listener" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name                           = "minio-api-listener-https"
      frontend_ip_configuration_name = "appgw-frontend-ip"
      frontend_port_name             = "port-443"
      protocol                       = "Https"
      host_name                      = var.minio_api_domain
      ssl_certificate_name           = "keyvault-ssl-cert"
    }
  }

  dynamic "http_listener" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name                           = "minio-console-listener-https"
      frontend_ip_configuration_name = "appgw-frontend-ip"
      frontend_port_name             = "port-443"
      protocol                       = "Https"
      host_name                      = var.minio_console_domain
      ssl_certificate_name           = "keyvault-ssl-cert"
    }
  }

  # HTTP Request Routing Rules (always present)
  request_routing_rule {
    name                       = "cap-routing-rule-http"
    rule_type                  = "Basic"
    http_listener_name         = "cap-listener-http"
    backend_address_pool_name  = "cap-backend-pool"
    backend_http_settings_name = "cap-http-settings"
    priority                   = 100
  }

  request_routing_rule {
    name                       = "minio-api-routing-rule-http"
    rule_type                  = "Basic"
    http_listener_name         = "minio-api-listener-http"
    backend_address_pool_name  = "minio-backend-pool"
    backend_http_settings_name = "minio-api-http-settings"
    priority                   = 200
  }

  request_routing_rule {
    name                       = "minio-console-routing-rule-http"
    rule_type                  = "Basic"
    http_listener_name         = "minio-console-listener-http"
    backend_address_pool_name  = "minio-backend-pool"
    backend_http_settings_name = "minio-console-http-settings"
    priority                   = 300
  }

  # HTTPS Request Routing Rules (when SSL is enabled)
  dynamic "request_routing_rule" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name                       = "cap-routing-rule-https"
      rule_type                  = "Basic"
      http_listener_name         = "cap-listener-https"
      backend_address_pool_name  = "cap-backend-pool"
      backend_http_settings_name = "cap-http-settings"
      priority                   = 400
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name                       = "minio-api-routing-rule-https"
      rule_type                  = "Basic"
      http_listener_name         = "minio-api-listener-https"
      backend_address_pool_name  = "minio-backend-pool"
      backend_http_settings_name = "minio-api-http-settings"
      priority                   = 500
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      name                       = "minio-console-routing-rule-https"
      rule_type                  = "Basic"
      http_listener_name         = "minio-console-listener-https"
      backend_address_pool_name  = "minio-backend-pool"
      backend_http_settings_name = "minio-console-http-settings"
      priority                   = 600
    }
  }

  # Health Probes
  probe {
    name                                      = "minio-api-health-probe"
    protocol                                  = "Http"
    path                                      = "/minio/health/live"
    host                                      = "127.0.0.1"
    interval                                  = 30
    timeout                                   = 20
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
    
    match {
      status_code = ["200"]
    }
  }
  
  probe {
    name                                      = "minio-console-health-probe"
    protocol                                  = "Http"
    path                                      = "/"
    host                                      = "127.0.0.1"
    interval                                  = 30
    timeout                                   = 20
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
    
    match {
      status_code = ["200"]
    }
  }

  # User-Assigned Managed Identity (when SSL is enabled)
  dynamic "identity" {
    for_each = var.ssl_enabled == 1 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.appgw_identity[0].id]
    }
  }

  depends_on = [
    azurerm_subnet.appgw_subnet
  ]
}

# Grant Application Gateway access to Key Vault (when SSL is enabled)
resource "azurerm_key_vault_access_policy" "appgw_ssl_access" {
  count        = var.ssl_enabled == 1 ? 1 : 0
  key_vault_id = data.azurerm_key_vault.ssl_kv[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw_identity[0].principal_id

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
} 