#!/bin/bash
# deploy-bitwarden-gcp.sh
# Creates a Bitwarden VM instance with snapshots, firewall, and DNS A record

# ==== USER INPUT ====

read -p "Enter GCP project ID [default: ${DEFAULT_PROJECT}]: " PROJECT_ID
read -p "Enter region [default: europe-southwest1]: " REGION; REGION=${REGION:-europe-southwest1}
read -p "Enter zone [default: europe-southwest1-b]: " ZONE; ZONE=${ZONE:-europe-southwest1-b}
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

# ==== INSTACE GROUPS ====
echo "Creating Instance Group"

gcloud compute instance-groups unmanaged create "$IG_NAME" --zone="$ZONE" 2>/dev/null || true
gcloud compute instance-groups unmanaged add-instances "$IG_NAME" --instances="$INSTANCE_NAME" --zone="$ZONE"

# ==== INSTACE GROUPS ====
echo "Creating Health Check"

gcloud compute health-checks create http "$HC_NAME" --port 80 --check-interval=30s --timeout=10s 2>/dev/null || true

# ==== LB ====
echo "Creating LB"

gcloud compute backend-services create "$BACKEND" \
  --global \
  --protocol HTTP \
  --port-name http \
  --health-checks "$HC_NAME" 2>/dev/null || true

gcloud compute backend-services add-backend "$BACKEND" \
  --instance-group "$IG_NAME" \
  --instance-group-zone "$ZONE" \
  --global

gcloud compute url-maps create "$URL_MAP" --default-service "$BACKEND" 2>/dev/null || true


# ==== DNS RECORD ====
echo "Retrieving external IP..."
IP_ADDRESS=$(gcloud compute instances describe "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Updating DNS record for $DNS_NAME with IP $IP_ADDRESS..."

# Get current A records
EXISTING_IPS=$(gcloud dns record-sets list \
  --project="$PROJECT_ID" \
  --zone="$DNS_ZONE" \
  --name="$DNS_NAME" \
  --type="A" \
  --format="value(rrdatas)")

TMPDIR=$(mktemp -d)
TRANSACTION_FILE="$TMPDIR/transaction.yaml"
gcloud dns record-sets transaction start \
  --project="$PROJECT_ID" \
  --zone="$DNS_ZONE" \
  --transaction-file="$TRANSACTION_FILE"

# Remove existing A record(s) if any
if [ -n "$EXISTING_IPS" ]; then
  echo "Removing existing A record(s): $EXISTING_IPS"
  gcloud dns record-sets transaction remove $EXISTING_IPS \
    --name="$DNS_NAME" \
    --type="A" \
    --ttl=300 \
    --zone="$DNS_ZONE" \
    --project="$PROJECT_ID" \
    --transaction-file="$TRANSACTION_FILE"
fi

# Add new record
echo "Adding new A record: $IP_ADDRESS"
gcloud dns record-sets transaction add "$IP_ADDRESS" \
  --name="$DNS_NAME" \
  --type="A" \
  --ttl=300 \
  --zone="$DNS_ZONE" \
  --project="$PROJECT_ID" \
  --transaction-file="$TRANSACTION_FILE"

# Execute transaction
gcloud dns record-sets transaction execute \
  --project="$PROJECT_ID" \
  --zone="$DNS_ZONE" \
  --transaction-file="$TRANSACTION_FILE"

rm -rf "$TMPDIR"
echo "DNS record updated successfully."
