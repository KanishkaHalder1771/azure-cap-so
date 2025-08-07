terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Network Module
module "network" {
  source = "./modules/network"
  
  resource_group_name     = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  vnet_address_space     = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes

  depends_on = [
    azurerm_resource_group.main
  ]
}

# Application Gateway Module
module "load_balancer" {
  source = "./modules/load_balancer"
  
  resource_group_name              = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  subnet_id                       = module.network.subnet_id
  vnet_name                       = module.network.vnet_name
  appgw_subnet_address_prefixes   = var.appgw_subnet_address_prefixes
  
  # Domain Configuration
  cap_domain           = var.cap_domain
  minio_api_domain     = var.minio_api_domain
  minio_console_domain = var.minio_console_domain
  
  # SSL Configuration
  ssl_enabled              = var.ssl_enabled
  key_vault_name          = var.key_vault_name
  key_vault_resource_group = var.key_vault_resource_group != "" ? var.key_vault_resource_group : azurerm_resource_group.main.name
  ssl_certificate_name    = var.ssl_certificate_name

  depends_on = [
    azurerm_resource_group.main
  ]
}

# MinIO Storage Module
module "minio" {
  source = "./modules/minio"
  
  resource_group_name           = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  subnet_id                    = module.network.subnet_id
  load_balancer_backend_pool_id = module.load_balancer.minio_backend_pool_id
  load_balancer_id             = module.load_balancer.application_gateway_id
  
  # Domain Configuration
  minio_api_domain     = var.minio_api_domain
  minio_console_domain = var.minio_console_domain
  
  # VM Configuration
  vm_size             = var.minio_vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  
  # MinIO Configuration
  minio_root_user        = var.minio_root_user
  minio_root_password    = var.minio_root_password
  minio_disk_size_gb     = var.minio_disk_size_gb

  depends_on = [
    azurerm_resource_group.main,
    module.network,
    module.load_balancer
  ]
}

# Cap Service Module
module "capso" {
  source = "./modules/capso"
  
  resource_group_name           = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  subnet_id                    = module.network.subnet_id
  load_balancer_backend_pool_id = module.load_balancer.cap_backend_pool_id
  load_balancer_id             = module.load_balancer.application_gateway_id
  load_balancer_public_ip      = module.load_balancer.public_ip
  minio_internal_endpoint      = module.minio.minio_api_endpoint
  
  # Domain Configuration
  cap_domain           = var.cap_domain
  minio_api_domain     = var.minio_api_domain
  
  # VM Configuration
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  cap_disk_size_gb    = var.cap_disk_size_gb
  
  # Application Configuration
  database_encryption_key = var.database_encryption_key
  nextauth_secret        = var.nextauth_secret
  cap_aws_access_key     = var.cap_aws_access_key
  cap_aws_secret_key     = var.cap_aws_secret_key
  mysql_root_password    = var.mysql_root_password
  resend_api_key         = var.resend_api_key
  resend_from_domain     = var.resend_from_domain

  depends_on = [
    azurerm_resource_group.main,
    module.network,
    module.load_balancer,
    module.minio
  ]
} 