#!/bin/bash

# EHRbase Admin Dashboard - Quick Deploy Script
set -e

echo "========================================="
echo "EHRbase Admin Dashboard Deployment"
echo "========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to Kubernetes cluster."
    echo "Please ensure you have cluster access configured."
    exit 1
fi

echo "✓ kubectl found and cluster is accessible"
echo ""

# Check if ehrbase namespace exists
if ! kubectl get namespace ehrbase &> /dev/null; then
    echo "Creating ehrbase namespace..."
    kubectl create namespace ehrbase
fi

echo "✓ ehrbase namespace exists"
echo ""

# Apply the deployment
echo "Applying deployment..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
kubectl apply -f "${SCRIPT_DIR}/kubernetes/complete-deployment.yaml"

echo ""
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/ehrbase-admin-ui -n ehrbase

echo ""
echo "========================================="
echo "Deployment Status"
echo "========================================="
echo ""

# Show pod status
echo "Pods:"
kubectl get pods -n ehrbase -l app=ehrbase-admin-ui

echo ""
echo "Service:"
kubectl get svc -n ehrbase ehrbase-admin-ui

echo ""
echo "========================================="
echo "Access Information"
echo "========================================="
echo ""

# Get NodePort
NODEPORT=$(kubectl get svc ehrbase-admin-ui -n ehrbase -o jsonpath='{.spec.ports[0].nodePort}')

echo "Dashboard is accessible at:"
echo "  http://10.10.10.101:${NODEPORT}"
echo "  http://10.10.10.102:${NODEPORT}"
echo "  http://10.10.10.103:${NODEPORT}"
echo "  http://10.10.10.104:${NODEPORT}"
echo "  http://10.10.10.105:${NODEPORT}"
echo "  http://10.10.10.106:${NODEPORT}"
echo ""
echo "Default Settings:"
echo "  EHRbase URL: https://ehr.medzenhealth.app"
echo "  Username: ehrbase-user"
echo "  Password: ehrbase-password"
echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
