# DNS and SSL Setup Guide

This guide will help you configure DNS records and SSL certificates for your self-hosted infrastructure.

## 📋 **Prerequisites**

After deploying with Terraform, you'll have:
- Load Balancer with a public IP address
- Domain names configured:
  - `capso.2vid.ai` - Cap application
  - `api.minio.2vid.ai` - MinIO API
  - `console.minio.2vid.ai` - MinIO Console

## 🌐 **Step 1: Configure DNS Records**

### Get Your Load Balancer IP
```bash
# After Terraform deployment
terraform output load_balancer_public_ip

# Or check Azure Portal: Resource Groups → Your RG → selfhost-lb-public-ip
```

### Create DNS A Records
In your DNS provider (Cloudflare, Route53, etc.), create these A records:

```
capso.2vid.ai           → YOUR_LOAD_BALANCER_IP
api.minio.2vid.ai       → YOUR_LOAD_BALANCER_IP  
console.minio.2vid.ai   → YOUR_LOAD_BALANCER_IP
```

### DNS Verification
```bash
# Test DNS resolution
nslookup capso.2vid.ai
nslookup api.minio.2vid.ai
nslookup console.minio.2vid.ai

# All should resolve to your Load Balancer IP
```

## 🔒 **Step 2: SSL Certificate Options**

### Option A: Cloudflare (Recommended - Easiest)

1. **Add domains to Cloudflare**:
   - Add `2vid.ai` to Cloudflare
   - Create the A records in Cloudflare dashboard
   - Enable "Proxied" (orange cloud) for all records

2. **Configure SSL/TLS**:
   - Go to SSL/TLS → Overview
   - Set encryption mode to "Full" or "Full (strict)"
   - Enable "Always Use HTTPS"

3. **Benefits**:
   - ✅ Free SSL certificates
   - ✅ Automatic renewal
   - ✅ DDoS protection
   - ✅ CDN acceleration

### Option B: Let's Encrypt with Certbot

1. **SSH to one of your VMs** (preferably Cap VM for web certificates):
   ```bash
   ssh selfhostuser@CAP_VM_IP
   ```

2. **Install Certbot**:
   ```bash
   sudo apt update
   sudo apt install certbot python3-certbot-nginx -y
   ```

3. **Install Nginx** (for SSL termination):
   ```bash
   sudo apt install nginx -y
   sudo systemctl enable nginx
   sudo systemctl start nginx
   ```

4. **Configure Nginx** for domain routing:
   ```bash
   sudo nano /etc/nginx/sites-available/selfhost
   ```

   Add this configuration:
   ```nginx
   # Cap Service
   server {
       listen 80;
       listen 443 ssl;
       server_name capso.2vid.ai;
       
       ssl_certificate /etc/letsencrypt/live/capso.2vid.ai/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/capso.2vid.ai/privkey.pem;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   
   # MinIO API
   server {
       listen 80;
       listen 443 ssl;
       server_name api.minio.2vid.ai;
       
       ssl_certificate /etc/letsencrypt/live/api.minio.2vid.ai/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/api.minio.2vid.ai/privkey.pem;
       
       location / {
           proxy_pass http://MINIO_PRIVATE_IP:9000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   
   # MinIO Console
   server {
       listen 80;
       listen 443 ssl;
       server_name console.minio.2vid.ai;
       
       ssl_certificate /etc/letsencrypt/live/console.minio.2vid.ai/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/console.minio.2vid.ai/privkey.pem;
       
       location / {
           proxy_pass http://MINIO_PRIVATE_IP:9001;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

5. **Enable the site**:
   ```bash
   sudo ln -s /etc/nginx/sites-available/selfhost /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

6. **Get SSL certificates**:
   ```bash
   sudo certbot --nginx -d capso.2vid.ai -d api.minio.2vid.ai -d console.minio.2vid.ai
   ```

7. **Setup auto-renewal**:
   ```bash
   sudo crontab -e
   # Add this line:
   0 12 * * * /usr/bin/certbot renew --quiet
   ```

## 🔧 **Step 3: Update MinIO Configuration**

### Set MinIO Domain in Environment
SSH to MinIO VM and update the MinIO configuration:

```bash
ssh selfhostuser@MINIO_VM_IP

# Edit MinIO docker-compose
sudo nano /opt/minio/docker-compose.yml
```

