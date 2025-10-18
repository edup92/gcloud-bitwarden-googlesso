# Pasos para instalar Ansible y ejecutar el playbook

## 1 - Crea zona dns en google cloud, crea instancia, snapshot schedule y firewall

```bash
 git clone https://github.com/edup92/gcloud-bitwarden-googlesso.git ; chmod +x gcloud-bitwarden-googlesso/gcloud.sh ; gcloud-bitwarden-googlesso/gcloud.sh
```


## 2- Modifica secrets.yml substituyendo los valores demo

domain: "demo"
admin_email: "demo"
oauth_client_id: "demo"
oauth_client_secret: "demo"
bw_installation_id: "XXXX-XXXX-XXXX"
bw_installation_key: "YYYYYYYYYYYYYYYY"
bw_installation_id: "XXXX-XXXX-XXXX"
bw_installation_key: "YYYYYYYYYYYYYYYY"
bw_db_password: "demo"
bw_smtp__host: "demo"
bw_smtp__port: 587
bw_smtp__ssl: true
bw_smtp__username: "demo"
bw_smtp__password: "demo"


## 3 - Ejecuta el playbook en el servidor

```bash
 git clone https://github.com/edup92/gcloud-bitwarden-googlesso.git ; ansible-playbook gcloud-bitwarden-googlesso/main.yml --connection=local -e @gcloud-bitwarden-ssogoogle/secrets.yml
```

## Ver estado

sudo -u bitwarden bash -c 'cd /opt/bitwarden/bwdata/docker && docker compose ps'
