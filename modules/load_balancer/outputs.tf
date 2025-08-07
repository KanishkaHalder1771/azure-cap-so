output "public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.main.ip_address
}

output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

# Find backend pools by name using for expressions
output "cap_backend_pool_id" {
  description = "ID of the Cap backend pool"
  value       = [for pool in azurerm_application_gateway.main.backend_address_pool : pool.id if pool.name == "cap-backend-pool"][0]
}

output "minio_backend_pool_id" {
  description = "ID of the MinIO backend pool"
  value       = [for pool in azurerm_application_gateway.main.backend_address_pool : pool.id if pool.name == "minio-backend-pool"][0]
}

output "frontend_ip_configuration_name" {
  description = "Name of the frontend IP configuration"
  value       = "appgw-frontend-ip"
}

# Legacy compatibility outputs
output "load_balancer_id" {
  description = "ID of the Application Gateway (legacy compatibility)"
  value       = azurerm_application_gateway.main.id
}

output "load_balancer_public_ip" {
  description = "Public IP address of the Application Gateway (legacy compatibility)"
  value       = azurerm_public_ip.main.ip_address
}

output "backend_pool_id" {
  description = "ID of the Cap backend pool (legacy compatibility)"
  value       = [for pool in azurerm_application_gateway.main.backend_address_pool : pool.id if pool.name == "cap-backend-pool"][0]
} 