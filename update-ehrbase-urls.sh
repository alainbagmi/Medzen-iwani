#!/bin/bash

# Script to update all EHRbase URLs in documentation
# From: medzen-ehrbase-alb-762044994.af-south-1.elb.amazonaws.com
# To: ehr.medzenhealth.app

set -e

echo "Starting EHRbase URL migration in documentation..."

# Define the old and new URLs
OLD_ALB_URL="medzen-ehrbase-alb-762044994.af-south-1.elb.amazonaws.com"
NEW_URL="ehr.medzenhealth.app"
OLD_PROXMOX_URL="ehrbase.mylestechsolutions.com"

# Function to update file
update_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Updating: $file"
        # Update ALB URL
        sed -i.bak "s|${OLD_ALB_URL}|${NEW_URL}|g" "$file"
        # Update Proxmox URL
        sed -i.bak "s|${OLD_PROXMOX_URL}|${NEW_URL}|g" "$file"
        rm -f "${file}.bak"
    else
        echo "Warning: File not found - $file"
    fi
}

# AWS Deployment Documentation
echo ""
echo "Updating AWS deployment documentation..."
update_file "EHRBASE_DEPLOYMENT_COMPLETE.md"
update_file "EHRBASE_TEST_COMPOSITIONS_REPORT.md"
update_file "DEPLOYED_TEMPLATES_SUMMARY.md"
update_file "SESSION_SUMMARY.md"
update_file "aws-deployment/DEPLOYMENT_SUMMARY.md"
update_file "aws-deployment/DEPLOYMENT_GUIDE.md"
update_file "aws-deployment/AWS-EHRBASE-PRODUCTION-DEPLOYMENT-GUIDE.md"
update_file "aws-deployment/AWS_EHRBASE_DEPLOYMENT_GUIDE.md"
update_file "aws-deployment/AWS_EHRBASE_QUICK_START.md"
update_file "aws-deployment/AWS_EHRBASE_ARCHITECTURE.md"

# Proxmox Deployment Documentation
echo ""
echo "Updating Proxmox deployment documentation..."
update_file "proxmox-deployment/QUICK_START.md"
update_file "proxmox-deployment/DEPLOYMENT_SUMMARY.md"
update_file "proxmox-deployment/COPY_PASTE_DEPLOYMENT.md"
update_file "proxmox-deployment/DEPLOY_NOW.sh"
update_file "proxmox-deployment/CLOUDFLARE_TUNNEL_SETUP.md"
update_file "proxmox-deployment/docker/docker-compose.yml"
update_file "ehrbase-admin/check-ehrbase.sh"
update_file "ehrbase-admin/build-and-deploy.sh"
update_file "ehrbase-admin/deploy.sh"
update_file "ehrbase-admin/README.md"
update_file "ehrbase-admin/kubernetes/complete-deployment.yaml"

# General Documentation
echo ""
echo "Updating general documentation..."
update_file "CLAUDE.md"
update_file "DEPLOYMENT_CHECKLIST.md"
update_file "QUICK_START.md"
update_file "PRODUCTION_DEPLOYMENT_GUIDE.md"
update_file "EHR_SYSTEM_README.md"
update_file "SYSTEM_INTEGRATION_STATUS.md"

echo ""
echo "✅ Documentation update complete!"
echo "   Updated from:"
echo "   - ${OLD_ALB_URL}"
echo "   - ${OLD_PROXMOX_URL}"
echo "   To: ${NEW_URL}"
