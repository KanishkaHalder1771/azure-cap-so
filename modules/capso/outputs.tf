output "vm_public_ip" {
  description = "Public IP address of the Cap VM"
  value       = azurerm_public_ip.capso_vm.ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the Cap VM"
  value       = azurerm_network_interface.capso.private_ip_address
}

output "vm_name" {
  description = "Name of the Cap VM"
  value       = azurerm_linux_virtual_machine.capso.name
}

output "ssh_connection_command" {
  description = "SSH command to connect to the Cap VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.capso_vm.ip_address}"
}

output "data_disk_id" {
  description = "ID of the Cap data disk"
  value       = azurerm_managed_disk.capso_data.id
}

output "data_disk_size_gb" {
  description = "Size of the Cap data disk in GB"
  value       = azurerm_managed_disk.capso_data.disk_size_gb
} 