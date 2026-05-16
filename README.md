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

After install, visit (replace `YOUR_SERVER_IP` with your actual server IP):

| URL | Purpose | Default Credentials |
|-----|---------|---------------------|
| `http://YOUR_SERVER_IP:3000` | **Grafana** (Visualization & Correlation) | `admin` / `admin` |
| `http://YOUR_SERVER_IP:9090` | **Prometheus** (Metrics & Alert Rules) | — |
| `http://YOUR_SERVER_IP:9093` | **Alertmanager** (Alert Routing & Inhibitions) | — |
| `http://YOUR_SERVER_IP:9091` | **Pushgateway** (GitHub Actions / DORA ingester) | — |
| `http://YOUR_SERVER_IP:3100` | **Loki** (Log aggregation backend) | — |
| `http://YOUR_SERVER_IP:3200` | **Tempo** (Distributed tracing backend) | — |

## Set Slack webhook after manual install

If you didn't set the webhook during installation, edit the Alertmanager configuration directly:
```bash
sudo sed -i 's|YOUR_SLACK_WEBHOOK_URL|https://hooks.slack.com/services/YOUR/WEBHOOK|g' \
  /etc/alertmanager/alertmanager.yml
sudo systemctl restart alertmanager
```

---

## Dashboard Guide & User Journeys

The platform features **5 deeply enriched, production-grade dashboards** built specifically to fulfill HNG Stage 6 requirements:

### 1. Unified Observability — Golden Signals, Logs & Traces
Designed as the primary dashboard for live incident triage (the core user journey).
* **Golden Signals**: Real-time panels for Errors (error rate %), Latency (p95 with 500ms target line), Traffic (RPS), and Saturation (CPU/Memory/Disk %).
* **Correlation Panels**: Integrated Loki log stream panel (filtering for errors/warnings) and Tempo trace search panel.
* **Correlated Drift-Down Flow**: Click an error spike in the metric panel -> scroll to logs to see correlated error logs -> click the hyperlinked `traceId` inside the log -> instantly opens the trace timeline in Tempo to find the exact database call or service block that failed.
* **Incident Support**: Live Stat panel for availability burn rate (1h) and an Active Alerts List to see what's firing.

### 2. DORA Metrics — Engineering Performance
Provides a high-level executive view of engineering velocity and stability.
* **Deployment Frequency (DF)**: Real-time 24h count with DORA classification (**Elite/High/Medium/Low**) mapped based on HNG benchmarks.
* **Change Failure Rate (CFR)**: 7-day rolling CFR % with DORA classification, plus a CFR trend timeline featuring a dashed red 15% SLO threshold line.
* **Mean Time to Restore (MTTR)**: 7-day average restore duration in seconds, with DORA classification and a trend timeline featuring a dashed green 1h Elite threshold line.
* **Lead Time for Changes (LTC)**: Point-in-time scatter plot for every GitHub Action deployment workflow duration.

### 3. SLO & Error Budget — Reliability Framework
Implements a strict, user-centric SLO framework to prevent alert fatigue.
* **Availability SLI vs SLO**: 30-day gauge showing compliance against the 99.5% availability target.
* **Error Rate SLI**: 5m success rate gauge against the 99% success target.
* **Latency SLI**: Real-time p95 request duration against the 500ms target.
* **Budget Gauges**: Visual bar gauges with gradient warning thresholds showing exactly what % of availability and error rate budgets remain.
* **Absolute Time Remaining**: Stat panel converting remaining budget into absolute **minutes remaining** (e.g. out of the 30d allowance of 216 minutes) for operational visibility.
* **Burn Rate Timelines**: Dual-burn rate alerting timelines showing 1h fast burn (critical 14.4x threshold line) and 6h slow burn (warning 5x threshold line) to alert on rapid budget consumption.

### 4. Node Exporter — Infrastructure Saturation
Tracks OS and hardware metrics.
* **Resource Summary Row**: Total CPU cores, RAM size, Root filesystem capacity, uptime counter, and real-time CPU & memory gauge dials.
* **Per-Core CPU Utilisation**: Graphing every individual CPU core's saturation (required for granular performance debugging).
* **Memory & Storage Areas**: Stacked area representation of used, cached, and free RAM. Load averages mapped alongside a red horizontal reference line indicating maximum healthy load. Negative-written disk and network I/O charts for bidirectional write/transmit visualization.

### 5. Blackbox Exporter — Uptime & SSL Expiry
Acts as an external prober simulating real customer traffic.
* **Target Management**: Current uptime %, total tracked endpoints count, and a giant critical counter displaying the number of currently down targets.
* **Probe Latency Breakdown**: Stacked area chart showing response times broken down by network phases: DNS resolution time, TCP connection handshakes, SSL handshakes, server processing lag, and transfer duration.
* **SSL Expiry Countdown**: Bar gauge showing remaining days until SSL certificates expire, color-coded to warn when expiry is less than 30 (warning) or 14 (critical) days.

---

## Alert Silencing Guide

Alertmanager includes native silencing to suppress notifications during planned maintenance windows, preventing alert spam.

