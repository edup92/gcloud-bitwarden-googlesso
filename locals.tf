
locals {

  # Global

  project_name = "bitwarden"

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
}

NETWORK="default"
LB_NAME="${INSTANCE_NAME}-lb"
IG_NAME="${LB_NAME}-ig"
BACKEND="${LB_NAME}-backend"
URL_MAP="${LB_NAME}-urlmap"
SEC_POLICY="${LB_NAME}-policy"
HC_NAME="${LB_NAME}-hc"
CERT_NAME="${LB_NAME}-cert"
PROXY="${LB_NAME}-https-proxy"
FWD_RULE="${LB_NAME}-https-fwd"
