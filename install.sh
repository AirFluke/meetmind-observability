#!/usr/bin/env bash
# MeetMind Observability Platform — Systemd Install Script
# Ubuntu 24.04 x86_64
# Usage: sudo bash install.sh
# Or with Slack webhook: sudo SLACK_WEBHOOK=https://hooks.slack.com/... bash install.sh

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Must run as root ──────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run this script with sudo: sudo bash install.sh"

# ── Versions ─────────────────────────────────────────────────────────────────
PROMETHEUS_VERSION="2.51.0"
LOKI_VERSION="2.9.7"
TEMPO_VERSION="2.4.1"
ALERTMANAGER_VERSION="0.27.0"
NODE_EXPORTER_VERSION="1.7.0"
BLACKBOX_VERSION="0.25.0"
PUSHGATEWAY_VERSION="1.7.0"
OTEL_VERSION="0.98.0"
GRAFANA_VERSION="10.4.2"

ARCH="amd64"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Slack webhook (optional at install time — can be set later) ───────────────
SLACK_WEBHOOK="${SLACK_WEBHOOK:-YOUR_SLACK_WEBHOOK_URL}"

# ── Server IP detection ───────────────────────────────────────────────────────
SERVER_IP="${SERVER_IP:-$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')}"
info "Detected server IP: ${SERVER_IP}"

info "========================================================"
info " MeetMind Observability Platform — Install Starting"
info "========================================================"

# ── 1. System dependencies ───────────────────────────────────────────────────
info "Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq curl wget tar gzip adduser libfontconfig1 musl

# ── 2. Helper: create system user for a service ──────────────────────────────
create_user() {
  local user=$1
  if ! id "${user}" &>/dev/null; then
    useradd --no-create-home --shell /bin/false "${user}"
    info "Created user: ${user}"
  fi
}

# ── 3. Helper: download and extract binary ───────────────────────────────────
download_binary() {
  local url=$1
  local binary_name=$2
  local extract_path=$3
  local tmp_dir
  tmp_dir=$(mktemp -d)

  info "Downloading ${binary_name}..."
  wget -q "${url}" -O "${tmp_dir}/archive.tar.gz"
  tar -xzf "${tmp_dir}/archive.tar.gz" -C "${tmp_dir}"

  local binary
  binary=$(find "${tmp_dir}" -name "${binary_name}" -type f | head -1)
  [[ -z "${binary}" ]] && error "Binary ${binary_name} not found in archive"

  cp "${binary}" "${extract_path}/${binary_name}"
  chmod +x "${extract_path}/${binary_name}"
  rm -rf "${tmp_dir}"
  info "Installed ${binary_name} to ${extract_path}/${binary_name}"
}

# ─────────────────────────────────────────────────────────────────────────────
# PROMETHEUS
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Prometheus ---"
create_user prometheus
mkdir -p /etc/prometheus/alerts /var/lib/prometheus
chown prometheus:prometheus /var/lib/prometheus

download_binary \
  "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}.tar.gz" \
  "prometheus" "/usr/local/bin"

download_binary \
  "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${ARCH}.tar.gz" \
  "promtool" "/usr/local/bin"

# Copy configs
cp "${SCRIPT_DIR}/config/prometheus.yml" /etc/prometheus/prometheus.yml
cp "${SCRIPT_DIR}/alerts/"*.yml /etc/prometheus/alerts/
chown -R prometheus:prometheus /etc/prometheus

# ─────────────────────────────────────────────────────────────────────────────
# NODE EXPORTER
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Node Exporter ---"
create_user node_exporter

download_binary \
  "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz" \
  "node_exporter" "/usr/local/bin"

# ─────────────────────────────────────────────────────────────────────────────
# BLACKBOX EXPORTER
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Blackbox Exporter ---"
create_user blackbox_exporter
mkdir -p /etc/blackbox_exporter

download_binary \
  "https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_VERSION}/blackbox_exporter-${BLACKBOX_VERSION}.linux-${ARCH}.tar.gz" \
  "blackbox_exporter" "/usr/local/bin"

cp "${SCRIPT_DIR}/config/blackbox.yml" /etc/blackbox_exporter/config.yml
chown -R blackbox_exporter:blackbox_exporter /etc/blackbox_exporter

# ─────────────────────────────────────────────────────────────────────────────
# ALERTMANAGER
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Alertmanager ---"
create_user alertmanager
mkdir -p /etc/alertmanager /var/lib/alertmanager
chown alertmanager:alertmanager /var/lib/alertmanager

download_binary \
  "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-${ARCH}.tar.gz" \
  "alertmanager" "/usr/local/bin"

# Substitute Slack webhook into alertmanager config
sed "s|YOUR_SLACK_WEBHOOK_URL|${SLACK_WEBHOOK}|g" \
  "${SCRIPT_DIR}/config/alertmanager.yml" > /etc/alertmanager/alertmanager.yml

cp "${SCRIPT_DIR}/config/slack.tmpl" /etc/alertmanager/slack.tmpl
chown -R alertmanager:alertmanager /etc/alertmanager

# ─────────────────────────────────────────────────────────────────────────────
# PUSHGATEWAY
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Pushgateway ---"
create_user pushgateway

