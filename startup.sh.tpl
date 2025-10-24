#!/bin/bash
set -e

apt-get update -y
apt-get install -y ansible git curl
cd /home/bitwarden
if [ -d "/home/bitwarden/gcloud-bitwarden-googlesso/.git" ]; then
  git -C /home/bitwarden/gcloud-bitwarden-googlesso pull || true
else
  git clone https://github.com/edup92/gcloud-bitwarden-googlesso.git /home/bitwarden/gcloud-bitwarden-googlesso
fi

cat > /home/bitwarden/gcloud-bitwarden-googlesso/vars.json <<'VARS'
{
  "project_name": "${project_name}",
  "gcloud_project_id": "${gcloud_project_id}",
  "gcloud_region": "${gcloud_region}",
  "domain": "${domain}",
  "managed_zone": "${managed_zone}",
  "admin_email": "${admin_email}",
  "allowed_countries": ${allowed_countries},
  "oauth_client_id": "${oauth_client_id}",
  "oauth_client_secret": "${oauth_client_secret}",
  "bw_installation_id": "${bw_installation_id}",
  "bw_installation_key": "${bw_installation_key}",
  "bw_db_password": "${bw_db_password}",
  "bw_smtp_host": "${bw_smtp_host}",
  "bw_smtp_port": ${bw_smtp_port},
  "bw_smtp_ssl": ${bw_smtp_ssl},
  "bw_smtp_username": "${bw_smtp_username}",
  "bw_smtp_password": "${bw_smtp_password}"
}
VARS

ansible-playbook /home/bitwarden/gcloud-bitwarden-googlesso/src/playbooks/bitwarden/main.yml --connection=local -e @/home/bitwarden/gcloud-bitwarden-googlesso/vars.json
