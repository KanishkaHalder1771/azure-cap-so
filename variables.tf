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
  default     = "capso.2vid.ai"
}

variable "minio_api_domain" {
  description = "Domain for MinIO API"
  type        = string
  default     = "api.minio.2vid.ai"
}

variable "minio_console_domain" {
  description = "Domain for MinIO Console"
  type        = string
  default     = "console.minio.2vid.ai"
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
  default     = "Standard_D2s_v3"
}

variable "minio_vm_size" {
  description = "Size of the MinIO Virtual Machine"
  type        = string
  default     = "Standard_D2s_v3"
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
  default     = "minio-secure-password-123"
  sensitive   = true
}

variable "minio_disk_size_gb" {
  description = "Size of the MinIO data disk in GB"
  type        = number
  default     = 100
}

# Cap Application Configuration
variable "database_encryption_key" {
  description = "Database encryption key for Cap"
  type        = string
  default     = "c7a1e98e1e5e4cec5a3fbf5eaf502d262fb99807ae2be8ee70537409e29cb6f9"
  sensitive   = true
}

variable "nextauth_secret" {
  description = "NextAuth secret for Cap"
  type        = string
  default     = "c7a1e98e1e5e4cec5a3fbf5eaf502d262fb99807ae2be8ee70537409e29cb6f9"
  sensitive   = true
}

variable "cap_aws_access_key" {
  description = "AWS/S3 access key for Cap (same as MinIO user)"
  type        = string
  default     = "minio-admin"
  sensitive   = true
}

variable "cap_aws_secret_key" {
  description = "AWS/S3 secret key for Cap (same as MinIO password)"
  type        = string
  default     = "minio-secure-password-123"
  sensitive   = true
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  default     = "capdb123"
  sensitive   = true
} 