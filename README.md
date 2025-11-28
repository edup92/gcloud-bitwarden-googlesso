# Vault

## Bitwarden selfhosted in docker containers, with Google SSO Auth, Hosted in Google cloud, DNS and WAF in Cloudflare

## Installation
- Create Account token in cloudflare with permissions:
  - Account - DNS Settings:Edit
  All zones - DNS Settings:Edit, Cache Rules:Edit, Zone WAF:Edit, Zone Settings:Edit, Zone:Edit, SSL and Certificates:Edit, Page Rules:Edit, Firewall Services:Edit, DNS:Edit
- Create google account project
- Create OAuth credentials
  - authoriced origins: https://subdomain.mydomain.tld
  - authoriced redirect: https://subdomain.mydomain.tld/oauth2/callback
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
