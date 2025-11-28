

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "bitwarden"
}

variable "gcloud_project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "gcloud_region" {
  description = "Google Cloud region where resources will be deployed"
  type        = string
}

variable "cf_token" {
  description = "Cloudflare Token"
  type        = string
}

variable "domain" {
  description = "Fully Qualified Domain Name (FQDN) "
  type        = string
}

variable "allowed_countries" {
  description = "List of allowed countries for access control"
  type        = list(string)
  default     = []
}

variable "admin_email" {
  description = "Administrator email address for the Bitwarden instance"
  type        = string
}

variable "oauth_client_id" {
  description = "OAuth client ID for Google SSO authentication"
  type        = string
}

variable "oauth_client_secret" {
  description = "OAuth client secret for Google SSO authentication"
  type        = string
  sensitive   = true
}

variable "bw_installation_id" {
  description = "Bitwarden installation ID in format XXXX-XXXX-XXXX"
  type        = string
  sensitive   = true
}

variable "bw_installation_key" {
  description = "Bitwarden installation key"
  type        = string
  sensitive   = true
}

variable "bw_db_password" {
  description = "Password for Bitwarden database"
  type        = string
  sensitive   = true
}

variable "bw_smtp_host" {
  description = "SMTP server hostname for email delivery"
  type        = string
}

variable "bw_smtp_port" {
  description = "SMTP server port for email delivery"
  type        = number
}

variable "bw_smtp_ssl" {
  description = "Enable SSL/TLS for SMTP connection"
  type        = bool
}

variable "bw_smtp_username" {
  description = "SMTP server username for authentication"
  type        = string
}

variable "bw_smtp_password" {
  description = "SMTP server password for authentication"
  type        = string
  sensitive   = true
}
