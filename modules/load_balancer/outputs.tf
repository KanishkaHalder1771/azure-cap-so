output "public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.main.ip_address
}

output "public_ip_id" {
  description = "ID of the Application Gateway Public IP"
  value       = azurerm_public_ip.main.id
}

output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "cap_backend_pool_id" {
  description = "ID of the Cap Backend Pool"
  value       = azurerm_application_gateway.main.backend_address_pool[0].id
}

output "minio_backend_pool_id" {
  description = "ID of the MinIO Backend Pool"
  value       = azurerm_application_gateway.main.backend_address_pool[1].id
}

output "frontend_ip_configuration_name" {
  description = "Name of the frontend IP configuration"
  value       = "appgw-frontend-ip"
}

# Legacy outputs for compatibility (will be deprecated)
output "load_balancer_id" {
  description = "ID of the Application Gateway (legacy compatibility)"
  value       = azurerm_application_gateway.main.id
}

output "backend_pool_id" {
  description = "ID of the Cap Backend Pool (legacy compatibility)"
  value       = azurerm_application_gateway.main.backend_address_pool[0].id
} 