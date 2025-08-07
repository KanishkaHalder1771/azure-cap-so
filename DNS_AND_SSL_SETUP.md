# DNS and SSL Setup Guide

Simple guide for configuring DNS records and SSL certificates for your self-hosted infrastructure.

## 📋 Prerequisites

After deploying with Terraform, you'll have:
- Application Gateway with a public IP address
- Three domains configured in your `terraform.tfvars`:
  - `capso.example.com` - Cap application
  - `api.minio.example.com` - MinIO API
  - `console.minio.example.com` - MinIO Console

## 🌐 Step 1: Get Your Application Gateway IP

```bash
# After Terraform deployment
terraform output application_gateway_public_ip

# Save this IP - you'll need it for DNS configuration
```

## 🔧 Step 2: Configure DNS Records

### Simple DNS Setup

In your DNS provider (Cloudflare, Route53, etc.), create these A records:

```
capso.example.com           → YOUR_APPLICATION_GATEWAY_IP
api.minio.example.com       → YOUR_APPLICATION_GATEWAY_IP  
console.minio.example.com   → YOUR_APPLICATION_GATEWAY_IP
```

### Cloudflare (Recommended)
1. Log into Cloudflare dashboard
2. Select your domain
3. Go to **DNS** > **Records**
4. Add three A records:
   - `capso` → `YOUR_APPLICATION_GATEWAY_IP` (Proxied: ✅)
   - `api.minio` → `YOUR_APPLICATION_GATEWAY_IP` (Proxied: ✅)
   - `console.minio` → `YOUR_APPLICATION_GATEWAY_IP` (Proxied: ✅)

### Other DNS Providers
- **Name/Host**: `capso`, `api.minio`, `console.minio`
- **Type**: `A`
- **Value**: `YOUR_APPLICATION_GATEWAY_IP`

### Verify DNS
```bash
# Test DNS resolution (wait 5-15 minutes for propagation)
nslookup capso.example.com
nslookup api.minio.example.com
nslookup console.minio.example.com
```

## 🔒 Step 3: SSL Certificate Setup

### Option A: Cloudflare SSL (Recommended - Easiest)

If using Cloudflare with proxied records:

1. **Enable SSL in Cloudflare**:
   - Go to SSL/TLS → Overview
   - Set encryption mode to **"Full"**
   - Enable **"Always Use HTTPS"**

2. **Done!** SSL is now automatic with free certificates and auto-renewal.

### Option B: Azure Key Vault with shibayan/keyvault-acmebot

If you have a Key Vault managed by [shibayan/keyvault-acmebot](https://github.com/shibayan/keyvault-acmebot):

1. **Create certificates in your acmebot Key Vault** for your domains
2. **Configure Terraform variables** in `terraform.tfvars`:
   ```hcl
   ssl_enabled              = 1
   key_vault_name          = "your-keyvault-name"
   key_vault_resource_group = "your-keyvault-resource-group"
   ssl_certificate_name    = "your-certificate-name"
   ```
3. **Redeploy Terraform**:
   ```bash
   terraform apply
   ```

See `IMPORT_KEYVAULT.md` for detailed Key Vault configuration.

## ✅ Step 4: Verification

### Test HTTPS Access
```bash
# Test all services
curl -I https://capso.example.com
curl -I https://api.minio.example.com/minio/health/live
curl -I https://console.minio.example.com
```

### Access in Browser
- **Cap**: https://capso.example.com
- **MinIO Console**: https://console.minio.example.com (credentials: see terraform output)
- **MinIO API**: https://api.minio.example.com

## 🎯 Final Architecture

```
Internet (HTTPS) → DNS → Application Gateway → Backend VMs
                           ↓
    capso.example.com         → Cap VM:3000
    api.minio.example.com     → MinIO VM:9000  
    console.minio.example.com → MinIO VM:9001
```

## 🛠️ Troubleshooting

**DNS not resolving?**
```bash
# Check DNS propagation
dig capso.example.com
# Clear local DNS cache if needed
```

**SSL certificate errors?**
- For Cloudflare: Ensure encryption mode is "Full" 
- For Key Vault: Check certificate exists and terraform variables are correct

**502 Bad Gateway?**
```bash
# Check backend health
az network application-gateway show-backend-health \
  --resource-group your-rg \
  --name selfhost-application-gateway
```

---

**🎉 That's it!** Your infrastructure is now accessible via HTTPS with custom domains. 