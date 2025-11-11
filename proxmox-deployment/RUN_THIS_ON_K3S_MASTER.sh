#!/bin/bash
#
# EHRbase Studio Deployment Script
# Run this on ehrbase-k3-master-1 (VM 101)
#

set -e

echo "========================================"
echo "  EHRbase Studio K3s Deployment"
echo "========================================"
echo ""

# Create manifest
cat <<'EOFMANIFEST' > /tmp/ehrbase-studio.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ehrbase
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ehrbase-studio
  namespace: ehrbase
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ehrbase-studio
  template:
    metadata:
      labels:
        app: ehrbase-studio
    spec:
      containers:
      - name: studio
        image: ehrbase/ehrbase-studio:latest
        ports:
        - containerPort: 8081
        env:
        - name: EHRBASE_REST_URL
          value: "http://ehrbase-api-service:8080/ehrbase/rest"
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: ehrbase-studio-service
  namespace: ehrbase
spec:
  type: NodePort
  selector:
    app: ehrbase-studio
  ports:
  - port: 8081
    targetPort: 8081
    nodePort: 30081
EOFMANIFEST

echo "✓ Manifest created"
echo ""

# Deploy
echo "Deploying to K8s cluster..."
kubectl apply -f /tmp/ehrbase-studio.yaml

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/ehrbase-studio -n ehrbase || true

echo ""
echo "========================================"
echo "  Deployment Status"
echo "========================================"
kubectl get pods -n ehrbase -l app=ehrbase-studio
echo ""
kubectl get svc -n ehrbase

echo ""
echo "========================================"
echo "  Access Studio"
echo "========================================"
echo ""
echo "Studio URL: http://$(hostname -I | awk '{print $1}'):30081"
echo ""
echo "✓ Deployment Complete!"
