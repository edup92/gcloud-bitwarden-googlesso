# Pasos para instalar Ansible y ejecutar el playbook

## 1 - Creacion de instancia de google cloud, snapshot job y firewall. Ejecutar en Cloud Shell (incluye ansible)

```bash

gcloud compute instances create bitwarden-tailscale \
    --project=personal-473223 \
    --zone=europe-southwest1-b \
    --machine-type=e2-small \
    --network-interface=network-tier=STANDARD,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-osconfig=TRUE,startup-script='apt update && apt install -y ansible git' \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=32608782837-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --create-disk=auto-delete=yes,boot=yes,device-name=bitwarden-tailscale,image=projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20251002,mode=rw,size=25,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any \
    --deletion-protection

gcloud compute resource-policies create snapshot-schedule bitwarden-tailscale \
    --project=personal-473223 \
    --region=europe-southwest1 \
    --max-retention-days=31 \
    --on-source-disk-delete=keep-auto-snapshots \
    --daily-schedule \
    --start-time=00:00 \
    --storage-location=europe-southwest1

gcloud compute disks add-resource-policies bitwarden-tailscale \
    --project=personal-473223 \
    --zone=europe-southwest1-b \
    --resource-policies=projects/personal-473223/regions/europe-southwest1/resourcePolicies/bitwarden-tailscale
```

## Modifica secrets.yml substituyendo los valores demo

domain: "demo"
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


## Ejecución del playbook

```bash
 git clone https://github.com/edup92/gcloud-bitwarden-tailscale.git ; ansible-playbook gcloud-bitwarden-tailscale/main.yml --connection=local -e @gcloud-bitwarden-tailscale/secrets.yml
```

## Ver estado

sudo -u bitwarden bash -c 'cd /opt/bitwarden/bwdata/docker && docker compose ps'
