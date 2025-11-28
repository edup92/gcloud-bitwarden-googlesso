terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.26.0"
    }
  }
}

provider "google" {
  project = var.gcloud_project_id
  region  = var.gcloud_region
}

provider "cloudflare" {
  api_token = var.cf_token
}