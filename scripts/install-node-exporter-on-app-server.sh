#!/usr/bin/env bash
# Run this script ONCE on your application server (13.63.206.183)
# It installs Node Exporter so the monitoring server can scrape system metrics
# Usage: sudo bash install-node-exporter.sh

set -euo pipefail

GREEN='\033[0;32m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }

[[ $EUID -ne 0 ]] && echo "Run with sudo" && exit 1

NODE_EXPORTER_VERSION="1.7.0"
ARCH="amd64"

info "Installing Node Exporter ${NODE_EXPORTER_VERSION} on app server..."

# Create user
if ! id node_exporter &>/dev/null; then
  useradd --no-create-home --shell /bin/false node_exporter
fi

# Download and install binary
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz" \
  -O /tmp/node_exporter.tar.gz
tar -xzf /tmp/node_exporter.tar.gz -C /tmp/
cp "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter" /usr/local/bin/
chmod +x /usr/local/bin/node_exporter
rm -rf /tmp/node_exporter*

# Create systemd unit
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=0.0.0.0:9100
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
sleep 3

if systemctl is-active --quiet node_exporter; then
  info "✓ Node Exporter running on port 9100"
  info "  Verify: curl http://localhost:9100/metrics | head -5"
else
  echo "Node Exporter failed to start"
  journalctl -u node_exporter -n 20
  exit 1
fi

info "Done. Make sure port 9100 is open in your AWS security group."
info "Only allow access from your monitoring server IP — not 0.0.0.0/0"
