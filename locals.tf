
locals {
  # Instances

  sshkey_main_name    = "${var.project_name}-sshkey-main"
  instance_bitwarden_name  = "${var.project_name}-instance-bitwarden"
  disk_bitwarden_name       = "${var.project_name}-disk-bitwarden"
  snapshot_bitwarden_name = "${var.project_name}-snapshot-bitwarden"
  instancegroup_bitwarden_name = "${var.project_name}-instancegroup-bitwarden"

  # Network

  firewall_bitwarden_name = "${var.project_name}-firewall-bitewarden"
  healthcheck_80_name = "${var.project_name}-healthcheck-80"
  backend_bitwarden_name = "${var.project_name}-backend-bitwarden" 
  cloudarmor_bitwarden_name = "${var.project_name}-cloudarmor-bitwarden"
  urlmap_bitwarden_name = "${var.project_name}-urlmap-bitwarden"
  lbip_bitwarden_name = "${var.project_name}-lbip-bitwarden"
  lbtarget_bitwarden_name = "${var.project_name}-lbtarget-bitwarden"
  lbrule_bitwarden_name = "${var.project_name}-lbrule-bitwarden"
  ssl_bitwarden_name = "${var.project_name}-ssl-bitwarden" 

}