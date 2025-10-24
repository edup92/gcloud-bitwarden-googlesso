# Google Cloud Bitwarden

# Whats inside

- Creates gcloud infra (instance, load balancer, firewall, waf, managed ssl, dns record)
- Installs bitwarden containers with Google SSO proxy

# Usage instructions

### 1) Login in Google Cloud Shell

### 2) Clone repository

```bash
git clone https://github.com/edup92/gcloud-bitwarden-googlesso.git
```

### 4) Create vars.json file
```bash
cat > gcloud-bitwarden-googlesso/vars.json <<EOF
{ 
  "gcloud_project_id":"demo",
  "gcloud_region":"demo",
  "domain": "demo.tld",
  "admin_email": "demo",
  "allowed_countries": [],
  "oauth_client_id": "demo",
  "oauth_client_secret": "demo",
  "bw_installation_id": "XXXX-XXXX-XXXX",
  "bw_installation_key": "YYYYYYYYYYYYYYYY",
  "bw_db_password": "demo",
  "bw_smtp__host": "demo",
  "bw_smtp__port": 587,
  "bw_smtp__ssl": true,
  "bw_smtp__username": "demo",
  "bw_smtp__password": "demo"
}
EOF
```

### 5) Run runme.sh

```bash
chmod +x gcloud-bitwarden-googlesso/runnme.sh ; gcloud-bitwarden-googlesso/runnme.sh
```