
locals {

  # Global

  project_name = "bitwarden"

  # Instances
  instances_ami        = "ami-0cd0767d8ed6ad0a9"
  instances_type       = "t4g.nano"
  instances_disk       = "gp3"
  keypair_main_name    = "${var.project_name}-keypair-main"
  instance_bitwarden_name  = "${var.project_name}-instance-bitwarden"
  disk_bitwarden_name       = "${var.project_name}-disk-bitwarden"

  
}

read -p "Enter instance name [default: bitwarden-ssogoogle]: " INSTANCE_NAME; INSTANCE_NAME=${INSTANCE_NAME:-bitwarden-ssogoogle}
read -p "Enter Cloud DNS zone name [default: edup92mail-zone]: " DNS_ZONE; DNS_ZONE=${DNS_ZONE:-test-zone}
read -p "Enter DNS record (FQDN ending with dot) [default: test.xyz.]: " DNS_NAME; DNS_NAME=${DNS_NAME:-test.xyz.}

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