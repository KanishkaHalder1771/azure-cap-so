# Self-Hosting Infrastructure with Azure Application Gateway

> **Modular Terraform Infrastructure for Self-Hosted Services with Persistent Storage**

This repository provides a production-ready, modular Terraform configuration for deploying self-hosted services on Azure with intelligent load balancing, persistent storage, and domain-based access.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Application Gateway                    │
│                    (Layer 7 Load Balancer)                     │
│                                                                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │ capso.example.com   │ │api.minio.example.com│ │console.minio... │   │
│  │      :80        │ │      :80        │ │      :80        │   │
│  └─────────────────┘ ┌─────────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
           │                      │                      │
           ▼                      ▼                      ▼
    ┌─────────────┐        ┌─────────────┐
    │   Cap VM    │        │  MinIO VM   │
    │   :3000     │        │ :9000/:9001 │
    │             │        │             │
    │ ┌─────────┐ │        │ ┌─────────┐ │
    │ │ Cap App │ │        │ │  MinIO  │ │
    │ │ MySQL   │ │        │ │         │ │
    │ └─────────┘ │        │ └─────────┘ │
    └─────────────┘        │ ┌─────────┐ │
                           │ │Persistent│ │
                           │ │  Disk   │ │
                           │ │  50GB+  │ │
                           │ └─────────┘ │
                           └─────────────┘
```

## ✨ Key Features

- **🌐 Domain-Based Routing**: Access services via custom domains (no port numbers!)
- **🔄 Application Gateway**: Layer 7 load balancing with SSL termination support
- **💾 Persistent Storage**: MinIO data survives VM restarts and recreations
- **🧩 Modular Design**: Easily add new self-hosted services
- **🔒 Security**: Network isolation, SSH key authentication, and proper firewall rules
- **📊 Monitoring**: Built-in health checks and service status scripts
- **⚡ High Performance**: Optimized VM sizes and storage configurations

## 📁 Module Structure

```
.
├── main.tf                          # Root orchestration
├── variables.tf                     # Root variables
├── outputs.tf                       # Deployment information
├── terraform.tfvars.example         # Configuration template
├── modules/
│   ├── network/                     # Shared VNet & Security
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── load_balancer/              # Application Gateway
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── minio/                      # MinIO Object Storage
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── cloud-init.yml
│   └── capso/                      # Cap Screen Recording
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── cloud-init.yml
└── README.md
```

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install Terraform
brew install terraform  # macOS
# OR
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login
```

### 2. Configuration

```bash
# Clone and setup
git clone <your-repo-url>
cd cap-so

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Update with your values
```

**Required Configuration:**
```hcl
# terraform.tfvars
resource_group_name = "your-selfhost-rg"
location           = "East US"

# Update these domains to YOUR domains
cap_domain           = "capso.yourdomain.com"
minio_api_domain     = "api.minio.yourdomain.com"
minio_console_domain = "console.minio.yourdomain.com"

# SSH access
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Security (generate secure values)
database_encryption_key = "your-64-char-hex-key"
nextauth_secret        = "your-secure-nextauth-secret"
mysql_root_password    = "your-secure-mysql-password"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 4. Configure DNS Records

After deployment, configure DNS with your provider:

```bash
# Get Application Gateway IP from output
terraform output application_gateway_public_ip

# Create A records:
# capso.yourdomain.com        → APPLICATION_GATEWAY_IP
# api.minio.yourdomain.com    → APPLICATION_GATEWAY_IP
# console.minio.yourdomain.com → APPLICATION_GATEWAY_IP
```

### 5. Access Your Services

- **Cap Screen Recording**: `https://capso.yourdomain.com`
- **MinIO Console**: `https://console.minio.yourdomain.com`
- **MinIO S3 API**: `https://api.minio.yourdomain.com`

## 🔧 Module Details

### Network Module
- **VNet**: `10.0.0.0/16` with isolated subnets
- **Security Groups**: Firewall rules for SSH, HTTP, HTTPS, and service ports
- **Subnets**: Main subnet (`10.0.1.0/24`) + Application Gateway subnet (`10.0.2.0/24`)

### Application Gateway Module
- **Type**: Azure Application Gateway Standard_v2
- **Features**: Layer 7 routing, health probes, SSL termination ready
- **Routing**: Domain-based routing using Host headers
- **Backend Pools**: Separate pools for Cap and MinIO services

### MinIO Module
- **VM**: `Standard_B2s` with Ubuntu 22.04 LTS
- **Storage**: 100GB Premium SSD persistent disk
- **Services**: MinIO server (port 9000) + Console (port 9001)
- **Features**: Automatic disk mounting, health checks, backup scripts

### Cap Module
- **VM**: `Standard_B2s` with Ubuntu 22.04 LTS
- **Services**: Cap web app (port 3000) + MySQL database
- **Integration**: Connects to external MinIO for object storage

## 💾 Persistent Storage Details

