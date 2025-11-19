
locals {
  # Instances

  instance_bitwarden_name  = "${var.project_name}-instance-main"
  disk_bitwarden_name       = "${var.project_name}-disk-main"
  snapshot_bitwarden_name = "${var.project_name}-snapshot-main"
  instancegroup_bitwarden_name = "${var.project_name}-instancegroup-main"

  # Secrets

  secret_pem_ssh    = "${var.project_name}-secret-pem-ssh"

  # Network

  firewall_lb_name = "${var.project_name}-firewall-lb"
  firewall_localssh_name = "${var.project_name}-firewall-localssh"
  firewall_tempssh_name = "${var.project_name}-firewall-tempssh"
  healthcheck_443_name = "${var.project_name}-healthcheck-https"
  backend_bitwarden_name = "${var.project_name}-backend-main" 
  cloudarmor_bitwarden_name = "${var.project_name}-cloudarmor-main"
  urlmap_vscode_name = "${var.project_name}-urlmap-main"
  lbip_vscode_name = "${var.project_name}-lbip-main"
  lbtarget_vscode_name = "${var.project_name}-lbtarget-main"
  lbrule_vscode_name = "${var.project_name}-lbrule-main"
  ssl_vscode_name = "${var.project_name}-ssl-main"

  # Oauth

  ouath_brand_name = "${var.project_name}-brand-main"
  ouath_client_name = "${var.project_name}-client-main"
}