output "vm_public_ip" {
  description = "Public IP address of the Cap VM"
  value       = azurerm_public_ip.cap_vm.ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the Cap VM"
  value       = azurerm_network_interface.cap.private_ip_address
}

output "vm_name" {
  description = "Name of the Cap VM"
  value       = azurerm_linux_virtual_machine.cap.name
}

output "ssh_connection_command" {
  description = "SSH command to connect to the Cap VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.cap_vm.ip_address}"
} 