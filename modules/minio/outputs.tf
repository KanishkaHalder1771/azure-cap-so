output "vm_public_ip" {
  description = "Public IP address of the MinIO VM"
  value       = azurerm_public_ip.minio_vm.ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the MinIO VM"
  value       = azurerm_network_interface.minio.private_ip_address
}

output "vm_name" {
  description = "Name of the MinIO VM"
  value       = azurerm_linux_virtual_machine.minio.name
}

output "ssh_connection_command" {
  description = "SSH command to connect to the MinIO VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.minio_vm.ip_address}"
}

output "minio_api_endpoint" {
  description = "Internal MinIO API endpoint"
  value       = "http://${azurerm_network_interface.minio.private_ip_address}:9000"
}

output "minio_console_endpoint" {
  description = "Internal MinIO Console endpoint"
  value       = "http://${azurerm_network_interface.minio.private_ip_address}:9001"
}

output "data_disk_id" {
  description = "ID of the MinIO data disk"
  value       = azurerm_managed_disk.minio_data.id
}

output "data_disk_size_gb" {
  description = "Size of the MinIO data disk in GB"
  value       = azurerm_managed_disk.minio_data.disk_size_gb
} 