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

resource "google_compute_instance" "instance_bitwarden" {
  name         = local.instance_bitwarden_name
  project      = var.gcloud_project_id
  machine_type = "e2-medium"
  zone          = data.google_compute_zones.available.names[0]
  metadata = {
    enable-osconfig = "TRUE"
  }
  allow_stopping_for_update = true
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
  tags = [local.instance_bitwarden_name]
}

# Snapshot

resource "google_compute_resource_policy" "snapshot_policy" {
  name   = local.snapshot_bitwarden_name
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
  disk    = google_compute_instance.instance_bitwarden.name
  zone    = data.google_compute_zones.available.names[0]
  project = var.gcloud_project_id

  depends_on = [google_compute_instance.instance_bitwarden]
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
  target_tags   = [google_compute_instance.instance_bitwarden.name]
}

resource "google_compute_firewall" "fw_lb" {
  name    = local.firewall_lb_name
  project = var.gcloud_project_id
  network = "default"
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [google_compute_instance.instance_bitwarden.name]
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
  target_tags   = [google_compute_instance.instance_bitwarden.name]
  disabled = true
}

# Cloud armor

resource "google_compute_security_policy" "cloudarmor_main" {
  name        = local.cloudarmor_bitwarden_name
  rule {
    priority    = 1000
    description = "Allow specified countries"
    match {
      expr {
        expression = join(" || ", [for country in var.allowed_countries : "origin.region_code == '${country}'"])
      }
    }
    action = "allow"
  }
  rule {
    priority    = 2147483647
    description = "Default deny rule"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    action = "deny(403)"
  }
}

# Instancegroup

resource "google_compute_instance_group" "instancegroup_bitwarden" {
  name        = local.instancegroup_bitwarden_name
  zone     = data.google_compute_zones.available.names[0]
  instances   = [google_compute_instance.instance_bitwarden.self_link]
  named_port {
    name = "https"
    port = 443
  }
}

# Healthcheck

resource "google_compute_health_check" "healthcheck_https" {
  name               = local.healthcheck_443_name
  check_interval_sec = 30
  timeout_sec        = 10
  healthy_threshold  = 2
  unhealthy_threshold = 3
  tcp_health_check {
    port = 443
  }
}

# Backend Service

resource "google_compute_backend_service" "backend_main" {
  name                  = local.backend_bitwarden_name
  protocol              = "HTTPS"
  port_name             = "https"
  health_checks         = [google_compute_health_check.healthcheck_https.id]
  connection_draining_timeout_sec = 10
  load_balancing_scheme = "EXTERNAL"
  security_policy = google_compute_security_policy.cloudarmor_main.id
  backend {
    group           = google_compute_instance_group.instancegroup_bitwarden.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

}

# Urlmap

resource "google_compute_url_map" "urlmap_main" {
  name            = local.urlmap_bitwarden_name
  default_service = google_compute_backend_service.backend_main.id
}

# SSL

resource "google_compute_managed_ssl_certificate" "ssl_main" {
  name = local.ssl_bitwarden_name
  managed {
    domains = [var.dnsrecord]
  }
}

# ALB

resource "google_compute_global_address" "lb_ip" {
  name = local.lbip_bitwarden_name
}

resource "google_compute_target_https_proxy" "lbtarget_main" {
  name             = local.lbtarget_bitwarden_name
  url_map          = google_compute_url_map.urlmap_main.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_main.id]
}

resource "google_compute_global_forwarding_rule" "lb_rule" {
  name                  = local.lbrule_bitwarden_name
  target                = google_compute_target_https_proxy.lbtarget_main.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.lb_ip.address
}

# Playbook

resource "null_resource" "run_ansible" {
  depends_on = [
    google_compute_instance.instance_bitwarden,
    google_compute_firewall.allow_temp_ssh
  ]
  triggers = {
    playbook_hash = filesha256("${path.module}/playbook.yml")
  }
  provisioner "local-exec" {
    command = <<EOT
  IP=${google_compute_instance.instance_bitwarden.network_interface[0].access_config[0].nat_ip}

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
  account_id = var.cf_accountid
  zone       = var.domain
}

resource "cloudflare_dnsrecord" "dnsrecord_main" {
  zone_id = cloudflare_zone.zone_main.id
  name    = var.dnsrecord
  type    = "A"
  content = google_compute_instance.instance_bitwarden.network_interface[0].access_config[0].nat_ip
  ttl     = 1
  proxied = true
}

resource "cloudflare_zone_settings_override" "zone_ssl" {
  zone_id = cloudflare_zone.zone_main.id
  settings {
    ssl = "full"
    min_tls_version = "1.2"
    automatic_https_rewrites = "on"
    always_use_https = "on"
  }
}

resource "cloudflare_page_rule" "pagerule_main" {
  zone_id = cloudflare_zone.zone_main.id
  target  = "${var.dnsrecord}/*"
  actions {
    cache_level         = "bypass"
    disable_performance = true
    disable_security    = false
  }
  priority = 1
}

resource "cloudflare_ruleset" "waf_main" {
  zone_id     = cloudflare_zone.zone_main.id
  name        = "WAF Country Firewall"
  description = "Allow/Block traffic based on countries"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action = "skip"
    description = "Allow only traffic from allowed countries"
    expression  = join(" or ", [for country in var.allowed_countries : "(cf.country eq \"${country}\")"])
  }

  rules {
    action = "block"
    description = "Block all other countries"
    expression  = "not (${join(" or ", [for country in var.allowed_countries : "(cf.country eq \"${country}\")"])})"
  }
}