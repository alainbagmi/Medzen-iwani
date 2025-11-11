#!/bin/bash

# EHRbase Studio Deployment Script for Kubernetes
# Deploys EHRbase Studio to existing K3s cluster on Proxmox

set -e  # Exit on error

echo "=========================================="
echo "EHRbase Studio K8s Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check kubectl access
echo -e "${YELLOW}Step 1: Checking kubectl access...${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found. Please install kubectl.${NC}"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster.${NC}"
    echo "Please ensure you're running this on a K3s master node or have kubeconfig configured."
    exit 1
fi

echo -e "${GREEN}✓ kubectl access confirmed${NC}"
kubectl get nodes
echo ""

# Step 2: Check if ehrbase namespace exists
echo -e "${YELLOW}Step 2: Checking/creating ehrbase namespace...${NC}"
if kubectl get namespace ehrbase &> /dev/null; then
    echo -e "${GREEN}✓ ehrbase namespace already exists${NC}"
else
    echo "Creating ehrbase namespace..."
    kubectl create namespace ehrbase
    echo -e "${GREEN}✓ ehrbase namespace created${NC}"
fi
echo ""

# Step 3: Deploy EHRbase Studio
echo -e "${YELLOW}Step 3: Deploying EHRbase Studio...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/../k8s/ehrbase-studio-deployment.yaml"

if [ ! -f "$MANIFEST" ]; then
    echo -e "${RED}Error: Deployment manifest not found at $MANIFEST${NC}"
    exit 1
fi

echo "Applying manifest: $MANIFEST"
kubectl apply -f "$MANIFEST"
echo ""

# Step 4: Wait for deployment
echo -e "${YELLOW}Step 4: Waiting for deployment to be ready...${NC}"
echo "This may take 1-2 minutes..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/ehrbase-studio -n ehrbase

echo -e "${GREEN}✓ Deployment is ready${NC}"
echo ""

# Step 5: Check pods
echo -e "${YELLOW}Step 5: Checking pod status...${NC}"
kubectl get pods -n ehrbase -l app=ehrbase-studio
echo ""

# Step 6: Check service
echo -e "${YELLOW}Step 6: Checking service...${NC}"
kubectl get svc -n ehrbase ehrbase-studio-service
echo ""

# Step 7: Check ingress
echo -e "${YELLOW}Step 7: Checking ingress...${NC}"
if kubectl get ingress -n ehrbase ehrbase-studio-ingress &> /dev/null; then
    kubectl describe ingress -n ehrbase ehrbase-studio-ingress
else
    echo -e "${YELLOW}Warning: Ingress not found. You may need to configure ingress manually.${NC}"
fi
echo ""

# Step 8: Get access URLs
echo -e "${YELLOW}Step 8: Access Information${NC}"
echo "=========================================="

# Try to get ingress URL
INGRESS_HOST=$(kubectl get ingress -n ehrbase ehrbase-studio-ingress \
    -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")

if [ -n "$INGRESS_HOST" ]; then
    echo -e "${GREEN}Studio URL (via Ingress):${NC}"
    echo "  https://$INGRESS_HOST/studio"
else
    echo -e "${YELLOW}No ingress configured. Alternative access methods:${NC}"
fi

# Show NodePort if available
NODEPORT=$(kubectl get svc -n ehrbase ehrbase-studio-service \
    -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")

if [ -n "$NODEPORT" ]; then
    echo ""
    echo -e "${GREEN}Studio URL (via NodePort):${NC}"
    echo "  http://\$(ANY_WORKER_NODE_IP):$NODEPORT"
fi

# Show port-forward command
echo ""
echo -e "${GREEN}Studio URL (via Port Forward):${NC}"
echo "  Run: kubectl port-forward -n ehrbase svc/ehrbase-studio-service 8081:8081"
echo "  Then access: http://localhost:8081"

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Access EHRbase Studio using one of the URLs above"
echo "2. Login with your EHRbase credentials"
echo "3. Upload OpenEHR templates"
echo "4. Browse EHRs and compositions"
echo ""
echo "To view logs:"
echo "  kubectl logs -n ehrbase -l app=ehrbase-studio -f"
echo ""
echo "To scale deployment:"
echo "  kubectl scale deployment ehrbase-studio -n ehrbase --replicas=3"
echo ""
