# AWS account bootstrap out of the box terraform

# Whats inside

- Creates Gcloud infra (server, firewall, load balancer, managed ssl, waf with allowed country)

# Usage instructions

### 1) Login in AWS CloudShell (login in aws region you want to bootstrap)

### 2) Clone repository

```bash
git clone https://github.com/edup92/gcloud-bitwarden-googlesso.git
```

### 4) Create vars.json file
```bash
cat > gcloud-bitwarden-googlesso/vars.json <<EOF
{
  "domain": "demo",
  "admin_email": "demo",
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

### View status

```bash
sudo -u bitwarden bash -c 'cd /opt/bitwarden/bwdata/docker && docker compose ps'
```