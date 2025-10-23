# SSH Key

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_secret_manager_secret" "ssh_keypair" {
  secret_id = local.sshkey_main_name
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "ssh_keypair_version" {
  secret      = google_secret_manager_secret.ssh_keypair.id
  secret_data = jsonencode({
    private_key = tls_private_key.keypair.private_key_pem
    public_key  = tls_private_key.keypair.public_key_openssh
  })
}

resource "google_compute_project_metadata" "metadata_keypair" {
  project = var.project_id
  metadata = {
    ssh-keys = "bitwarden:${tls_private_key.keypair.public_key_openssh}"
  }
}

# Instance

resource "google_compute_instance" "instance_bitwarden" {
  name         = local.instance_bitwarden_name
  project      = var.project_id
  machine_type = "e2-small"
  zone          = data.google_compute_zones.available.names[0]
  deletion_protection = true
  metadata = {
    enable-osconfig = "TRUE"
    startup-script  = "apt update && apt install -y ansible git ; git clone https://github.com/edup92/gcloud-bitwarden-ssogoogle.git ; ansible-playbook gcloud-bitwarden-ssogoogle/main.yml --connection=local -e @gcloud-bitwarden-googlesso/vars.json"
  }
  boot_disk {
    auto_delete = false
    device_name = local.disk_bitwarden_name
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251002"
      size  = 25
      type  = "pd-balanced"
    }
  }
  network_interface {
    network_tier = "STANDARD"
    stack_type   = "IPV4_ONLY"
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  maintenance_policy {
    maintenance_type = "MIGRATE"
  }
  scheduling {
    provisioning_model = "STANDARD"
  }
  labels = {
    goog-ec-src = "vm_add-gcloud"
  }
  reservation_affinity {
    type = "ANY"
  }
  tags = [local.instance_bitwarden_name]
}

# Snapshot policy

resource "google_compute_resource_policy" "snapshot_policy" {
  name   = local.snapshot_bitwarden_name
  project = var.project_id
  region  = var.region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "00:00"
      }
    }
    retention_policy {
      max_retention_days    = 31
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    storage_locations = [var.region]
  }
}

resource "google_compute_disk_resource_policy_attachment" "disk_policy_attachment" {
  name     = local.snapshot_bitwarden_name
  disk     = google_compute_instance.instance_bitwarden.boot_disk[0].device_name
  zone     = data.google_compute_zones.available.names[0]
  project  = var.project_id
  resource_policy = google_compute_resource_policy.snapshot_policy.id
}

# Firewall

resource "google_compute_firewall" "allow_lb_hc" {
  name    = local.firewall_bitwarden_name
  project = var.project_id
  network = local.network_name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [local.instance_bitwarden_name]
}