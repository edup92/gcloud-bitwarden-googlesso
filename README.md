# Google Cloud Bitwarden

# Whats inside

- Creates gcloud infra (instance, load balancer, firewall, waf, managed ssl, dns record)

# Usage instructions

### 1) Login in AWS CloudShell (login in aws region you want to bootstrap)

### 2) Clone repository

```bash
git clone https://github.com/zenpresscloudorg/aws-bootstrap
```

### 4) Create vars.json file
```bash
cat > aws-bootstrap/vars.json <<EOF
{ 
  "gcloud_project_name":"demo",
  "gcloud_region":"demo",
  "domain": "demo.tld",
  "admin_email": "demo",
  "allowed_countries": [],
  "oauth_client_id": "demo",
  "oauth_client_secret": "demo",
  "oauth_cookie_secret": "demo",
  "bw_installation_id": "XXXX-XXXX-XXXX"
  "bw_installation_key": "YYYYYYYYYYYYYYYY"
  "bw_db_password": "demo"
  "bw_smtp__host": "demo"
  "bw_smtp__port": 587
  "bw_smtp__ssl": true
  "bw_smtp__username": "demo"
  "bw_smtp__password": "demo"
}
EOF
```

### 5) Run runme.sh

```bash
chmod +x aws-bootstrap/runnme.sh ; aws-bootstrap/runnme.sh
```