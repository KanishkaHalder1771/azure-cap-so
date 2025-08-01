# Public IP for VM
resource "azurerm_public_ip" "capso_vm" {
  name                = "capso-vm-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

# Network Interface
resource "azurerm_network_interface" "capso" {
  name                = "capso-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.capso_vm.id
  }
}

# Associate VM with Application Gateway Backend Pool
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "capso" {
  network_interface_id    = azurerm_network_interface.capso.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.load_balancer_backend_pool_id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "capso" {
  name                = "capso-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.capso.id,
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
    database_encryption_key = var.database_encryption_key
    nextauth_secret        = var.nextauth_secret
    cap_aws_access_key     = var.cap_aws_access_key
    cap_aws_secret_key     = var.cap_aws_secret_key
    mysql_root_password    = var.mysql_root_password
    web_url               = "https://${var.cap_domain}"
    s3_public_endpoint    = "https://${var.minio_api_domain}"
    s3_internal_endpoint  = var.minio_internal_endpoint
  }))
} 