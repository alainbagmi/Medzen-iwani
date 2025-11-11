# Proxmox EHRbase Studio Deployment Guide

## Overview
Deploy EHRbase Studio web interface on your existing Proxmox prod-prox cluster to provide admin dashboard for EHR management.

## Current Infrastructure

### Proxmox Cluster: `prod-prox`
- **CPU**: 96 cores
- **Memory**: 503.24 GB (86.43 GB used, 17.2%)
- **Available Resources**: ~83% capacity free

### Existing EHRbase Infrastructure
**K3s Kubernetes Cluster** (3 master nodes):
- `ehrbase-k3-master-1` (VM 101): 2 CPU, 16GB RAM
- `ehrbase-k3-master-2` (VM 103): 2 CPU, 16GB RAM
- `ehrbase-k3-master-3` (VM 102): 2 CPU, 16GB RAM

**K3s Worker Nodes** (3 workers):
- `ehrbase-worker-1` (VM 114): 4 CPU, 16GB RAM
- `ehrbase-worker-2` (VM 105): 4 CPU, 16GB RAM
- `ehrbase-worker-3` (VM 107): 4 CPU, 16GB RAM

## Deployment Strategy

### Option 1: Deploy Studio to Existing K3s Cluster (RECOMMENDED)
Deploy EHRbase Studio as a K8s deployment alongside existing EHRbase API.

**Pros**:
- ✅ Uses existing infrastructure (no new VMs)
- ✅ Zero additional cost
- ✅ Automatic load balancing via K3s
- ✅ Easy updates via kubectl
- ✅ High availability (runs on multiple workers)

**Resource Usage**: ~1 CPU, 2GB RAM (fits easily on existing workers)

### Option 2: Deploy Studio to Single VM
Deploy Studio as Docker container on one existing VM.

**Pros**:
- ✅ Simpler than K8s
- ✅ Isolated from cluster
- ✅ Good for testing

**Cons**:
- ❌ Manual updates required
- ❌ No automatic failover

## Recommended: Option 1 (K3s Deployment)

## Prerequisites

### 1. Access to Proxmox Hosts
```bash
# SSH to prod-prox or one of the K3s masters
ssh user@prod-prox  # Or bastion-host (VM 110)
```

### 2. kubectl Access
```bash
# From any K3s master node
kubectl get nodes
kubectl get pods -A
```

### 3. EHRbase API URL
Find your current EHRbase REST API endpoint:
- Likely: `http://ehrbase-api-service:8080/ehrbase/rest` (internal)
- Or: `https://ehrbase.mylestechsolutions.com/ehrbase/rest` (external)

### 4. Ingress Controller
Check if ingress controller exists:
```bash
kubectl get svc -A | grep ingress
```

## Deployment Steps

### Step 1: Create Studio Kubernetes Deployment

Save as `ehrbase-studio-deployment.yaml`:

```yaml
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
  labels:
    app: ehrbase-studio
spec:
  replicas: 2  # High availability
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
          name: http
        env:
        - name: EHRBASE_REST_URL
          value: "http://ehrbase-api-service:8080/ehrbase/rest"  # Internal K8s service
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
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8081
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ehrbase-studio-service
  namespace: ehrbase
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
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ehrbase-studio-ingress
  namespace: ehrbase
  annotations:
    kubernetes.io/ingress.class: "traefik"  # Or "nginx" if using nginx-ingress
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # If using cert-manager
spec:
  rules:
  - host: ehrbase.mylestechsolutions.com  # Your domain
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
    - ehrbase.mylestechsolutions.com
    secretName: ehrbase-studio-tls
```

### Step 2: Deploy to Cluster

```bash
# SSH to ehrbase-k3-master-1 (VM 101) via bastion-host
ssh -J user@bastion-host user@ehrbase-k3-master-1

# Deploy Studio
kubectl apply -f ehrbase-studio-deployment.yaml

# Verify deployment
kubectl get pods -n ehrbase
kubectl logs -n ehrbase -l app=ehrbase-studio

# Check service
kubectl get svc -n ehrbase ehrbase-studio-service
```

### Step 3: Configure Ingress/Load Balancer

**If using existing ingress** (likely Traefik or nginx):
```bash
# Check ingress
kubectl get ingress -n ehrbase

# Get ingress IP
kubectl get svc -A | grep LoadBalancer
```

**If no ingress exists**, use NodePort:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ehrbase-studio-nodeport
  namespace: ehrbase
spec:
  type: NodePort
  selector:
    app: ehrbase-studio
  ports:
  - protocol: TCP
    port: 8081
    targetPort: 8081
    nodePort: 30081  # Access via http://any-worker-ip:30081
```

### Step 4: Test Studio Access

**Option A: Via Ingress (Production)**
```bash
# Access: https://ehrbase.mylestechsolutions.com/studio
curl -I https://ehrbase.mylestechsolutions.com/studio
```

**Option B: Via NodePort (Testing)**
```bash
# Access via any worker node IP
curl http://ehrbase-worker-1:30081
curl http://10.x.x.x:30081  # Replace with actual IP
```

**Option C: Port Forward (Local Testing)**
```bash
# From K3s master
kubectl port-forward -n ehrbase svc/ehrbase-studio-service 8081:8081

