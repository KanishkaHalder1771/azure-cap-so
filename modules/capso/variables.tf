variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where Cap VM will be deployed"
  type        = string
}

variable "load_balancer_backend_pool_id" {
  description = "ID of the Application Gateway backend pool for Cap"
  type        = string
}

variable "load_balancer_id" {
  description = "ID of the Application Gateway"
  type        = string
}

variable "load_balancer_public_ip" {
  description = "Public IP address of the Application Gateway"
  type        = string
}

variable "minio_internal_endpoint" {
  description = "Internal endpoint of the MinIO service"
  type        = string
}

variable "cap_domain" {
  description = "Domain for Cap service"
  type        = string
}

variable "minio_api_domain" {
  description = "Domain for MinIO API"
  type        = string
}

variable "vm_size" {
  description = "Size of the Cap virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the Cap VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}

variable "cap_disk_size_gb" {
  description = "Size of the persistent data disk for MySQL in GB"
  type        = number
  default     = 25
}

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
  description = "AWS access key for Cap (should match MinIO root user)"
  type        = string
}

variable "cap_aws_secret_key" {
  description = "AWS secret key for Cap (should match MinIO root password)"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "Root password for MySQL database"
  type        = string
  sensitive   = true
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