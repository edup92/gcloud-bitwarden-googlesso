# Vault

## Bitwarden selfhosted in docker containers, with Google SSO Auth, Hosted in Google cloud, DNS and WAF in Cloudflare

## Installation
-  Run bootstrap.sh on Cloudshell
- Paste json data from bootstrap.sh as Github Actions Secret with name SERVICE_ACCOUNT 
- Paste this json as Github Actions Secret with name VARS_JSON:

{
  "gcloud_project_id":"",
  "gcloud_region":"",
  "cf_token":"",
  "cf_accountid": "",
  "project_name": "myproject",
  "dns_domain": "mydomain.tld",
  "dns_record": "x.mydomain.tld",
  "admin_email": "",
  "allowed_countries": ["ES"],
  "bw_installation_id": "",
  "bw_installation_key": "",
  "bw_db_password": "",
  "bw_smtp_host": "",
  "bw_smtp_port": 587,
  "bw_smtp_ssl": true,
  "bw_smtp_username": "",
  "bw_smtp_password": "",
  "oauth_client_id": "",
  "oauth_client_secret": ""
}

- Run Github Actions
