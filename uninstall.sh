#!/usr/bin/env bash
# MeetMind Observability Platform — Uninstall Script
# Usage: sudo bash uninstall.sh

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

[[ $EUID -ne 0 ]] && echo "Run with sudo" && exit 1

warn "This will remove ALL MeetMind observability components."
read -rp "Are you sure? (yes/no): " confirm
[[ "${confirm}" != "yes" ]] && echo "Aborted." && exit 0

SERVICES=(
  prometheus node_exporter blackbox_exporter
  alertmanager pushgateway loki tempo otelcol grafana-server
)

info "Stopping and disabling all services..."
for svc in "${SERVICES[@]}"; do
  systemctl stop "${svc}"    2>/dev/null || true
  systemctl disable "${svc}" 2>/dev/null || true
  rm -f "/etc/systemd/system/${svc}.service"
done
systemctl daemon-reload

info "Removing binaries..."
rm -f /usr/local/bin/prometheus /usr/local/bin/promtool
rm -f /usr/local/bin/node_exporter
rm -f /usr/local/bin/blackbox_exporter
rm -f /usr/local/bin/alertmanager
rm -f /usr/local/bin/pushgateway
rm -f /usr/local/bin/loki
rm -f /usr/local/bin/tempo
rm -f /usr/local/bin/otelcol

info "Removing configs..."
rm -rf /etc/prometheus /etc/alertmanager /etc/blackbox_exporter
rm -rf /etc/loki /etc/tempo /etc/otelcol

info "Removing Grafana..."
apt-get remove -y grafana 2>/dev/null || true
rm -rf /etc/grafana /var/lib/grafana

info "Removing data directories..."
rm -rf /var/lib/prometheus /var/lib/loki /var/lib/tempo

info "Removing users..."
for user in prometheus node_exporter blackbox_exporter alertmanager pushgateway loki tempo otelcol; do
  userdel "${user}" 2>/dev/null || true
done

info "Uninstall complete."
