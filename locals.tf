
locals {
  # Instances

  sshkey_main_name    = "${var.project_name}-sshkey-main"
  instance_bitwarden_name  = "${var.project_name}-instance-main"
  disk_bitwarden_name       = "${var.project_name}-disk-main"
  snapshot_bitwarden_name = "${var.project_name}-snapshot-main"
  instancegroup_bitwarden_name = "${var.project_name}-instancegroup-main"

  # Network

  firewall_bitwarden_name = "${var.project_name}-firewall-main"
  healthcheck_443_name = "${var.project_name}-healthcheck-https"
  backend_bitwarden_name = "${var.project_name}-backend-main" 
  cloudarmor_bitwarden_name = "${var.project_name}-cloudarmor-main"
  urlmap_bitwarden_name = "${var.project_name}-urlmap-main"
  lbip_bitwarden_name = "${var.project_name}-lbip-main"
  lbtarget_bitwarden_name = "${var.project_name}-lbtarget-main"
  lbrule_bitwarden_name = "${var.project_name}-lbrule-main"
  ssl_bitwarden_name = "${var.project_name}-ssl-main" 

}