#!/bin/bash
#
# EHRbase Studio One-Command Deployment
# Run this on any K3s master node
#
# Usage: curl -sL https://your-server/DEPLOY_NOW.sh | bash
# Or: bash DEPLOY_NOW.sh
#

set -e

echo "=========================================="
echo "  EHRbase Studio Deployment"
echo "  MedZen Iwani - Proxmox K3s Cluster"
echo "=========================================="
echo ""

# Check if running on K3s node
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please run this on a K3s master node."
    exit 1
fi

# Create deployment manifest inline
cat <<'EOF' > /tmp/ehrbase-studio-deployment.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ehrbase
  labels:
    name: ehrbase
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ehrbase-studio
  namespace: ehrbase
  labels:
    app: ehrbase-studio
    component: web-ui
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: ehrbase-studio
  template:
    metadata:
      labels:
        app: ehrbase-studio
        component: web-ui
    spec:
      containers:
      - name: studio
        image: ehrbase/ehrbase-studio:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8081
          name: http
          protocol: TCP
        env:
        - name: EHRBASE_REST_URL
          value: "http://ehrbase-api-service:8080/ehrbase/rest"
        - name: STUDIO_TITLE
          value: "MedZen Iwani EHRbase Studio"
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /
            port: 8081
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8081
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 5
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
---
apiVersion: v1
kind: Service
metadata:
  name: ehrbase-studio-service
  namespace: ehrbase
  labels:
    app: ehrbase-studio
spec:
  selector:
    app: ehrbase-studio
  ports:
  - protocol: TCP
    port: 8081
    targetPort: 8081
    name: http
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: ehrbase-studio-nodeport
  namespace: ehrbase
  labels:
    app: ehrbase-studio
spec:
  type: NodePort
  selector:
    app: ehrbase-studio
  ports:
  - protocol: TCP
    port: 8081
    targetPort: 8081
    nodePort: 30081
    name: http
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ehrbase-studio-ingress
  namespace: ehrbase
  annotations:
    kubernetes.io/ingress.class: "traefik"
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  rules:
  - host: ehr.medzenhealth.app
    http:
      paths:
      - path: /studio
        pathType: Prefix
        backend:
          service:
            name: ehrbase-studio-service
            port:
              number: 8081
  tls:
  - hosts:
    - ehr.medzenhealth.app
    secretName: ehrbase-studio-tls
EOF

echo "✓ Deployment manifest created"
echo ""

# Apply deployment
echo "Deploying EHRbase Studio to K8s cluster..."
kubectl apply -f /tmp/ehrbase-studio-deployment.yaml

echo ""
echo "Waiting for deployment to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/ehrbase-studio -n ehrbase || true

echo ""
echo "=========================================="
echo "Deployment Status"
echo "=========================================="
kubectl get pods -n ehrbase -l app=ehrbase-studio
echo ""
kubectl get svc -n ehrbase
echo ""

echo "=========================================="
echo "Access Information"
echo "=========================================="
echo ""
echo "Studio is accessible via:"
echo ""
echo "1. NodePort (Direct Access):"
echo "   http://$(hostname -I | awk '{print $1}'):30081"
echo "   http://ANY_WORKER_IP:30081"
echo ""
echo "2. Port Forward (Local Testing):"
echo "   kubectl port-forward -n ehrbase svc/ehrbase-studio-service 8081:8081"
echo "   Then: http://localhost:8081"
echo ""
echo "3. Ingress (Production - after DNS setup):"
echo "   https://ehr.medzenhealth.app/studio"
echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Access Studio using one of the methods above"
echo "2. Login with EHRbase credentials"
echo "3. Upload OpenEHR templates"
echo ""
echo "To view logs:"
echo "  kubectl logs -n ehrbase -l app=ehrbase-studio -f"
echo ""
echo "To check status:"
echo "  kubectl get pods -n ehrbase"
echo ""

# Cleanup
rm -f /tmp/ehrbase-studio-deployment.yaml

echo "✓ Deployment Complete!"
echo ""
