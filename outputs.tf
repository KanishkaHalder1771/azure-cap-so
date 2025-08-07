# --- Core Outputs ---


output "service_urls" {
  description = "Access URLs for your deployed services."
  value = {
    cap_web       = var.ssl_enabled == 1 ? "https://${var.cap_domain}" : "http://${var.cap_domain}"
    minio_console = var.ssl_enabled == 1 ? "https://${var.minio_console_domain}" : "http://${var.minio_console_domain}"
  }
}

# --- Summary & Next Steps ---

output "next_steps" {
  description = "Follow these steps after deployment is complete."
  value = <<-EOT
    1. DNS Setup: Create A records for your domains pointing to the Application Gateway IP.
    2. Access Services: Once DNS propagates, use the URLs from the 'service_urls' output.
    3. MinIO Credentials: Use 'minio-admin' and your configured password to log in.
  EOT
} 