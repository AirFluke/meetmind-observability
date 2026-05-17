# MeetMind Observability Platform — Remote Monitoring

The monitoring stack runs on a **separate server** from the application.
Prometheus scrapes metrics from the app server remotely.
Alertmanager, Grafana, Loki, and Tempo all live on the monitoring server only.

```
Application Server (13.63.206.183)    Monitoring Server (spun up by Terraform)
─────────────────────────────────     ────────────────────────────────────────
Node Exporter     :9100         ←──── Prometheus scrapes every 15s
Nginx/App         :80/:443      ←──── Blackbox probes HTTP + SSL
App (OTel SDK)    ──────────────────→ OTel Collector :4319 (receives traces/logs)
                                      ↓
                                   Loki (logs)
                                   Tempo (traces)
                                   Grafana (dashboards)
                                   Alertmanager → Slack #all-hng-alerts
```

## Spin up monitoring server

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform apply
```

Terraform will:
1. Create an EC2 instance (t3.medium, Ubuntu 24.04)
2. Assign an Elastic IP so the IP stays stable
3. Open required ports in a new security group
4. Open port 9100 on your app server's security group
5. Run install.sh automatically via cloud-init
6. Output the Grafana URL when done

## Spin down monitoring server

```bash
terraform destroy
```

App server is completely unaffected. Node Exporter stays installed and running — it just won't be scraped until the monitoring server comes back.

## One-time setup on app server

Run this ONCE on your application server (13.63.206.183):

```bash
# SSH into your app server
ssh ubuntu@13.63.206.183

# Install Node Exporter
curl -O https://raw.githubusercontent.com/AirFluke/meetmind-observability/main/scripts/install-node-exporter-on-app-server.sh
sudo bash install-node-exporter-on-app-server.sh
```

This installs Node Exporter as a systemd service on port 9100.
The Terraform security group rule opens that port only to the monitoring server.

## Manual deploy (no Terraform)

```bash
git clone https://github.com/AirFluke/meetmind-observability.git
cd meetmind-observability

sudo APP_SERVER_IP=13.63.206.183 \
     SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK \
     bash install.sh
```

## Check status

```bash
sudo bash scripts/status.sh
```

## What gets monitored

| Metric source | How | Port |
|---------------|-----|------|
| App server CPU/memory/disk | Node Exporter scraped remotely | 9100 |
| App server HTTP endpoints | Blackbox Exporter probes | 80, 443, 3000, 3001 |
| App server SSL certificates | Blackbox TLS probe | 443 |
| App traces (OTel) | OTel Collector receives pushes | 4319 |
| CI/CD DORA metrics | Pushgateway receives from GitHub Actions | 9091 |

## Access URLs

After `terraform apply` completes, outputs show:

```
monitoring_server_ip = "x.x.x.x"
grafana_url          = "http://x.x.x.x:3000"
prometheus_url       = "http://x.x.x.x:9090"
ssh_command          = "ssh -i your-key.pem ubuntu@x.x.x.x"
```

## Repository structure

```
meetmind-observability/
├── install.sh                     # One-command install (accepts APP_SERVER_IP)
├── uninstall.sh                   # Clean teardown
├── scripts/
│   ├── status.sh                  # Check all service statuses
│   └── install-node-exporter-on-app-server.sh
├── terraform/
│   ├── main.tf                    # Creates EC2, security groups, EIP
│   ├── variables.tf               # All configurable values
│   ├── terraform.tfvars.example   # Copy to terraform.tfvars
│   └── user_data.sh.tpl           # Cloud-init bootstrap script
├── systemd/                       # Systemd unit files
├── config/                        # Service configs (APP_SERVER_IP placeholder)
├── alerts/                        # Alert rules
├── grafana/                       # Dashboards and provisioning
└── runbooks/                      # One per alert rule
```
