# Google Cloud Bitwarden

# Whats inside

- Creates gcloud infra (instance, load balancer, firewall, waf, managed ssl, dns record)
- Installs bitwarden containers with Google SSO proxy

# Usage instructions

### 1) In google cloud create project. Enable compute, dns, secrets and bucket api

### 2) Login in Google Cloud Shell

### 3) Clone repository

```bash
git clone https://github.com/edup92/gcloud-bitwarden-googlesso.git
```

### 4) Create vars.json file
```bash
cat > gcloud-bitwarden-googlesso/vars.json <<EOF
{ 
  "project_name": "demo",
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
  "bw_smtp_host": "demo",
  "bw_smtp_port": 587,
  "bw_smtp_ssl": true,
  "bw_smtp_username": "demo",
  "bw_smtp_password": "demo"
}
EOF
```

### 4) Run runme.sh

```bash
chmod +x gcloud-bitwarden-googlesso/runnme.sh ; gcloud-bitwarden-googlesso/runnme.sh
```

### 5) Point the ip to the record in your DNS zone

### 6) Save SSHKeypair and Ouath Key and secret from Gcloud secrets

### View status
```bash
sudo -u bitwarden bash -c 'cd /opt/bitwarden/bwdata/docker && docker compose ps'
```