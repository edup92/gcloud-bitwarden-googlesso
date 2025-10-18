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
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account="$(gcloud projects describe "$PROJECT_ID" --format='get(projectNumber)')-compute@developer.gserviceaccount.com" \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=no,boot=yes,device-name="$INSTANCE_NAME",image=projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251002,mode=rw,size=25,type=pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any \
  --deletion-protection

# ==== SNAPSHOT POLICY ====
echo "Creating snapshot policy..."
gcloud compute resource-policies create snapshot-schedule "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --max-retention-days=31 \
  --on-source-disk-delete=keep-auto-snapshots \
  --daily-schedule \
  --start-time=00:00 \
  --storage-location="$REGION"

# ==== ASSOCIATE SNAPSHOT POLICY ====
echo "Attaching snapshot policy to disk..."
gcloud compute disks add-resource-policies "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --resource-policies="projects/$PROJECT_ID/regions/$REGION/resourcePolicies/$INSTANCE_NAME"

# ==== FIREWALL RULE ====
echo "Creating firewall rule named $INSTANCE_NAME (HTTP/HTTPS only)..."
gcloud compute firewall-rules create "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --direction=INGRESS \
  --priority=1000 \
  --network="$NETWORK" \
  --action=ALLOW \
  --rules=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0,::/0 \
  --target-tags="$INSTANCE_NAME" \
  --description="Allow HTTP and HTTPS from all IPv4 and IPv6 for $INSTANCE_NAME"

# ==== APPLY NETWORK TAG ====
echo "Applying network tag '$INSTANCE_NAME' to instance..."
gcloud compute instances add-tags "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --tags="$INSTANCE_NAME"

# ==== DNS RECORD ====
echo "Retrieving external IP..."
IP_ADDRESS=$(gcloud compute instances describe "$INSTANCE_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Remove existing record if present
gcloud dns record-sets transaction remove "$IP_ADDRESS" \
  --name="$DNS_NAME" \
  --type="A" \
  --ttl=300 \
  --zone="$DNS_ZONE" \
  --project="$PROJECT_ID" 2>/dev/null || true

# Add new record
gcloud dns record-sets transaction add "$IP_ADDRESS" \
  --name="$DNS_NAME" \
  --type="A" \
  --ttl=300 \
  --zone="$DNS_ZONE" \
  --project="$PROJECT_ID"

# Execute transaction
gcloud dns record-sets transaction execute --project="$PROJECT_ID" --zone="$DNS_ZONE"

echo "DNS record updated successfully."
