# DNS and SSL Setup Guide

> **Complete guide for configuring domain names and SSL certificates for your self-hosted infrastructure**

This guide walks you through setting up DNS records and SSL certificates for your self-hosted services deployed with Azure Application Gateway.

## 📋 Overview

After deploying the Terraform infrastructure, you'll have:
- ✅ Azure Application Gateway with a public IP
- ✅ Backend VMs running Cap and MinIO
- ❌ DNS records pointing to your domains
- ❌ SSL certificates for HTTPS access

This guide covers both of these missing pieces.

## 🌐 Step 1: Get Your Application Gateway IP

After running `terraform apply`, get the public IP address:

```bash
# Get the Application Gateway public IP
terraform output application_gateway_public_ip

# Example output: 20.123.45.67
```

**Save this IP address** - you'll need it for DNS configuration.

## 🔧 Step 2: Configure DNS Records

You need to create DNS A records for your three domains. The process varies by DNS provider:

### Required DNS Records

| Domain | Type | Value | Purpose |
|--------|------|-------|---------|
| `capso.yourdomain.com` | A | `APPLICATION_GATEWAY_IP` | Cap screen recording app |
| `api.minio.yourdomain.com` | A | `APPLICATION_GATEWAY_IP` | MinIO S3 API endpoint |
| `console.minio.yourdomain.com` | A | `APPLICATION_GATEWAY_IP` | MinIO web console |

### Common DNS Providers

#### Cloudflare
1. Log into Cloudflare dashboard
2. Select your domain
3. Go to **DNS** > **Records**
4. Add three A records:
   ```
   Type: A, Name: capso, Content: YOUR_APP_GATEWAY_IP, Proxy: Orange Cloud (Proxied)
   Type: A, Name: api.minio, Content: YOUR_APP_GATEWAY_IP, Proxy: Orange Cloud (Proxied)
   Type: A, Name: console.minio, Content: YOUR_APP_GATEWAY_IP, Proxy: Orange Cloud (Proxied)
   ```

#### Route 53 (AWS)
```bash
# Using AWS CLI
aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch '{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "capso.yourdomain.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "YOUR_APP_GATEWAY_IP"}]
      }
    },
    {
      "Action": "CREATE", 
      "ResourceRecordSet": {
        "Name": "api.minio.yourdomain.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "YOUR_APP_GATEWAY_IP"}]
      }
    },
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "console.minio.yourdomain.com", 
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "YOUR_APP_GATEWAY_IP"}]
      }
    }
  ]
}'
```

#### Google Cloud DNS
```bash
# Using gcloud CLI
gcloud dns record-sets transaction start --zone=YOUR_ZONE_NAME

gcloud dns record-sets transaction add YOUR_APP_GATEWAY_IP \
  --name=capso.yourdomain.com. --type=A --zone=YOUR_ZONE_NAME

gcloud dns record-sets transaction add YOUR_APP_GATEWAY_IP \
  --name=api.minio.yourdomain.com. --type=A --zone=YOUR_ZONE_NAME

gcloud dns record-sets transaction add YOUR_APP_GATEWAY_IP \
  --name=console.minio.yourdomain.com. --type=A --zone=YOUR_ZONE_NAME

gcloud dns record-sets transaction execute --zone=YOUR_ZONE_NAME
```

#### Generic DNS Provider
For most DNS providers, add these records via their web interface:
- **Host**: `capso` | **Type**: `A` | **Value**: `YOUR_APP_GATEWAY_IP`
- **Host**: `api.minio` | **Type**: `A` | **Value**: `YOUR_APP_GATEWAY_IP`
- **Host**: `console.minio` | **Type**: `A` | **Value**: `YOUR_APP_GATEWAY_IP`

### Verify DNS Propagation

Wait 5-15 minutes for DNS propagation, then test:

```bash
# Test DNS resolution
nslookup capso.yourdomain.com
nslookup api.minio.yourdomain.com
nslookup console.minio.yourdomain.com

# Test HTTP access (should work now)
curl -H "Host: capso.yourdomain.com" http://YOUR_APP_GATEWAY_IP
curl -H "Host: api.minio.yourdomain.com" http://YOUR_APP_GATEWAY_IP/minio/health/live
```

## 🔒 Step 3: SSL Certificate Options

You have several options for SSL certificates. Choose the one that best fits your needs:

### Option A: Cloudflare SSL (Recommended for Cloudflare users)

If you're using Cloudflare and enabled the orange cloud (proxy), SSL is automatic:

