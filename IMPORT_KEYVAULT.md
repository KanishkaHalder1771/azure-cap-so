# Key Vault Configuration Guide

This guide explains how to configure SSL certificates with an existing Azure Key Vault managed by [shibayan/keyvault-acmebot](https://github.com/shibayan/keyvault-acmebot).

## Overview

This Terraform configuration is designed to work with Key Vaults that are managed by the **shibayan/keyvault-acmebot** project. The acmebot automatically provisions and renews Let's Encrypt SSL certificates in your Azure Key Vault.

**Important**: This Terraform setup does NOT manage the Key Vault itself - it only references existing certificates stored in your acmebot-managed Key Vault.

## Prerequisites

1. You have a Key Vault managed by [shibayan/keyvault-acmebot](https://github.com/shibayan/keyvault-acmebot)
2. You have created SSL certificates in that Key Vault using the acmebot
3. Your Azure credentials have access to read certificates from the Key Vault

## Configuration Steps

### 1. Create Certificates in Key Vault

Using your acmebot deployment, create the SSL certificates you need:
- Wildcard certificate (e.g., `*.example.com`)
- Or specific domain certificates for your applications

### 2. Configure Terraform Variables

Add the following variables to your `terraform.tfvars` file:

```hcl
ssl_enabled              = 1
key_vault_name          = "your-keyvault-name"
key_vault_resource_group = "your-keyvault-resource-group"
ssl_certificate_name    = "your-certificate-name"
```

**Example:**
```hcl
ssl_enabled              = 1
key_vault_name          = "kv-letsencrypt-example"
key_vault_resource_group = "rg-acmebot"
ssl_certificate_name    = "wildcard-example-com"
```

### 3. Deploy with SSL

Deploy your infrastructure with SSL enabled:

```bash
terraform apply
```

## How It Works

1. The Terraform configuration uses `data` sources to reference your existing Key Vault and certificates
2. Application Gateway is configured with a system-assigned managed identity
3. Access policies are automatically created to allow Application Gateway to read the SSL certificates
4. No import or Key Vault management by Terraform is required

## Troubleshooting

**Error: "Key Vault not found"**
- Verify the `key_vault_name` matches your acmebot Key Vault name
- Verify the `key_vault_resource_group` is correct
- Ensure your Azure credentials have access to the Key Vault

**Error: "Certificate not found"**
- Verify the certificate exists in your acmebot Key Vault
- Check the `ssl_certificate_name` matches the certificate name in Key Vault
- Ensure the certificate is in the "Certificates" section (not just "Secrets")

**Error: "Access denied to Key Vault"**
- The Application Gateway needs read access to Key Vault certificates
- Access policies are created automatically when `ssl_enabled = 1`
- Verify your deployment has the necessary Azure permissions

## Verification

After successful deployment with SSL enabled:

```bash
# Check Application Gateway SSL certificates
az network application-gateway ssl-cert list \
  --resource-group your-rg \
  --gateway-name selfhost-application-gateway

# Test HTTPS access to your applications
curl -I https://capso.example.com
curl -I https://console.minio.example.com
```

## Certificate Renewal

Since your Key Vault is managed by shibayan/keyvault-acmebot:
- Certificates will be automatically renewed by the acmebot
- No manual intervention required for certificate lifecycle management
- Application Gateway will automatically use the renewed certificates 