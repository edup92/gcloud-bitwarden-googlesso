# SSH Key

resource "tls_private_key" "pem_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "file_pem_ssh" {
  filename        = "/tmp/pem_ssh"
  content         = tls_private_key.pem_ssh.private_key_pem
  file_permission = "0600"
}

resource "google_secret_manager_secret" "secret_pem_ssh" {
  secret_id = local.secret_pem_ssh
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "secretversion_pem_ssh" {
  secret      = google_secret_manager_secret.secret_pem_ssh.id
  secret_data = jsonencode({
    private_key = tls_private_key.pem_ssh.private_key_pem
    public_key  = tls_private_key.pem_ssh.public_key_openssh
  })
}

resource "google_compute_project_metadata" "metadata_keypair" {
  project = var.gcloud_project_id
  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.pem_ssh.public_key_openssh}"
  }
}

# Instance

resource "google_compute_instance" "instance_main" {
  name         = local.instance_main_name
  project      = var.gcloud_project_id
  machine_type = "e2-medium"
  zone          = data.google_compute_zones.available.names[0]
  metadata = {
    enable-osconfig = "TRUE"
  }
  allow_stopping_for_update = true
  boot_disk {
    auto_delete = false
    device_name = local.disk_main_name
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251002"
      size  = 25
      type  = "pd-balanced"
    }
  }
  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
    stack_type = "IPV4_ONLY"
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  scheduling {
    provisioning_model = "STANDARD"
    on_host_maintenance = "MIGRATE"
  }
  labels = {
    goog-ec-src = "vm_add-gcloud"
  }
  reservation_affinity {
    type = "NO_RESERVATION"
  }
  tags = [local.instance_main_name]
}

# Snapshot

resource "google_compute_resource_policy" "snapshot_policy" {
  name   = local.snapshot_main_name
  project = var.gcloud_project_id
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
  }
}

resource "google_compute_disk_resource_policy_attachment" "disk_policy_attachment" {
  name    = google_compute_resource_policy.snapshot_policy.name
  disk    = google_compute_instance.instance_main.name
  zone    = data.google_compute_zones.available.names[0]
  project = var.gcloud_project_id

  depends_on = [google_compute_instance.instance_main]
}

# Firewall

resource "google_compute_firewall" "fw_localssh" {
  name    = local.firewall_localssh_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = [google_compute_instance.instance_main.name]
}

resource "google_compute_firewall" "fw_cf" {
  name    = local.firewall_cf_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = data.cloudflare_ip_ranges.cloudflare.ipv4_cidr_blocks
  target_tags   = [google_compute_instance.instance_main.name]
}

resource "google_compute_firewall" "allow_temp_ssh" {
  name    = local.firewall_tempssh_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [google_compute_instance.instance_main.name]
  disabled = true
}

# Playbook

resource "null_resource" "run_ansible" {
  depends_on = [
    google_compute_instance.instance_main,
    google_compute_firewall.allow_temp_ssh
  ]
  triggers = {
    playbook_hash = filesha256("${path.module}/playbook.yml")
  }
  provisioner "local-exec" {
    command = <<EOT
  IP=${google_compute_instance.instance_main.network_interface[0].access_config[0].nat_ip}

  # Abrir SSH temporalmente
  gcloud compute firewall-rules update ${local.firewall_tempssh_name} \
    --project=${var.gcloud_project_id} \
    --no-disabled

  echo "Waiting for instance SSH"

  OK=0
  for i in {1..12}; do   # 12 intentos × 5s = 60s
    ssh -o BatchMode=yes \
        -o ConnectTimeout=3 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -i "${local_file.file_pem_ssh.filename}" \
        ubuntu@$IP 'exit' >/dev/null 2>&1 && {
          echo "SSH disponible"
          OK=1
          break
        }
    echo "Instance SSH unavailable, retrying"
    sleep 5
  done

  if [ "$OK" -ne 1 ]; then
    echo "ERROR: Instance unaccesible, timeout"
    gcloud compute firewall-rules update ${local.firewall_tempssh_name} \
      --project=${var.gcloud_project_id} \
      --disabled
    exit 1
  fi

  # Ejecutar Ansible
  ansible-playbook \
    -i "$IP," \
    --user ubuntu \
    --private-key "${local_file.file_pem_ssh.filename}" \
    --extra-vars "@${path.module}/vars.json" \
    --ssh-extra-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    playbook.yml

  # Cerrar SSH temporal
  gcloud compute firewall-rules update ${local.firewall_tempssh_name} \
    --project=${var.gcloud_project_id} \
    --disabled
  EOT
  }
}

# Cloudflare

resource "cloudflare_zone" "zone_main" {
  zone       = var.dns_domain
  account_id = var.cf_accountid
}

resource "cloudflare_record" "dnsrecord_main" {
  zone_id = cloudflare_zone.zone_main.id
  name    = var.dns_record
  type    = "A"
  value   = google_compute_instance.instance_main.network_interface[0].access_config[0].nat_ip
  ttl     = 1
  proxied = true
  allow_overwrite = true
}

resource "cloudflare_zone_settings_override" "zonesettings_main" {
  zone_id = cloudflare_zone.zone_main.id
  settings {
    ssl                     = "full"
    min_tls_version         = "1.2"
    automatic_https_rewrites = "on"
    always_use_https        = "on"
  }
}

resource "cloudflare_ruleset" "ruleset_cache" {
  zone_id = cloudflare_zone.zone_main.id
  name    = "disable_cache_everything"
  kind    = "zone"
  phase   = "http_request_cache_settings"
  rules {
    enabled     = true
    description = "Soft disable cache (Terraform-safe)"
    expression  = "true"
    action = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        mode = "bypass_by_default"
      }
      browser_ttl {
        mode    = "override_origin"
        default = 1
      }
    }
  }
}

resource "cloudflare_ruleset" "ruleset_waf" {
  zone_id = cloudflare_zone.zone_main.id
  name    = "country-access-control"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    enabled     = true
    description = "Block all non-allowed countries"
    expression  = "not (${join(" or ", [
      for c in var.allowed_countries :
      "(ip.geoip.country eq \"${c}\")"
    ])})"
    action      = "block"
  }
}