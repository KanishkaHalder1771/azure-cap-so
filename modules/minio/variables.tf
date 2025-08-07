variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where MinIO VM will be deployed"
  type        = string
}

variable "load_balancer_backend_pool_id" {
  description = "ID of the Application Gateway backend pool for MinIO"
  type        = string
}

variable "load_balancer_id" {
  description = "ID of the Application Gateway"
  type        = string
}

variable "vm_size" {
  description = "Size of the MinIO virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the MinIO VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}

variable "minio_root_user" {
  description = "MinIO root username"
  type        = string
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}

variable "minio_disk_size_gb" {
  description = "Size of the persistent data disk in GB"
  type        = number
  default     = 100
}

variable "minio_api_domain" {
  description = "Domain for MinIO API"
  type        = string
}

variable "minio_console_domain" {
  description = "Domain for MinIO Console"
  type        = string
} 