1. **Enable Cloudflare SSL**:
   - In Cloudflare dashboard → **SSL/TLS** → **Overview**
   - Set SSL mode to **Full** or **Full (Strict)**

2. **Test HTTPS access**:
   ```bash
   curl https://capso.yourdomain.com
   curl https://console.minio.yourdomain.com
   curl https://api.minio.yourdomain.com/minio/health/live
   ```

**Pros**: Easy, automatic renewal, free
**Cons**: Only works with Cloudflare proxy

### Option B: Azure Application Gateway SSL

Configure SSL certificates directly on the Application Gateway:

#### Using Azure-Managed Certificates (Easiest)

1. **Enable Azure managed certificates**:
   ```bash
   # Create managed certificate for each domain
   az network application-gateway ssl-cert create \
     --resource-group your-selfhost-rg \
     --gateway-name selfhost-application-gateway \
     --name capso-cert \
     --key-vault-secret-id https://your-keyvault.vault.azure.net/secrets/capso-cert
   ```

2. **Update Application Gateway listeners**:
   ```bash
   # Update listeners to use HTTPS
   az network application-gateway http-listener update \
     --resource-group your-selfhost-rg \
     --gateway-name selfhost-application-gateway \
     --name cap-listener \
     --frontend-port port-443 \
     --ssl-cert capso-cert
   ```

#### Using Let's Encrypt with Certbot