### MinIO Storage Guarantees
- ✅ **Data survives VM restart**
- ✅ **Data survives VM stop/start**
- ✅ **Data survives VM recreation** (if disk is preserved)
- ✅ **Automatic mounting** on boot via `/etc/fstab`
- ✅ **Backup scripts** included

### Disk Management
```bash
# SSH into MinIO VM
ssh selfhostuser@MINIO_VM_IP

# Check disk status
sudo ./disk-info.sh

# Expand disk (after resizing in Azure)
sudo resize2fs /dev/sdc

# Manual backup
sudo ./backup-script.sh
```

## 🌐 Service Access Patterns

| Service | Domain | Port | Purpose |
|---------|--------|------|---------|
| Cap Web App | `capso.yourdomain.com` | 443 (HTTPS) | Screen recording interface |
| MinIO S3 API | `api.minio.yourdomain.com` | 443 (HTTPS) | S3-compatible storage API |
| MinIO Console | `console.minio.yourdomain.com` | 443 (HTTPS) | MinIO management interface |

## 🔐 Default Credentials

### MinIO
- **Username**: Set via `minio_root_user` variable
- **Password**: Set via `minio_root_password` variable
- **Access via**: https://console.minio.yourdomain.com

### MySQL (Cap Database)
- **Username**: `root`
- **Password**: Set via `mysql_root_password` variable
- **Access**: Internal to Cap VM only

## 🔍 Post-Deployment Verification

### Check Cap VM
```bash
# SSH to Cap VM
ssh selfhostuser@CAP_VM_IP

# Verify services
docker-compose -f /opt/cap/docker-compose.yml ps

# Check logs
docker-compose -f /opt/cap/docker-compose.yml logs cap-web
```

### Check MinIO VM
```bash
# SSH to MinIO VM
ssh selfhostuser@MINIO_VM_IP

# Verify services
docker-compose -f /opt/minio/docker-compose.yml ps

# Check persistent storage
df -h /mnt/minio-data
sudo ls -la /mnt/minio-data
```

### Test Application Gateway Routing
```bash
# Test Cap access
curl -H "Host: capso.yourdomain.com" http://APPLICATION_GATEWAY_IP

# Test MinIO API
curl -H "Host: api.minio.yourdomain.com" http://APPLICATION_GATEWAY_IP/minio/health/live

# Test MinIO Console
curl -H "Host: console.minio.yourdomain.com" http://APPLICATION_GATEWAY_IP
```

## 📈 Scaling and High Availability

### Adding More Services
1. Create new module in `modules/your-service/`
2. Add backend pool to Application Gateway
3. Configure routing rules
4. Update DNS records

### Storage Scaling
```bash
# Resize MinIO disk in Azure Portal or via CLI
az disk update --resource-group your-rg --name minio-data-disk --size-gb 200

# SSH to MinIO VM and expand filesystem
sudo resize2fs /dev/sdc
```

### VM Scaling
Update `vm_size` in variables and apply:
```bash
terraform apply -var="minio_vm_size=Standard_D2s_v3"
```

## 🛠️ Troubleshooting

### Common Issues

**Application Gateway not routing correctly**
```bash
# Check backend health
az network application-gateway show-backend-health \
  --resource-group your-rg \
  --name selfhost-application-gateway
```

**MinIO data disk not mounting**
```bash
# SSH to MinIO VM
ssh selfhostuser@MINIO_VM_IP

# Check disk status
lsblk
sudo blkid

# Manual mount
sudo mount /dev/sdc /mnt/minio-data
```

**Cap unable to connect to MinIO**
```bash
# Check network connectivity from Cap VM
ssh selfhostuser@CAP_VM_IP
curl http://MINIO_PRIVATE_IP:9000/minio/health/live
```

### Storage Issues
```bash
# Check MinIO data disk health
sudo fsck /dev/sdc

# View mount status
mount | grep minio-data

# Check /etc/fstab entry
cat /etc/fstab | grep minio-data
```

### Module Issues
```bash
# Re-run specific module
terraform apply -target=module.minio

# Destroy and recreate module
terraform destroy -target=module.capso
terraform apply -target=module.capso
```

## 🚀 Future Enhancements

- [ ] **SSL Certificates**: Automated Let's Encrypt or Azure-managed certificates
- [ ] **Auto-scaling**: VM scale sets for high availability
- [ ] **Monitoring**: Integration with Azure Monitor or Prometheus
- [ ] **Backup Automation**: Automated MinIO data backups to Azure Storage
- [ ] **Multiple Regions**: Cross-region deployment with traffic manager
- [ ] **Service Discovery**: Consul or similar for dynamic service registration

## 📖 DNS and SSL Setup Guide

For detailed instructions on configuring DNS records and SSL certificates, see our comprehensive guide:

- [DNS and SSL Setup Guide](dns_ssl_setup_guide.md)

## 📞 Support

For issues, questions, or contributions:
1. Check the troubleshooting section above
2. Review Terraform and Azure documentation
3. Open an issue in this repository
4. Consider professional Azure support for production deployments

---

**Happy Self-Hosting! 🏠✨** 