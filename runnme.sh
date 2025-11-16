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
bucket_name="${project_name}-bucket-tfstate"

# Packages

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install ansible terraform -y

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
    	prefix = ""
	}
}
EOF

# Run terraform

terraform -chdir="$(dirname "$0")" init
terraform -chdir="$(dirname "$0")" apply -var-file="vars.json"