download_binary \
  "https://github.com/prometheus/pushgateway/releases/download/v${PUSHGATEWAY_VERSION}/pushgateway-${PUSHGATEWAY_VERSION}.linux-${ARCH}.tar.gz" \
  "pushgateway" "/usr/local/bin"

# ─────────────────────────────────────────────────────────────────────────────
# LOKI
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Loki ---"
create_user loki
mkdir -p /etc/loki /var/lib/loki
chown loki:loki /var/lib/loki

wget -q "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-${ARCH}.zip" \
  -O /tmp/loki.zip
apt-get install -y -qq unzip
unzip -q -o /tmp/loki.zip -d /tmp/loki-extract
cp /tmp/loki-extract/loki-linux-${ARCH} /usr/local/bin/loki
chmod +x /usr/local/bin/loki
rm -rf /tmp/loki.zip /tmp/loki-extract

cp "${SCRIPT_DIR}/config/loki-config.yaml" /etc/loki/loki-config.yaml
chown -R loki:loki /etc/loki

# ─────────────────────────────────────────────────────────────────────────────
# TEMPO
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Tempo ---"
create_user tempo
mkdir -p /etc/tempo /var/lib/tempo
chown tempo:tempo /var/lib/tempo

wget -q "https://github.com/grafana/tempo/releases/download/v${TEMPO_VERSION}/tempo_${TEMPO_VERSION}_linux_${ARCH}.tar.gz" \
  -O /tmp/tempo.tar.gz
tar -xzf /tmp/tempo.tar.gz -C /tmp/
cp /tmp/tempo /usr/local/bin/tempo
chmod +x /usr/local/bin/tempo
rm -f /tmp/tempo.tar.gz /tmp/tempo

cp "${SCRIPT_DIR}/config/tempo.yaml" /etc/tempo/tempo.yaml
chown -R tempo:tempo /etc/tempo

# ─────────────────────────────────────────────────────────────────────────────
# OTEL COLLECTOR
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing OpenTelemetry Collector ---"
create_user otelcol
mkdir -p /etc/otelcol

wget -q "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_${ARCH}.tar.gz" \
  -O /tmp/otelcol.tar.gz
tar -xzf /tmp/otelcol.tar.gz -C /tmp/
cp /tmp/otelcol-contrib /usr/local/bin/otelcol
chmod +x /usr/local/bin/otelcol
rm -f /tmp/otelcol.tar.gz /tmp/otelcol-contrib

cp "${SCRIPT_DIR}/config/otel-collector.yaml" /etc/otelcol/otel-collector.yaml
chown -R otelcol:otelcol /etc/otelcol

# ─────────────────────────────────────────────────────────────────────────────
# GRAFANA
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing Grafana ---"
wget -q -O /tmp/grafana.deb \
  "https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb"
dpkg -i /tmp/grafana.deb
rm -f /tmp/grafana.deb

# Copy provisioning and dashboards
cp -r "${SCRIPT_DIR}/grafana/provisioning/"* /etc/grafana/provisioning/
mkdir -p /var/lib/grafana/dashboards
cp "${SCRIPT_DIR}/grafana/dashboards/"*.json /var/lib/grafana/dashboards/
chown -R grafana:grafana /var/lib/grafana /etc/grafana/provisioning

# ─────────────────────────────────────────────────────────────────────────────
# SYSTEMD UNIT FILES
# ─────────────────────────────────────────────────────────────────────────────
info "--- Installing systemd unit files ---"
cp "${SCRIPT_DIR}/systemd/"*.service /etc/systemd/system/
systemctl daemon-reload

# ─────────────────────────────────────────────────────────────────────────────
# ENABLE AND START ALL SERVICES
# ─────────────────────────────────────────────────────────────────────────────
info "--- Enabling and starting all services ---"
SERVICES=(
  prometheus
  node_exporter
  blackbox_exporter
  alertmanager
  pushgateway
  loki
  tempo
  otelcol
  grafana-server
)

for svc in "${SERVICES[@]}"; do
  systemctl enable "${svc}"
  systemctl restart "${svc}"
  sleep 1
  if systemctl is-active --quiet "${svc}"; then
    info "✓ ${svc} is running"
  else
    warn "✗ ${svc} failed to start — check: journalctl -u ${svc} -n 20"
  fi
done

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
echo ""
info "========================================================"
info " Installation Complete!"
info "========================================================"
echo ""
info "Service URLs:"
echo "  Grafana:      http://${SERVER_IP}:3000  (admin/admin)"
echo "  Prometheus:   http://${SERVER_IP}:9090"
echo "  Alertmanager: http://${SERVER_IP}:9093"
echo "  Pushgateway:  http://${SERVER_IP}:9091"
echo "  Loki:         http://${SERVER_IP}:3100"
echo "  Tempo:        http://${SERVER_IP}:3200"
echo ""
info "Check all services: sudo bash scripts/status.sh"
info "View logs: journalctl -u <service-name> -f"
echo ""
if [[ "${SLACK_WEBHOOK}" == "YOUR_SLACK_WEBHOOK_URL" ]]; then
  warn "Slack webhook not set. Update /etc/alertmanager/alertmanager.yml"
  warn "then run: sudo systemctl restart alertmanager"
fi