### How to Silence an Alert via Web UI

1. Open Alertmanager at `http://YOUR_SERVER_IP:9093`.
2. Click **Silences** in the top navigation bar, then click **New Silence**.
3. Under **Matchers**, define which alerts to silence. For example:
   * To silence a specific node's memory alerts: `alertname="HighMemoryWarning"`, `instance="127.0.0.1:9100"`.
   * To silence all warning-level alerts: `severity="warning"`.
4. Set the **Start**, **End**, or **Duration** (e.g., `2h` for a 2-hour maintenance window).
5. Enter a **Creator** name and **Comment** (e.g., "Planned RAM upgrade").
6. Click **Create** to activate the silence. Firing matches will immediately disappear from your Slack channel.

### How to Silence via CLI (Command Line)
If you have SSH access, you can use the `amtool` CLI tool which comes pre-installed in `/usr/local/bin/amtool`:
```bash
# Silence all HighMemoryWarning alerts on a node for 1 hour
amtool silence add alertname=HighMemoryWarning instance="127.0.0.1:9100" --duration=1h --comment="Planned maintenance" --author="DevOps Team"
```

---

## Game Day Scenarios — Self-Healing & Alert Verification

To satisfy Part 7, three Game Day simulation scenarios are pre-configured to verify alert routing, runbook accuracy, and self-healing mechanisms:

### Scenario 1: CPU Saturation & Alertmanager Inhibition
* **Objective**: Simulate severe CPU load to verify that the Warning alert fires, escalates to Critical, routes to Slack, and inhibits lower-priority alerts.
* **Action**: SSH into the server and run:
  ```bash
  # Ingress CPU stress on all cores for 10 minutes
  sudo apt-get install -y stress-ng
  stress-ng --cpu $(nproc) --timeout 600s
  ```
* **Expected Result**:
  1. `HighCPUWarning` fires in Alertmanager after 5 minutes and posts a warning to Slack.
  2. CPU continues to stay >90% -> `HighCPUCritical` fires after 10 minutes and posts a critical alert to Slack.
  3. Alertmanager's inhibition rules automatically suppress the warning-level alert so only the critical alert is active (reducing alert noise).

### Scenario 2: Network Latency & SLO Burn Rate Alerting
* **Objective**: Inject artificial network delay to exceed the 500ms p95 latency SLO, triggering the SLO slow-burn warning and fast-burn critical alerts.
* **Action**: Run the traffic-shaping command on the server's external interface (replace `eth0` with your interface name e.g. `ens5`):
  ```bash
  # Inject 600ms latency on all outbound network traffic
  sudo tc qdisc add dev eth0 root netem delay 600ms
  ```
  *To revert the latency injection after testing:*
  ```bash
  sudo tc qdisc del dev eth0 root
  ```
* **Expected Result**:
  1. The Blackbox probe response time exceeds 500ms.
  2. The `HighLatencyWarning` alert fires after 5 minutes.
  3. The availability error budget begins to burn.
  4. The 1h fast-burn rate exceeds 14.4x -> `SLOAvailabilityFastBurn` triggers a critical notification in Slack.
  5. Engineers click the Slack runbook link leading directly to `runbooks/high-latency.md` or `runbooks/slo-fast-burn.md`.

### Scenario 3: Deployment Failure & Change Failure Rate (CFR)
* **Objective**: Trigger a mock deployment pipeline failure to verify DORA tracking, CFR calculation, and Alertmanager routing.
* **Action**: Commit a failing step to your CI/CD repository (e.g. add `exit 1` under the deploy script in `.github/workflows/deploy.yml` or push directly to pushgateway):
  ```bash
  # Manually push a failed deployment metric to the Pushgateway
  curl -X POST -d "deployment_total{status=\"failure\",workflow=\"production-deploy\",branch=\"main\"} 1\n" \
    http://localhost:9091/metrics/job/dora_deployer
  ```
* **Expected Result**:
  1. `CICDDeploymentFailed` fires immediately and routes to Slack.
  2. The DORA Metrics dashboard automatically computes the failed deployment, spiking the CFR.
  3. If CFR over 7 days exceeds 15% -> `CICDHighChangeFailureRate` triggers, changing your DORA classification from Elite to Low performer.

---

## SLO Targets

| SLO | Target | Window | Error budget | Runbook |
|-----|--------|--------|--------------|---------|
| **Availability** | 99.5% | 30 days | 216 minutes | [slo-fast-burn.md](./runbooks/slo-fast-burn.md) |
| **Error rate** | 99% success | 30 days | 432 minutes | [slo-slow-burn.md](./runbooks/slo-slow-burn.md) |
| **Latency p95** | < 500ms | Rolling | Alert-only | [high-latency.md](./runbooks/high-latency.md) |

See [slo-definitions.yml](./slo-definitions.yml) and [error-budget-policy.md](./error-budget-policy.md).

---

## Teardown

To remove all binaries, systemd units, configuration files, and system users provisioned by this stack:
```bash
sudo bash uninstall.sh
```
If deployed via Terraform, clean up the AWS resources using:
```bash
cd terraform
terraform destroy
```
