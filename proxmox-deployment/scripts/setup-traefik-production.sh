#!/bin/bash
#
# Complete Traefik + EHRbase Ingress Production Setup
# Run this on K3s master node (VM 101)
#
# This script:
# 1. Installs Traefik v2.10 with proper RBAC
# 2. Creates IngressClass
# 3. Configures Ingress for EHRbase
# 4. Sets up LoadBalancer
# 5. Optionally configures Let's Encrypt SSL
#

set -e

echo "=========================================="
echo "  Traefik + EHRbase Production Setup"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${DOMAIN:-ehrbase.mylestechsolutions.com}"
EMAIL="${EMAIL:-admin@mylestechsolutions.com}"
ENABLE_SSL="${ENABLE_SSL:-false}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Domain: $DOMAIN"
echo "  Email: $EMAIL"
echo "  SSL: $ENABLE_SSL"
echo ""

# Step 1: Install Traefik CRDs
echo -e "${YELLOW}Step 1: Installing Traefik CRDs...${NC}"
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

# Step 2: Install Traefik RBAC
echo -e "${YELLOW}Step 2: Installing Traefik RBAC...${NC}"
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml

# Step 3: Create Traefik Deployment
echo -e "${YELLOW}Step 3: Creating Traefik deployment...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: kube-system
  labels:
    app: traefik
spec:
  replicas: 2
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-ingress-controller
      containers:
      - name: traefik
        image: traefik:v2.10
        args:
        - --api.insecure=true
        - --api.dashboard=true
        - --providers.kubernetesingress
        - --providers.kubernetescrd
        - --entrypoints.web.address=:80
        - --entrypoints.websecure.address=:443
        - --log.level=INFO
        $(if [ "$ENABLE_SSL" = "true" ]; then echo "        - --certificatesresolvers.letsencrypt.acme.email=$EMAIL"; fi)
        $(if [ "$ENABLE_SSL" = "true" ]; then echo "        - --certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"; fi)
        $(if [ "$ENABLE_SSL" = "true" ]; then echo "        - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"; fi)
        ports:
        - name: web
          containerPort: 80
        - name: websecure
          containerPort: 443
        - name: admin
          containerPort: 8080
        $(if [ "$ENABLE_SSL" = "true" ]; then echo "        volumeMounts:"; fi)
        $(if [ "$ENABLE_SSL" = "true" ]; then echo "        - name: data"; fi)
        $(if [ "$ENABLE_SSL" = "true" ]; then echo "          mountPath: /data"; fi)
      $(if [ "$ENABLE_SSL" = "true" ]; then echo "      volumes:"; fi)
      $(if [ "$ENABLE_SSL" = "true" ]; then echo "      - name: data"; fi)
      $(if [ "$ENABLE_SSL" = "true" ]; then echo "        emptyDir: {}"; fi)
EOF

echo -e "${GREEN}✓ Traefik deployment created${NC}"

# Step 4: Create Traefik Service
echo -e "${YELLOW}Step 4: Creating Traefik service...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: kube-system
spec:
  type: LoadBalancer
  selector:
    app: traefik
  ports:
  - name: web
    port: 80
    targetPort: 80
  - name: websecure
    port: 443
    targetPort: 443
  - name: admin
    port: 8080
    targetPort: 8080
EOF

echo -e "${GREEN}✓ Traefik service created${NC}"

# Step 5: Create IngressClass
echo -e "${YELLOW}Step 5: Creating IngressClass...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: traefik
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: traefik.io/ingress-controller
EOF

echo -e "${GREEN}✓ IngressClass created${NC}"

# Step 6: Wait for Traefik to be ready
echo -e "${YELLOW}Step 6: Waiting for Traefik to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/traefik -n kube-system

# Step 7: Create EHRbase Ingress
echo -e "${YELLOW}Step 7: Creating EHRbase ingress...${NC}"
if [ "$ENABLE_SSL" = "true" ]; then
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ehrbase-ingress
  namespace: ehrbase
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - $DOMAIN
    secretName: ehrbase-tls
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ehrbase
            port:
              number: 8080
EOF
else
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ehrbase-ingress
  namespace: ehrbase
spec:
  ingressClassName: traefik
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ehrbase
            port:
              number: 8080
EOF
fi

echo -e "${GREEN}✓ EHRbase ingress created${NC}"

# Step 8: Display status
echo ""
echo "=========================================="
echo -e "${GREEN}  Setup Complete!${NC}"
echo "=========================================="
echo ""

# Get LoadBalancer IPs
LB_IPS=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[*].ip}' | tr ' ' ',')

echo "Traefik LoadBalancer IPs: $LB_IPS"
echo ""
echo "Next Steps:"
echo "1. Update DNS for $DOMAIN to point to: ${LB_IPS%%,*}"
echo "2. Wait for DNS propagation (1-5 minutes)"
if [ "$ENABLE_SSL" = "true" ]; then
  echo "3. Access EHRbase at: https://$DOMAIN/ehrbase/swagger-ui/index.html"
  echo "4. SSL certificate will be automatically obtained from Let's Encrypt"
else
  echo "3. Access EHRbase at: http://$DOMAIN/ehrbase/swagger-ui/index.html"
fi
echo ""
echo "Monitoring:"
echo "  Traefik dashboard: http://${LB_IPS%%,*}:8080/dashboard/"
echo "  View ingress: kubectl get ingress -n ehrbase"
echo "  View Traefik logs: kubectl logs -n kube-system -l app=traefik -f"
echo ""

# Test ingress
echo -e "${YELLOW}Testing ingress routing...${NC}"
FIRST_IP="${LB_IPS%%,*}"
TEST_RESULT=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" "http://$FIRST_IP/ehrbase/rest/openehr/v1/definition/template/adl1.4" || echo "000")

if [ "$TEST_RESULT" = "401" ]; then
  echo -e "${GREEN}✓ Ingress routing working! (401 = authentication required, which is expected)${NC}"
elif [ "$TEST_RESULT" = "200" ]; then
  echo -e "${GREEN}✓ Ingress routing working perfectly!${NC}"
else
  echo -e "${YELLOW}⚠ Ingress test returned HTTP $TEST_RESULT${NC}"
  echo "  This may be normal if EHRbase requires authentication"
  echo "  Check logs: kubectl logs -n kube-system -l app=traefik --tail=50"
fi

echo ""
echo -e "${GREEN}Setup script completed successfully!${NC}"
