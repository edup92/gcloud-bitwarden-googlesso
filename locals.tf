
locals {

  # Global

  project_name = "bitwarden"

  # Instances
  
  instances_image        = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251002"
  instances_type       = "e2-small"
  instances_disk_model       = "pd-balanced"
  instances_disk_size       = 25
  sshkey_main_name    = "${var.project_name}-sshkey-main"
  instance_bitwarden_name  = "${var.project_name}-instance-bitwarden"
  disk_bitwarden_name       = "${var.project_name}-disk-bitwarden"

  
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
