#!/bin/bash
# deploy-bitwarden-gcp.sh
# Creates a Bitwarden VM instance with snapshots, firewall, and DNS A record

# ==== USER INPUT ====
DEFAULT_PROJECT=$(gcloud config get-value project 2>/dev/null)
read -p "Enter GCP project ID [default: ${DEFAULT_PROJECT}]: " PROJECT_ID
PROJECT_ID=${PROJECT_ID:-$DEFAULT_PROJECT}

read -p "Enter region [default: europe-southwest1]: " REGION
REGION=${REGION:-europe-southwest1}

read -p "Enter zone [default: europe-southwest1-b]: " ZONE
ZONE=${ZONE:-europe-southwest1-b}

read -p "Enter instance name [default: bitwarden-ssogoogle]: " INSTANCE_NAME
INSTANCE_NAME=${INSTANCE_NAME:-bitwarden-ssogoogle}

read -p "Enter Cloud DNS zone name [default: edup92mail-zone]: " DNS_ZONE
DNS_ZONE=${DNS_ZONE:-edup92mail-zone}

read -p "Enter DNS record (FQDN) [default: vault.edup92mail.xyz.]: " DNS_NAME
DNS_NAME=${DNS_NAME:-vault.edup92mail.xyz.}

NETWORK="default"

echo
echo "=== CONFIGURATION SUMMARY ==="
echo "Project:        $PROJECT_ID"
echo "Region:         $REGION"
echo "Zone:           $ZONE"
echo "Instance name:  $INSTANCE_NAME"
echo "DNS zone:       $DNS_ZONE"
echo "DNS record:     $DNS_NAME"
echo "=============================="
echo

# ==== CREATE INSTANCE ====
echo "Creating instance ${INSTANCE_NAME}..."
gcloud compute instances create "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type=e2-small \
  --network-interface=network-tier=STANDARD,stack-type=IPV4_ONLY,subnet="$NETWORK" \
  --metadata=enable-osconfig=TRUE,startup-script='apt update && apt install -y ansible git' \
  --maint
