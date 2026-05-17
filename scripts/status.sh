#!/usr/bin/env bash
# Check status of all MeetMind observability services
# Usage: sudo bash scripts/status.sh

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

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

echo ""
echo "MeetMind Observability — Service Status"
echo "========================================="
printf "%-25s %-12s %s\n" "SERVICE" "STATUS" "PORT"
echo "-----------------------------------------"

check_port() {
  local port=$1
  if ss -tlnp | grep -q ":${port} " 2>/dev/null; then
    echo -n "✓"
  else
    echo -n "✗"
  fi
}

declare -A PORTS=(
  [prometheus]=9090
  [node_exporter]=9100
  [blackbox_exporter]=9115
  [alertmanager]=9093
  [pushgateway]=9091
  [loki]=3100
  [tempo]=3200
  [otelcol]=8888
  [grafana-server]=3000
)

for svc in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "${svc}"; then
    status="${GREEN}running${NC}"
  else
    status="${RED}stopped${NC}"
  fi
  port="${PORTS[$svc]:-?}"
  printf "%-25s ${status}%-6s %s\n" "${svc}" "" "${port}"
done

echo ""
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo "Access URLs:"
echo "  Grafana:      http://${SERVER_IP}:3000"
echo "  Prometheus:   http://${SERVER_IP}:9090"
echo "  Alertmanager: http://${SERVER_IP}:9093"
echo "  Pushgateway:  http://${SERVER_IP}:9091"
echo ""
