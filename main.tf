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

# Create the Bitwarden instance

resource "google_compute_instance" "instance_bitwarden" {
  name         = local.instance_bitwarden_name
  project      = var.project_id
  machine_type = local.instances_type
  zone = data.google_compute_zones.available.names[0]
  deletion_protection = true
  metadata = {
    enable-osconfig = "TRUE"
    startup-script  = "apt update && apt install -y ansible git"
  }
  boot_disk {
    auto_delete = false
    device_name = local.disk_bitwarden_name
    initialize_params {
      image = local.instances_image
      size  = local.instances_disk_size
      type  = local.instances_disk_model
    }
  }
  network_interface {
    network_tier = "STANDARD"
    stack_type   = "IPV4_ONLY"
  }
  service_account {
    email = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
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
}


