#!/bin/bash
set -e

PROJECT_ID="$1"
APP_NAME="$2"
REDIRECT_URI="$3"

if [ -z "$PROJECT_ID" ] || [ -z "$APP_NAME" ] || [ -z "$REDIRECT_URI" ]; then
  echo "Usage: create_oauth_client.sh <project_id> <app_name> <redirect_uri>"
  exit 1
fi

EXISTING=$(gcloud iam oauth-clients list \
  --project="${PROJECT_ID}" \
  --format="value(name)" \
  --filter="displayName=${APP_NAME}" || true)

if [ -z "$EXISTING" ]; then
  JSON=$(gcloud iam oauth-clients create \
    --project="${PROJECT_ID}" \
    --display_name="${APP_NAME}" \
    --redirect_uris="${REDIRECT_URI}" \
    --format=json)
else
  JSON=$(gcloud iam oauth-clients describe "$EXISTING" --project="${PROJECT_ID}" --format=json)
fi

CLIENT_ID=$(echo "$JSON" | jq -r '.client_id')
CLIENT_SECRET=$(echo "$JSON" | jq -r '.client_secret')

# Salida en JSON para Terraform
echo "{\"client_id\":\"${CLIENT_ID}\",\"client_secret\":\"${CLIENT_SECRET}\"}"