Add these environment variables to MinIO service:
```yaml
environment:
  - MINIO_API_PORT_NUMBER=9000
  - MINIO_CONSOLE_PORT_NUMBER=9001
  - MINIO_ROOT_USER=${minio_root_user}
  - MINIO_ROOT_PASSWORD=${minio_root_password}
  - MINIO_DEFAULT_BUCKETS=capso,nextcloud,backup
  - MINIO_SERVER_URL=https://api.minio.2vid.ai
  - MINIO_BROWSER_REDIRECT_URL=https://console.minio.2vid.ai
```

Restart MinIO:
```bash
sudo systemctl restart minio.service
```

## ✅ **Step 4: Verification**

### Test HTTPS Access
```bash
# Test Cap application
curl -I https://capso.2vid.ai

# Test MinIO API
curl -I https://api.minio.2vid.ai/minio/health/live

# Test MinIO Console
curl -I https://console.minio.2vid.ai
```

### Test HTTP to HTTPS Redirect
```bash
# Should redirect to HTTPS
curl -I http://capso.2vid.ai
curl -I http://api.minio.2vid.ai
curl -I http://console.minio.2vid.ai
```

### Access in Browser
- ✅ **Cap**: https://capso.2vid.ai
- ✅ **MinIO Console**: https://console.minio.2vid.ai
- ✅ **MinIO API**: https://api.minio.2vid.ai

## 🚀 **Step 5: Update Cap Configuration**

### Update Cap Environment Variables
SSH to Cap VM and update the S3 endpoints:

```bash
ssh selfhostuser@CAP_VM_IP

# Edit Cap docker-compose
sudo nano /opt/cap/docker-compose.yml
```

Update these environment variables:
```yaml
environment:
  # ... other variables ...
  S3_PUBLIC_ENDPOINT: https://api.minio.2vid.ai
  S3_INTERNAL_ENDPOINT: http://MINIO_PRIVATE_IP:9000  # Keep internal as HTTP for performance
```

Restart Cap:
```bash
sudo systemctl restart cap.service
```

## 📊 **Monitoring and Maintenance**

### SSL Certificate Monitoring
```bash
# Check certificate expiry
echo | openssl s_client -servername capso.2vid.ai -connect capso.2vid.ai:443 2>/dev/null | openssl x509 -noout -dates
```

### DNS Monitoring
```bash
# Check DNS propagation
dig +short capso.2vid.ai
dig +short api.minio.2vid.ai
dig +short console.minio.2vid.ai
```

## 🔄 **MinIO Disk Expansion (Confirmed Working)**

Azure Managed Disks support online expansion without data loss:

### Via Azure Portal
1. Navigate to: Azure Portal → Resource Groups → Your RG → `minio-data-disk`
2. Click "Size + performance"
3. Increase the size (can only increase, not decrease)
4. Click "Resize"

### Via Azure CLI
```bash
az disk update --resource-group selfhost-rg --name minio-data-disk --size-gb 200
```

### Expand Filesystem
```bash
# SSH to MinIO VM
ssh selfhostuser@MINIO_VM_IP

# Expand filesystem to use new space
sudo resize2fs /dev/sdc

# Verify expansion
df -h /mnt/minio-data
```

### Benefits of Azure Managed Disks
✅ **Online Expansion**: No downtime required  
✅ **Data Persistence**: Data survives VM restarts, stops, and recreation  
✅ **Automatic Backup**: Point-in-time snapshots available  
✅ **High Performance**: Premium SSD with consistent IOPS  
✅ **Encryption**: Data encrypted at rest by default  

## 🛠️ **Troubleshooting**

### DNS Issues
```bash
# Clear DNS cache
sudo systemctl flush-dns

# Test from different locations
dig @8.8.8.8 capso.2vid.ai
dig @1.1.1.1 capso.2vid.ai
```

### SSL Issues
```bash
# Test SSL certificate
openssl s_client -connect capso.2vid.ai:443 -servername capso.2vid.ai

# Check certificate chain
curl -vI https://capso.2vid.ai
```

### Service Issues
```bash
# Check Cap service
ssh selfhostuser@CAP_VM_IP 'sudo /opt/cap/check-services.sh'

# Check MinIO service
ssh selfhostuser@MINIO_VM_IP 'sudo /opt/minio/check-minio.sh'
```

## 🎯 **Final Architecture**

```
Internet (HTTPS) → DNS → Load Balancer → VMs
                           ↓
    capso.2vid.ai         → Cap VM:3000
    api.minio.2vid.ai     → MinIO VM:9000  
    console.minio.2vid.ai → MinIO VM:9001
                           ↓
                    Persistent Storage (100GB+, expandable)
```

Your self-hosted infrastructure is now production-ready with proper DNS, SSL, and expandable storage! 🎉 