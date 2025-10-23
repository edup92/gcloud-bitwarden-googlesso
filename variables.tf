variable "gcloud_project_name" {
  description = "Google Cloud Project Name"
  type        = string
}

variable "gcloud_region" {
  description = "Google Cloud region where resources will be deployed"
  type        = string
}

variable "domain" {
  description = "Fully Qualified Domain Name (FQDN) ending with dot"
  type        = string
}

variable "allowed_countries" {
  description = "List of allowed countries for access control"
  type        = list(string)
  default     = []
}