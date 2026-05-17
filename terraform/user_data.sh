#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# MeetMind Observability — Cloud-Init Bootstrap Script
# This runs automatically when the EC2 instance first boots.
# It clones the repo and executes install.sh to deploy the full LGTM stack.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
exec > /var/log/meetmind-bootstrap.log 2>&1

echo "========================================"
echo " MeetMind Bootstrap — $(date -u)"
echo "========================================"

# ── 1. System updates ────────────────────────────────────────────────────────
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq git curl wget

# ── 2. Clone the repository ──────────────────────────────────────────────────
REPO_DIR="/opt/meetmind-observability"
git clone --branch "${github_branch}" "${github_repo}" "$REPO_DIR"
cd "$REPO_DIR"

# ── 3. Detect the public IP and patch configs ────────────────────────────────
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || curl -s ifconfig.me)
echo "Detected server IP: $SERVER_IP"

# Replace placeholder IPs in alert annotations and runbook URLs
find . -name '*.yml' -o -name '*.yaml' -o -name '*.json' -o -name '*.md' | \
  xargs sed -i "s|YOUR_SERVER_IP|$SERVER_IP|g" 2>/dev/null || true

# Replace placeholder org in runbook URLs
find . -name '*.yml' -o -name '*.yaml' | \
  xargs sed -i "s|your-org|AirFluke|g" 2>/dev/null || true

# ── 4. Run the install script ────────────────────────────────────────────────
export SLACK_WEBHOOK="${slack_webhook_url}"
bash install.sh

# ── 5. Verify all services are running ────────────────────────────────────────
echo ""
echo "========================================"
echo " Bootstrap Complete — $(date -u)"
echo " Server IP: $SERVER_IP"
echo " Grafana:   http://$SERVER_IP:3000"
echo "========================================"

bash scripts/status.sh
