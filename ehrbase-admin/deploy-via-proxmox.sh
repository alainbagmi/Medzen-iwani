#!/bin/bash

# Deployment script using Proxmox commands
# This creates a temporary deployment package and transfers it

set -e

echo "Creating deployment package..."

# Create temp directory
TMPDIR=$(mktemp -d)
PACKAGE="${TMPDIR}/ehrbase-admin.tar.gz"

# Create tarball
tar -czf "${PACKAGE}" \
    -C /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin \
    Dockerfile nginx.conf index.html js css kubernetes

# Encode as base64
BASE64_PACKAGE=$(base64 < "${PACKAGE}")

echo "Package created: $(du -h "${PACKAGE}" | cut -f1)"
echo "Base64 size: ${#BASE64_PACKAGE} characters"

# Save to file for manual deployment
echo "${BASE64_PACKAGE}" > /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin/deployment-package.b64

echo ""
echo "Deployment package created at:"
echo "  /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin/deployment-package.b64"
echo ""
echo "To deploy, run these commands on the Kubernetes master node:"
echo ""
echo "  # Decode and extract"
echo "  cat > /tmp/ehrbase-admin.tar.gz.b64 << 'EOF'"
echo "  ${BASE64_PACKAGE}"
echo "  EOF"
echo ""
echo "  base64 -d < /tmp/ehrbase-admin.tar.gz.b64 > /tmp/ehrbase-admin.tar.gz"
echo "  mkdir -p /tmp/ehrbase-admin"
echo "  tar -xzf /tmp/ehrbase-admin.tar.gz -C /tmp/ehrbase-admin"
echo "  cd /tmp/ehrbase-admin"
echo "  docker build -t ehrbase-admin-ui:latest ."
echo "  kubectl apply -f kubernetes/deployment.yaml"
echo ""

# Cleanup
rm -rf "${TMPDIR}"

echo "Package ready for deployment!"