# Access: http://localhost:8081
```

### Step 5: Configure DNS

Point your domain to ingress load balancer:

**If using pfSense DNS** (you have pfSense MCP server):
```bash
# Create DNS host override:
# Host: ehrbase
# Domain: mylestechsolutions.com
# IP: <ingress-controller-IP>
```

Or use pfSense HAProxy to forward `/studio` path to Studio service.

### Step 6: Upload OpenEHR Templates

**Via Studio UI**:
1. Access `https://ehrbase.mylestechsolutions.com/studio`
2. Login with EHRbase credentials
3. Navigate to Templates section
4. Upload each template:
   - `ehrbase.demographics.v1.opt`
   - `ehrbase.vital_signs.v1.opt`
   - `ehrbase.lab_results.v1.opt`
   - `ehrbase.prescriptions.v1.opt`

**Or via API**:
```bash
# From bastion-host or any node
for template in demographics vital_signs lab_results prescriptions; do
  curl -X POST \
    "https://ehrbase.mylestechsolutions.com/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
    -H "Content-Type: application/xml" \
    -u "ehrbase-system:PASSWORD" \
    --data-binary "@/path/to/templates/ehrbase.${template}.v1.opt"
done
```

## Alternative: Docker Compose Deployment

If K8s is too complex, deploy on single VM using Docker Compose.

### On ehrbase-worker-1 (or dedicated VM):

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  ehrbase-studio:
    image: ehrbase/ehrbase-studio:latest
    container_name: ehrbase-studio
    ports:
      - "8081:8081"
    environment:
      EHRBASE_REST_URL: "https://ehrbase.mylestechsolutions.com/ehrbase/rest"
    restart: unless-stopped
    networks:
      - ehrbase-network

networks:
  ehrbase-network:
    external: true  # Connect to existing EHRbase network
```

**Deploy**:
```bash
# SSH to ehrbase-worker-1
ssh -J user@bastion-host user@ehrbase-worker-1

# Create directory
mkdir -p /opt/ehrbase-studio
cd /opt/ehrbase-studio

# Save docker-compose.yml
vi docker-compose.yml  # Paste content above

# Start Studio
docker-compose up -d

# Check logs
docker-compose logs -f

# Access: http://ehrbase-worker-1:8081
```

## Updating Application Configuration

Once Studio is deployed, update your app to use Proxmox EHRbase:

### 1. Find EHRbase URL

**Internal (K8s)**:
```bash
kubectl get svc -n ehrbase
# Likely: http://ehrbase-api-service.ehrbase.svc.cluster.local:8080/ehrbase/rest
```

**External (Public)**:
```bash
# If exposed via ingress:
https://ehrbase.mylestechsolutions.com/ehrbase/rest
```

### 2. Update Firebase Cloud Functions

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

firebase functions:config:set \
  ehrbase.url="https://ehrbase.mylestechsolutions.com/ehrbase/rest" \
  ehrbase.username="ehrbase-system" \
  ehrbase.password="YOUR_PASSWORD"

firebase deploy --only functions:onUserCreated
```

### 3. Update Supabase Edge Functions

```bash
npx supabase secrets set \
  EHRBASE_URL=https://ehrbase.mylestechsolutions.com/ehrbase/rest \
  EHRBASE_USERNAME=ehrbase-system \
  EHRBASE_PASSWORD=YOUR_PASSWORD

npx supabase functions deploy sync-to-ehrbase
```

### 4. Update OpenEHR MCP Server

Edit `.mcp.json`:
```json
{
  "mcpServers": {
    "openEHR": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "EHRBASE_URL=https://ehrbase.mylestechsolutions.com/ehrbase/rest",
        "-e", "EHRBASE_USERNAME=ehrbase-system",
        "-e", "EHRBASE_PASSWORD=YOUR_PASSWORD",
        "openehr-mcp-server"
      ]
    }
  }
}
```

### 5. Update Database

```sql
UPDATE electronic_health_records
SET ehrbase_url = 'https://ehrbase.mylestechsolutions.com/ehrbase/rest';
```

## Cost Savings

**AWS Option**: ~$260/month
**Proxmox Option**: **$0/month** (uses existing infrastructure)

**Savings**: $260/month = **$3,120/year**

## Resource Usage on Proxmox

**EHRbase Studio** (2 replicas):
- CPU: 2 cores total (2% of available 96 cores)
- Memory: 4GB total (0.8% of available 503GB)
- Storage: ~1GB

**Impact**: Negligible - plenty of capacity remaining

## Monitoring

### Check Studio Health
```bash
kubectl get pods -n ehrbase -l app=ehrbase-studio
kubectl logs -n ehrbase -l app=ehrbase-studio --tail=50
```

### Check EHRbase API
```bash
curl -u ehrbase-system:PASSWORD \
  https://ehrbase.mylestechsolutions.com/ehrbase/rest/status
```

### Check Ingress
```bash
kubectl describe ingress -n ehrbase ehrbase-studio-ingress
```

## Next Steps

1. **SSH to bastion-host**: `ssh user@cloud-bastion` (VM 126)
2. **SSH to K3s master**: `ssh user@ehrbase-k3-master-1`
3. **Check K8s status**: `kubectl get nodes && kubectl get pods -A`
4. **Deploy Studio**: `kubectl apply -f ehrbase-studio-deployment.yaml`
5. **Verify access**: Open `https://ehrbase.mylestechsolutions.com/studio`
6. **Upload templates**: Use Studio UI or API
7. **Update app config**: Run Firebase/Supabase config updates
8. **Test end-to-end**: Create test user, verify EHR creation

## Support

- Proxmox Dashboard: `https://prod-prox:8006`
- K8s Cluster: SSH to `ehrbase-k3-master-1` (VM 101)
- Bastion Access: `cloud-bastion` (VM 126) or `bastion-host` (VM 110)
