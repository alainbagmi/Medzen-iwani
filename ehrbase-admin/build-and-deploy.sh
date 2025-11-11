#!/bin/bash

# EHRbase Admin Dashboard - Build and Deploy Script
# This script builds the Docker image and deploys to Kubernetes

set -e

echo "=========================================="
echo "EHRbase Admin Dashboard Deployment"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="ehrbase-admin-ui"
IMAGE_TAG="latest"
NAMESPACE="ehrbase"
K8S_MASTER="10.10.10.101"  # k3s-master-1 IP

echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"
if ! command -v ssh &> /dev/null; then
    echo -e "${RED}Error: ssh command not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

echo -e "${YELLOW}[2/5] Creating deployment tarball...${NC}"
tar -czf /tmp/ehrbase-admin.tar.gz \
    Dockerfile \
    nginx.conf \
    index.html \
    js/ \
    css/ \
    kubernetes/
echo -e "${GREEN}✓ Tarball created${NC}"
echo ""

echo -e "${YELLOW}[3/5] Copying files to Kubernetes master node...${NC}"
scp /tmp/ehrbase-admin.tar.gz root@${K8S_MASTER}:/tmp/
ssh root@${K8S_MASTER} "mkdir -p /tmp/ehrbase-admin && tar -xzf /tmp/ehrbase-admin.tar.gz -C /tmp/ehrbase-admin"
echo -e "${GREEN}✓ Files copied${NC}"
echo ""

echo -e "${YELLOW}[4/5] Building Docker image on Kubernetes cluster...${NC}"
ssh root@${K8S_MASTER} "cd /tmp/ehrbase-admin && docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
echo -e "${GREEN}✓ Docker image built${NC}"
echo ""

echo -e "${YELLOW}[5/5] Deploying to Kubernetes...${NC}"
ssh root@${K8S_MASTER} "kubectl apply -f /tmp/ehrbase-admin/kubernetes/deployment.yaml"
echo -e "${GREEN}✓ Deployment applied${NC}"
echo ""

echo -e "${YELLOW}Waiting for pods to be ready...${NC}"
ssh root@${K8S_MASTER} "kubectl rollout status deployment/ehrbase-admin-ui -n ${NAMESPACE} --timeout=120s"
echo ""

echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "Access the dashboard at:"
echo "  🌐 Internal: http://10.10.10.101:30090"
echo "  🌐 Internal: http://10.10.10.102:30090"
echo "  🌐 Internal: http://10.10.10.103:30090"
echo ""
echo "Default EHRbase connection:"
echo "  URL: https://ehr.medzenhealth.app"
echo "  Username: ehrbase-user"
echo "  Password: ehrbase-password"
echo ""
echo "Check deployment status:"
echo "  kubectl get pods -n ${NAMESPACE} -l app=ehrbase-admin-ui"
echo "  kubectl get svc -n ${NAMESPACE} ehrbase-admin-ui"
echo ""
