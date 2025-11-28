#!/bin/bash

### CONFIG ###
USERNAME="${1:-admin-$(date +%s)}"

# Always ask for PROJECT_ID interactively
read -p "Enter your Google Cloud PROJECT_ID: " PROJECT_ID

ROLE="roles/editor"

### 1. Select project
echo "[INFO] Using project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

### 2. Create Service Account
echo "[INFO] Creating Service Account..."
gcloud iam service-accounts create "$USERNAME"

SA_EMAIL="$USERNAME@$PROJECT_ID.iam.gserviceaccount.com"
echo "[INFO] Service Account created: $SA_EMAIL"

### 3. Assign role to the Service Account
echo "[INFO] Assigning role $ROLE to $SA_EMAIL"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="$ROLE" \
  --quiet

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:<SA_EMAIL>" \
  --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:<SA_EMAIL>" \
  --role="roles/secretmanager.secretAccessor"


### 4. Generate JSON key inline
echo "[INFO] Generating JSON key (inline output):"
echo ""
echo "========================================"
gcloud iam service-accounts keys create /dev/stdout \
  --iam-account="$SA_EMAIL"
echo "========================================"
echo ""
echo "Copy the entire JSON above into a GitHub Secret named: GCP_SA_KEY"
