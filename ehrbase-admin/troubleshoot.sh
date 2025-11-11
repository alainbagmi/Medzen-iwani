#!/bin/bash

# EHRbase Admin Dashboard - Troubleshooting Script

echo "========================================="
echo "EHRbase Admin Dashboard Troubleshooting"
echo "========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ ERROR: kubectl not found"
    exit 1
fi

echo "1. Checking namespace..."
if kubectl get namespace ehrbase &> /dev/null; then
    echo "   ✓ ehrbase namespace exists"
else
    echo "   ❌ ehrbase namespace does NOT exist"
    echo "   Run: kubectl create namespace ehrbase"
fi

echo ""
echo "2. Checking ConfigMap..."
if kubectl get configmap ehrbase-admin-html -n ehrbase &> /dev/null; then
    echo "   ✓ ConfigMap exists"
    kubectl get configmap ehrbase-admin-html -n ehrbase
else
    echo "   ❌ ConfigMap does NOT exist"
    echo "   Deployment may not have been applied"
fi

echo ""
echo "3. Checking Deployment..."
if kubectl get deployment ehrbase-admin-ui -n ehrbase &> /dev/null; then
    echo "   ✓ Deployment exists"
    kubectl get deployment ehrbase-admin-ui -n ehrbase
else
    echo "   ❌ Deployment does NOT exist"
    echo "   Run the deploy.sh script"
fi

echo ""
echo "4. Checking Pods..."
PODS=$(kubectl get pods -n ehrbase -l app=ehrbase-admin-ui --no-headers 2>/dev/null | wc -l)
if [ "$PODS" -gt 0 ]; then
    echo "   ✓ Found $PODS pod(s)"
    kubectl get pods -n ehrbase -l app=ehrbase-admin-ui

    echo ""
    echo "   Pod Status Details:"
    kubectl describe pods -n ehrbase -l app=ehrbase-admin-ui | grep -E "Status:|Ready:|Restart Count:|Events:" -A 5
else
    echo "   ❌ No pods found"
    echo "   Deployment may have failed"
fi

echo ""
echo "5. Checking Service..."
if kubectl get svc ehrbase-admin-ui -n ehrbase &> /dev/null; then
    echo "   ✓ Service exists"
    kubectl get svc ehrbase-admin-ui -n ehrbase

    NODEPORT=$(kubectl get svc ehrbase-admin-ui -n ehrbase -o jsonpath='{.spec.ports[0].nodePort}')
    echo ""
    echo "   NodePort: $NODEPORT"
else
    echo "   ❌ Service does NOT exist"
    echo "   Run the deploy.sh script"
fi

echo ""
echo "6. Checking Pod Logs..."
POD_NAME=$(kubectl get pods -n ehrbase -l app=ehrbase-admin-ui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    echo "   Logs from pod: $POD_NAME"
    kubectl logs -n ehrbase "$POD_NAME" --tail=20
else
    echo "   ❌ No running pods to check logs"
fi

echo ""
echo "7. Testing Service Endpoints..."
ENDPOINTS=$(kubectl get endpoints ehrbase-admin-ui -n ehrbase -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -n "$ENDPOINTS" ]; then
    echo "   ✓ Service has endpoints: $ENDPOINTS"
else
    echo "   ❌ Service has NO endpoints"
    echo "   This means no pods are ready to serve traffic"
fi

echo ""
echo "========================================="
echo "Common Issues and Solutions"
echo "========================================="
echo ""
echo "If you see 404 errors:"
echo "  1. Ensure deployment is applied: ./deploy.sh"
echo "  2. Wait for pods to be ready: kubectl wait --for=condition=ready pod -l app=ehrbase-admin-ui -n ehrbase --timeout=120s"
echo "  3. Check pod logs above for errors"
echo "  4. Verify correct URL: http://<node-ip>:30090"
echo ""
echo "If pods are not running:"
echo "  1. Check events: kubectl describe deployment ehrbase-admin-ui -n ehrbase"
echo "  2. Check pod events: kubectl describe pods -n ehrbase -l app=ehrbase-admin-ui"
echo "  3. Verify image can be pulled: nginx:alpine"
echo ""
echo "========================================="
