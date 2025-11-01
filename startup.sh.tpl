#!/bin/bash
set -e

apt-get update -y
apt-get install -y ansible git curl
rm -rf /home/bitwarden/gcloud-bitwarden-googlesso
git clone https://github.com/edup92/gcloud-bitwarden-googlesso.git /home/bitwarden/gcloud-bitwarden-googlesso
cat > /home/bitwarden/gcloud-bitwarden-googlesso/vars.json <<EOF
{
  "project_name": "${project_name}",
  "gcloud_project_id": "${gcloud_project_id}",
  "gcloud_region": "${gcloud_region}",
  "domain": "${domain}",
  "admin_email": "${admin_email}",
  "allowed_countries": ${allowed_countries},
  "oauth_client_id": "${oauth_client_id}",
  "oauth_secret": "${oauth_secret}",
  "bw_installation_id": "${bw_installation_id}",
  "bw_installation_key": "${bw_installation_key}",
  "bw_db_password": "${bw_db_password}",
  "bw_smtp_host": "${bw_smtp_host}",
  "bw_smtp_port": ${bw_smtp_port},
  "bw_smtp_ssl": ${bw_smtp_ssl},
  "bw_smtp_username": "${bw_smtp_username}",
  "bw_smtp_password": "${bw_smtp_password}"
}
EOF
chown bitwarden:bitwarden /home/bitwarden/gcloud-bitwarden-googlesso/vars.json
ansible-playbook /home/bitwarden/gcloud-bitwarden-googlesso/playbook.yml --connection=local -e @/home/bitwarden/gcloud-bitwarden-googlesso/vars.json
rm -rf /home/bitwarden/gcloud-bitwarden-googlesso
