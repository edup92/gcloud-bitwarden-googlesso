#!/bin/bash

# Vars json
VARS_JSON_PATH="$(dirname "$0")/vars.json"
if [ ! -f "$VARS_JSON_PATH" ]; then
	echo "ERROR: vars.json file does not exist. Cancelling run."
	exit 1
fi

project_name=$(jq -r '.project_name' "$VARS_JSON_PATH")
gcloud_project_id=$(jq -r '.gcloud_project_id' "$VARS_JSON_PATH")
gcloud_region=$(jq -r '.gcloud_region' "$VARS_JSON_PATH")

# Formato del nombre del bucket
suffix="$(tr -dc 'a-z0-9' < /dev/urandom | head -c8)"
bucket_name="${project_name}-bucket-tfstate-${suffix}"
bucket_name="bitwarden-bucket-tfstate-3367shu3"

# Bucket

if gsutil ls -b "gs://$bucket_name" 2>/dev/null; then
	echo "Bucket $bucket_name already exists."
else
	gsutil mb -p "$gcloud_project_id" -l ${gcloud_region} "gs://$bucket_name"
	gsutil versioning set on "gs://$bucket_name"
fi

# Generate backend

cat > "$(dirname "$0")/backend.tf" <<EOF
terraform {
	backend "gcs" {
		bucket  = "$bucket_name"
		prefix  = "terraform.tfstate"
	}
}
EOF

# Run terraform

terraform -chdir="$(dirname "$0")" init
terraform -chdir="$(dirname "$0")" apply -var-file="vars.json"