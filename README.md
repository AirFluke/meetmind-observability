# MeetMind Observability Platform — Systemd Edition

Production-grade LGTM observability stack running as native systemd services.
No Docker required. Works on any Ubuntu 24.04 server.

## One-command deployment

```bash
git clone https://github.com/AirFluke/meetmind-observability.git
cd meetmind-observability
sudo SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK bash install.sh
```

Without Slack webhook (configure later):
```bash
sudo bash install.sh
```

## What gets installed

| Service | Binary location | Config | Data | Port |
|---------|----------------|--------|------|------|
| Prometheus | /usr/local/bin/prometheus | /etc/prometheus/ | /var/lib/prometheus | 9090 |
| Loki | /usr/local/bin/loki | /etc/loki/ | /var/lib/loki | 3100 |
| Tempo | /usr/local/bin/tempo | /etc/tempo/ | /var/lib/tempo | 3200 |
| Grafana | apt package | /etc/grafana/ | /var/lib/grafana | 3000 |
| Alertmanager | /usr/local/bin/alertmanager | /etc/alertmanager/ | /var/lib/alertmanager | 9093 |
| Node Exporter | /usr/local/bin/node_exporter | — | — | 9100 |
| Blackbox Exporter | /usr/local/bin/blackbox_exporter | /etc/blackbox_exporter/ | — | 9115 |
| Pushgateway | /usr/local/bin/pushgateway | — | — | 9091 |
| OTel Collector | /usr/local/bin/otelcol | /etc/otelcol/ | — | 4317/4318 |

## Check status of all services

```bash
sudo bash scripts/status.sh
```

Or individually:
```bash
sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status loki
# etc.
```

## View logs

```bash
# Follow logs for any service
journalctl -u prometheus -f
journalctl -u grafana-server -f
journalctl -u loki -f
journalctl -u alertmanager -f
```

## Access URLs

After install, visit (replace YOUR_SERVER_IP):

| URL | Purpose |
|-----|---------|
| http://YOUR_SERVER_IP:3000 | Grafana (admin/admin) |
| http://YOUR_SERVER_IP:9090 | Prometheus |
| http://YOUR_SERVER_IP:9093 | Alertmanager |
| http://YOUR_SERVER_IP:9091 | Pushgateway |

## Set Slack webhook after install

```bash
sudo sed -i 's|YOUR_SLACK_WEBHOOK_URL|https://hooks.slack.com/services/YOUR/WEBHOOK|g' \
  /etc/alertmanager/alertmanager.yml
sudo systemctl restart alertmanager
```

## Deploying to a new server

1. Clone the repo
2. Run the install script — it auto-detects the server IP
3. Set your Slack webhook

The install script handles everything:
- Downloads all binaries from GitHub releases
- Creates system users for each service
- Installs configs to /etc/
- Creates data directories in /var/lib/
- Installs and enables all systemd unit files
- Starts all services

## Restart a service after config change

```bash
# Example: after editing prometheus config
sudo systemctl restart prometheus

# Reload prometheus config without restart (hot reload)
curl -X POST http://localhost:9090/-/reload
```

## Teardown

```bash
sudo bash uninstall.sh
```

## Repository structure

```
meetmind-observability/
├── install.sh                  # One-command install
├── uninstall.sh                # Clean teardown
├── scripts/
│   └── status.sh               # Check all service statuses
├── systemd/                    # Systemd unit files
│   ├── prometheus.service
│   ├── node_exporter.service
│   ├── blackbox_exporter.service
│   ├── alertmanager.service
│   ├── pushgateway.service
│   ├── loki.service
│   ├── tempo.service
│   └── otelcol.service
├── config/                     # All service configs
│   ├── prometheus.yml
│   ├── alertmanager.yml
│   ├── slack.tmpl
│   ├── loki-config.yaml
│   ├── tempo.yaml
│   ├── otel-collector.yaml
│   └── blackbox.yml
├── alerts/                     # Alert rules (version-controlled)
│   ├── infrastructure.yml
│   ├── slo-burnrate.yml
│   └── cicd.yml
├── grafana/
│   ├── provisioning/           # Datasource + dashboard discovery
│   └── dashboards/             # 5 JSON dashboards
├── runbooks/                   # One .md per alert rule
├── slo-definitions.yml         # SLI/SLO definitions
├── error-budget-policy.md      # Error budget policy
└── post-incident-review.md     # Blameless PIR template
```

## Four Golden Signals PromQL

```promql
# Latency (p95)
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job))

# Traffic
sum(rate(http_requests_total[1m])) by (job)

# Errors
sum(rate(http_requests_total{status=~"5.."}[5m])) by (job) / sum(rate(http_requests_total[5m])) by (job)

# Saturation
1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

## SLO Targets

| SLO | Target | Window | Error budget |
|-----|--------|--------|--------------|
| Availability | 99.5% | 30 days | 216 minutes |
| Error rate | 99% success | 30 days | 432 minutes |
| Latency p95 | < 500ms | Rolling | Alert-only |

See [slo-definitions.yml](./slo-definitions.yml) and [error-budget-policy.md](./error-budget-policy.md).
