variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for services (not used with App Gateway)"
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "appgw_subnet_address_prefixes" {
  description = "Address prefixes for the Application Gateway subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# Domain Configuration
variable "cap_domain" {
  description = "Domain for Cap service"
  type        = string
}

variable "minio_api_domain" {
  description = "Domain for MinIO API"
  type        = string
}

variable "minio_console_domain" {
  description = "Domain for MinIO Console"
  type        = string
} 