1. **SSH to a VM** (we'll use the Cap VM):
   ```bash
   ssh selfhostuser@CAP_VM_IP
   ```

2. **Install Certbot**:
   ```bash
   sudo apt update
   sudo apt install certbot -y
   ```

3. **Generate certificates**:
   ```bash
   # Generate certificates for all domains
   sudo certbot certonly --standalone --email your@email.com \
     -d capso.yourdomain.com \
     -d api.minio.yourdomain.com \
     -d console.minio.yourdomain.com
   ```

4. **Upload certificates to Azure**:
   ```bash
   # Convert to PFX format for Azure
   sudo openssl pkcs12 -export -out /tmp/cert.pfx \
     -inkey /etc/letsencrypt/live/capso.yourdomain.com/privkey.pem \
     -in /etc/letsencrypt/live/capso.yourdomain.com/fullchain.pem \
     -password pass:YourSecurePassword

   # Upload to Application Gateway
   az network application-gateway ssl-cert create \
     --resource-group your-selfhost-rg \
     --gateway-name selfhost-application-gateway \
     --name letsencrypt-cert \
     --cert-file /tmp/cert.pfx \
     --cert-password YourSecurePassword
   ```

**Pros**: Free, widely trusted, automatic renewal possible
**Cons**: Requires more setup, need renewal automation

### Option C: Commercial SSL Certificate

1. **Purchase SSL certificate** from a provider (Sectigo, DigiCert, etc.)
2. **Generate CSR** for your domains
3. **Upload certificate** to Azure Application Gateway
4. **Configure listeners** to use the certificate

## 🔧 Step 4: Update Application Services

After enabling SSL, update your services to use HTTPS URLs:

### Update Terraform Variables

```hcl
# In terraform.tfvars, ensure domains don't include protocol
cap_domain           = "capso.yourdomain.com"        # ✅ Correct
minio_api_domain     = "api.minio.yourdomain.com"    # ✅ Correct
minio_console_domain = "console.minio.yourdomain.com" # ✅ Correct

# NOT:
cap_domain           = "https://capso.yourdomain.com" # ❌ Wrong
```

### Update MinIO Configuration

SSH to MinIO VM and update the configuration:

```bash
ssh selfhostuser@MINIO_VM_IP

# Edit MinIO docker-compose.yml
sudo nano /opt/minio/docker-compose.yml

# Update environment variables:
# MINIO_SERVER_URL=https://api.minio.yourdomain.com
# MINIO_BROWSER_REDIRECT_URL=https://console.minio.yourdomain.com

# Restart MinIO
sudo systemctl restart minio.service
```

### Update Cap Configuration

SSH to Cap VM and update the configuration:

```bash
ssh selfhostuser@CAP_VM_IP

# The cloud-init template should automatically set:
# WEB_URL=https://capso.yourdomain.com
# S3_PUBLIC_ENDPOINT=https://api.minio.yourdomain.com

# Restart Cap if needed
sudo systemctl restart cap.service
```

## ✅ Step 5: Verification

Test all your services with HTTPS:

### Test Cap Application
```bash
# Test Cap web interface
curl -I https://capso.yourdomain.com
# Should return 200 OK

# Test in browser
open https://capso.yourdomain.com
```

### Test MinIO Services
```bash
# Test MinIO API health
curl https://api.minio.yourdomain.com/minio/health/live
# Should return {"status":"ok"}

# Test MinIO Console
curl -I https://console.minio.yourdomain.com
# Should return 200 OK or redirect

# Login to MinIO Console
open https://console.minio.yourdomain.com
# Use credentials: minio-admin / minio-secure-password-123
```

### Test S3 API Access
```bash
# Install AWS CLI if not already installed
pip install awscli

# Configure AWS CLI for MinIO
aws configure set aws_access_key_id minio-admin
aws configure set aws_secret_access_key minio-secure-password-123
aws configure set default.region us-east-1

# Test S3 API
aws s3 ls --endpoint-url https://api.minio.yourdomain.com
# Should list buckets: capso, nextcloud, backup
```

## 🔄 Step 6: SSL Renewal Automation

### For Let's Encrypt Certificates

Set up automatic renewal:

```bash
# SSH to the VM where you generated certificates
ssh selfhostuser@CAP_VM_IP

# Create renewal script
sudo nano /opt/ssl-renewal.sh
```

```bash
#!/bin/bash
# SSL Certificate Renewal Script

# Renew certificates
certbot renew --quiet

# Convert to PFX format
openssl pkcs12 -export -out /tmp/cert-new.pfx \
  -inkey /etc/letsencrypt/live/capso.yourdomain.com/privkey.pem \
  -in /etc/letsencrypt/live/capso.yourdomain.com/fullchain.pem \
  -password pass:YourSecurePassword

# Upload to Application Gateway
az network application-gateway ssl-cert update \
  --resource-group your-selfhost-rg \
  --gateway-name selfhost-application-gateway \
  --name letsencrypt-cert \
  --cert-file /tmp/cert-new.pfx \
  --cert-password YourSecurePassword

# Clean up
rm /tmp/cert-new.pfx

echo "SSL certificates renewed successfully"
```

```bash
# Make script executable
sudo chmod +x /opt/ssl-renewal.sh

# Add to crontab for monthly renewal
sudo crontab -e
# Add line: 0 2 1 * * /opt/ssl-renewal.sh >> /var/log/ssl-renewal.log 2>&1
```

## 🚨 Troubleshooting

### DNS Issues

**Problem**: DNS not resolving
```bash
# Check DNS propagation
dig capso.yourdomain.com
nslookup capso.yourdomain.com 8.8.8.8

# Clear local DNS cache
sudo systemctl flush-dns  # Linux
sudo dscacheutil -flushcache  # macOS
```

### SSL Issues

**Problem**: SSL certificate errors
```bash
# Check certificate details
openssl s_client -connect capso.yourdomain.com:443 -servername capso.yourdomain.com

# Check Application Gateway SSL configuration
az network application-gateway ssl-cert list \
  --resource-group your-selfhost-rg \
  --gateway-name selfhost-application-gateway
```

**Problem**: Mixed content warnings
- Ensure all internal links use HTTPS
- Update MinIO and Cap configurations to use HTTPS endpoints

### Service Access Issues

**Problem**: 502 Bad Gateway
```bash
# Check Application Gateway backend health
az network application-gateway show-backend-health \
  --resource-group your-selfhost-rg \
  --name selfhost-application-gateway

# Check if services are running on VMs
ssh selfhostuser@CAP_VM_IP 'docker-compose -f /opt/cap/docker-compose.yml ps'
ssh selfhostuser@MINIO_VM_IP 'docker-compose -f /opt/minio/docker-compose.yml ps'
```

## 🎯 Production Recommendations

### Security
- ✅ Use strong SSL configurations (TLS 1.2+)
- ✅ Enable HSTS headers
- ✅ Consider using a Web Application Firewall (WAF)
- ✅ Regularly update certificates

### Monitoring
- ✅ Set up certificate expiration monitoring
- ✅ Monitor Application Gateway health
- ✅ Set up alerts for SSL certificate issues

### Backup
- ✅ Backup SSL certificates and private keys
- ✅ Document your SSL setup process
- ✅ Test certificate renewal process regularly

## 📚 Additional Resources

- [Azure Application Gateway SSL Documentation](https://docs.microsoft.com/en-us/azure/application-gateway/ssl-overview)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Cloudflare SSL Documentation](https://developers.cloudflare.com/ssl/)
- [MinIO Security Guide](https://min.io/docs/minio/linux/operations/network-encryption.html)

---

**🎉 Congratulations!** Your self-hosted infrastructure is now secured with SSL and accessible via custom domains! 