output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = module.load_balancer.public_ip
}

output "capso_vm_public_ip" {
  description = "Public IP address of the Cap VM"
  value       = module.capso.vm_public_ip
}

output "minio_vm_public_ip" {
  description = "Public IP address of the MinIO VM"
  value       = module.minio.vm_public_ip
}

output "cap_web_url" {
  description = "URL to access Cap Web application"
  value       = "https://${var.cap_domain}"
}

output "minio_console_url" {
  description = "URL to access MinIO Console"
  value       = "https://${var.minio_console_domain}"
}

output "minio_api_url" {
  description = "URL to access MinIO API"
  value       = "https://${var.minio_api_domain}"
}

output "dns_configuration" {
  description = "DNS records to configure"
  value = {
    application_gateway_ip = module.load_balancer.public_ip
    dns_records = {
      cap_domain           = "${var.cap_domain} → ${module.load_balancer.public_ip}"
      minio_api_domain     = "${var.minio_api_domain} → ${module.load_balancer.public_ip}"
      minio_console_domain = "${var.minio_console_domain} → ${module.load_balancer.public_ip}"
    }
    routing_explanation = "Application Gateway uses Layer 7 routing based on Host headers"
  }
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to VMs"
  value = {
    cap_vm   = module.capso.ssh_connection_command
    minio_vm = module.minio.ssh_connection_command
  }
}

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "network_info" {
  description = "Network information"
  value = {
    vnet_name                  = module.network.vnet_name
    subnet_name                = module.network.subnet_name
    main_subnet_prefix         = var.subnet_address_prefixes[0]
    appgw_subnet_prefix        = var.appgw_subnet_address_prefixes[0]
  }
}

output "storage_info" {
  description = "MinIO storage information"
  value = {
    data_disk_size_gb = module.minio.data_disk_size_gb
    minio_vm_name     = module.minio.vm_name
    internal_endpoint = module.minio.minio_api_endpoint
    expandable        = "Yes - Azure Managed Disks support online expansion without data loss"
  }
}

output "application_gateway_info" {
  description = "Application Gateway routing information"
  value = {
    type                = "Azure Application Gateway (Layer 7)"
    routing_method      = "Domain-based (Host header inspection)"
    ssl_termination     = "Supported (configure certificates after deployment)"
    health_checks       = "Built-in health probes"
    domain_routing = {
      "${var.cap_domain}"           = "Cap VM:3000"
      "${var.minio_api_domain}"     = "MinIO VM:9000 (S3 API)"
      "${var.minio_console_domain}" = "MinIO VM:9001 (Console)"
    }
  }
}

output "deployment_info" {
  description = "Important deployment information"
  value = {
    architecture             = "Azure Application Gateway → Domain-based routing → Backend VMs"
    cap_web_url             = "https://${var.cap_domain}"
    minio_console_url       = "https://${var.minio_console_domain}"
    minio_api_url           = "https://${var.minio_api_domain}"
    application_gateway_ip   = module.load_balancer.public_ip
    dns_setup_required      = "Yes - Configure DNS A records to point domains to Application Gateway IP"
    ssl_setup_recommended   = "Yes - Configure SSL certificates on Application Gateway"
    ssh_cap_vm              = module.capso.ssh_connection_command
    ssh_minio_vm            = module.minio.ssh_connection_command
    status_check_cap        = "ssh ${var.admin_username}@${module.capso.vm_public_ip} 'sudo /opt/cap/check-services.sh'"
    status_check_minio      = "ssh ${var.admin_username}@${module.minio.vm_public_ip} 'sudo /opt/minio/check-minio.sh'"
    disk_expansion_guide    = "To expand MinIO disk: Azure Portal → minio-data-disk → Size + Performance → Increase size → SSH to MinIO VM → sudo resize2fs /dev/sdc"
    routing_explanation     = "Application Gateway inspects Host headers to route capso.2vid.ai → Cap VM, api.minio.2vid.ai → MinIO API, console.minio.2vid.ai → MinIO Console"
  }
}

# Legacy outputs for compatibility
output "load_balancer_public_ip" {
  description = "Public IP address of the Application Gateway (legacy name for compatibility)"
  value       = module.load_balancer.public_ip
} 