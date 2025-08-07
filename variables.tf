variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "selfhost-rg"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

# Domain Configuration
variable "cap_domain" {
  description = "Domain for Cap service"
  type        = string
  default     = "capso.example.com"
}

variable "minio_api_domain" {
  description = "Domain for MinIO API"
  type        = string
  default     = "api.minio.example.com"
}

variable "minio_console_domain" {
  description = "Domain for MinIO Console"
  type        = string
  default     = "console.minio.example.com"
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the main subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "appgw_subnet_address_prefixes" {
  description = "Address prefixes for the Application Gateway subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# VM Configuration
variable "vm_size" {
  description = "Size of the Cap Virtual Machine"
  type        = string
  default     = "Standard_B1s"
}

variable "minio_vm_size" {
  description = "Size of the MinIO Virtual Machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "selfhostuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# MinIO Configuration
variable "minio_root_user" {
  description = "MinIO root username"
  type        = string
  default     = "minio-admin"
  sensitive   = true
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}

variable "minio_disk_size_gb" {
  description = "Size of the MinIO data disk in GB"
  type        = number
  default     = 100
}

variable "cap_disk_size_gb" {
  description = "Size of the Cap data disk for MySQL in GB"
  type        = number
  default     = 25
}

# Cap Application Configuration
variable "database_encryption_key" {
  description = "Database encryption key for Cap"
  type        = string
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret for Cap"
  type        = string
  sensitive   = true
}

variable "cap_aws_access_key" {
  description = "AWS/S3 access key for Cap (same as MinIO user)"
  type        = string
  sensitive   = true
}

variable "cap_aws_secret_key" {
  description = "AWS/S3 secret key for Cap (same as MinIO password)"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

# SSL Configuration
variable "ssl_enabled" {
  description = "Enable SSL certificate from Key Vault (1 = enabled, 0 = disabled)"
  type        = number
  default     = 0
  validation {
    condition     = var.ssl_enabled == 0 || var.ssl_enabled == 1
    error_message = "ssl_enabled must be either 0 (disabled) or 1 (enabled)."
  }
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault containing SSL certificates"
  type        = string
  default     = "kv-letsencrypt-example"
}

variable "key_vault_resource_group" {
  description = "Resource group of the Key Vault (if different from main resource group)"
  type        = string
  default     = ""
}

variable "ssl_certificate_name" {
  description = "Name of the SSL certificate in Key Vault"
  type        = string
  default     = "wildcard-example-com"
}

variable "resend_api_key" {
  description = "Resend API key for email functionality in Cap"
  type        = string
  sensitive   = true
}

variable "resend_from_domain" {
  description = "Resend from domain for email functionality in Cap"
  type        = string
} 