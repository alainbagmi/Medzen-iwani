#!/bin/bash
#
# Cloudflare Tunnel Setup for EHRbase
# Run this on ehrbase-k3-master-1 (VM 101)
#
# This will:
# 1. Install cloudflared
# 2. Create a tunnel
# 3. Route ehrbase.mylestechsolutions.com to the tunnel
# 4. Run as a systemd service
#

set -e

DOMAIN="ehrbase.mylestechsolutions.com"
SERVICE_URL="http://10.10.10.201:30080"
TUNNEL_NAME="ehrbase-tunnel"

echo "==========================================="
echo "  Cloudflare Tunnel Setup for EHRbase"
echo "==========================================="
echo ""
echo "Domain: $DOMAIN"
echo "Service: $SERVICE_URL"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo "Please run as root (sudo bash $0)"
   exit 1
fi

# Step 1: Install cloudflared
echo "Step 1: Installing cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    curl -L --output /tmp/cloudflared.deb \
        https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i /tmp/cloudflared.deb
    echo "✓ cloudflared installed"
else
    echo "✓ cloudflared already installed"
fi

# Step 2: Authenticate (interactive)
echo ""
echo "Step 2: Authenticate with Cloudflare..."
echo "This will open a browser window for authentication."
echo "Press Enter to continue..."
read

cloudflared tunnel login

echo "✓ Authenticated with Cloudflare"

# Step 3: Create tunnel
echo ""
echo "Step 3: Creating tunnel '$TUNNEL_NAME'..."

# Check if tunnel already exists
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo "⚠ Tunnel '$TUNNEL_NAME' already exists"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
else
    cloudflared tunnel create "$TUNNEL_NAME"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    echo "✓ Tunnel created with ID: $TUNNEL_ID"
fi

# Step 4: Create config file
echo ""
echo "Step 4: Creating tunnel configuration..."

mkdir -p /root/.cloudflared

cat > /root/.cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  # Route ehrbase.mylestechsolutions.com to EHRbase service
  - hostname: $DOMAIN
    service: $SERVICE_URL
    originRequest:
      noTLSVerify: true

  # Catch-all rule (required)
  - service: http_status:404
EOF

echo "✓ Configuration created at /root/.cloudflared/config.yml"

# Step 5: Route DNS
echo ""
echo "Step 5: Routing DNS..."
cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN"
echo "✓ DNS route created for $DOMAIN"

# Step 6: Install as service
echo ""
echo "Step 6: Installing as systemd service..."
cloudflared service install
systemctl enable cloudflared
systemctl restart cloudflared

echo "✓ Service installed and started"

# Step 7: Check status
echo ""
echo "==========================================="
echo "  Setup Complete!"
echo "==========================================="
echo ""
echo "Tunnel Status:"
systemctl status cloudflared --no-pager | head -10

echo ""
echo "Access EHRbase:"
echo "  https://$DOMAIN/ehrbase/swagger-ui/index.html"
echo ""
echo "Monitor tunnel:"
echo "  journalctl -u cloudflared -f"
echo ""
echo "Manage tunnel:"
echo "  systemctl status cloudflared"
echo "  systemctl restart cloudflared"
echo "  systemctl stop cloudflared"
echo ""
echo "Note: DNS propagation may take 1-5 minutes"
echo ""
