# Public IP for MinIO VM
resource "azurerm_public_ip" "minio_vm" {
  name                = "minio-vm-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

# Managed Disk for MinIO Data (Persistent Storage)
resource "azurerm_managed_disk" "minio_data" {
  name                 = "minio-data-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"  # High performance SSD
  create_option        = "Empty"
  disk_size_gb         = var.minio_disk_size_gb
}

# Network Interface for MinIO VM
resource "azurerm_network_interface" "minio" {
  name                = "minio-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.minio_vm.id
  }
}

# Associate MinIO VM with Application Gateway Backend Pool
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "minio" {
  network_interface_id    = azurerm_network_interface.minio.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.load_balancer_backend_pool_id
}

# MinIO Virtual Machine
resource "azurerm_linux_virtual_machine" "minio" {
  name                = "minio-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.minio.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
    minio_root_user        = var.minio_root_user
    minio_root_password    = var.minio_root_password
    minio_data_disk_device = "/dev/sdc"  # Standard for first additional disk
    minio_api_domain       = var.minio_api_domain
    minio_console_domain   = var.minio_console_domain
  }))
}

# Attach the managed disk to the VM
resource "azurerm_virtual_machine_data_disk_attachment" "minio_data" {
  managed_disk_id    = azurerm_managed_disk.minio_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.minio.id
  lun                = "0"
  caching            = "ReadWrite"
} 