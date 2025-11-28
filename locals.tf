
locals {
  # Instances

  instance_main_name  = "${var.project_name}-instance-main"
  disk_main_name       = "${var.project_name}-disk-main"
  snapshot_main_name = "${var.project_name}-snapshot-main"

  # Secrets

  secret_pem_ssh    = "${var.project_name}-secret-pem-ssh"

  # Network

  firewall_cf_name = "${var.project_name}-firewall-cf"
  firewall_localssh_name = "${var.project_name}-firewall-localssh"
  firewall_tempssh_name = "${var.project_name}-firewall-tempssh"

  # Oauth

  ouath_brand_name = "${var.project_name}-brand-main"
  ouath_client_name = "${var.project_name}-client-main"
}