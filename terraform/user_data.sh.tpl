#!/bin/bash
# This script runs automatically when the monitoring server EC2 instance starts
# It installs all dependencies and deploys the full LGTM stack

set -euo pipefail
exec > /var/log/monitoring-install.log 2>&1

echo "=== MeetMind Monitoring Server Bootstrap ==="
echo "App server: ${app_server_ip}"
echo "Started at: $(date)"

# Wait for apt to be ready
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for apt lock..."
  sleep 5
done

# System updates and dependencies
apt-get update -qq
apt-get install -y -qq git curl wget

# Clone the observability repo
git clone ${repo_url} /opt/meetmind-observability
cd /opt/meetmind-observability

# Inject the app server IP into all configs
grep -rl "YOUR_SERVER_IP" . --include="*.yml" --include="*.yaml" --include="*.json" | \
  xargs sed -i "s|YOUR_SERVER_IP|${app_server_ip}|g" 2>/dev/null || true

# Set Grafana password
sed -i "s|GF_SECURITY_ADMIN_PASSWORD=admin|GF_SECURITY_ADMIN_PASSWORD=${grafana_password}|g" \
  install.sh 2>/dev/null || true

# Run the install script
SLACK_WEBHOOK="${slack_webhook}" \
APP_SERVER_IP="${app_server_ip}" \
bash install.sh

echo "=== Bootstrap complete at $(date) ==="
echo "Grafana: http://$(curl -s ifconfig.me):3000"
