# EHRbase Studio Proxmox Deployment - Quick Start

## Decision: Deploy on Existing K3s Cluster vs Single VM

### Option 1: K3s Cluster (RECOMMENDED) ⭐
**Best for**: Production use, high availability, easy updates

```bash
# SSH to K3s master node via bastion
ssh -J user@cloud-bastion user@ehrbase-k3-master-1

# Clone or copy deployment files to master node
# Then run:
cd proxmox-deployment/scripts
./deploy-studio-k8s.sh
```

**Benefits**:
- ✅ Zero cost (uses existing infrastructure)
- ✅ High availability (2 replicas across workers)
- ✅ Auto-healing (K8s restarts failed pods)
- ✅ Easy updates (`kubectl apply -f`)
- ✅ Load balanced automatically

### Option 2: Single VM with Docker
**Best for**: Quick testing, simpler setup

```bash
# SSH to any worker node
ssh -J user@cloud-bastion user@ehrbase-worker-1

# Run deployment
cd proxmox-deployment/scripts
./deploy-studio-docker.sh
```

## Recommended: K3s Deployment

### Step 1: Access K3s Master Node
```bash
# Via bastion host
ssh user@cloud-bastion  # VM 126
ssh user@ehrbase-k3-master-1  # VM 101
```

### Step 2: Copy Deployment Files
```bash
# On K3s master, create directory
mkdir -p ~/ehrbase-studio-deployment
cd ~/ehrbase-studio-deployment

# Copy from local machine (from your Mac)
scp -J user@cloud-bastion \
  proxmox-deployment/k8s/ehrbase-studio-deployment.yaml \
  user@ehrbase-k3-master-1:~/ehrbase-studio-deployment/

# Or create file manually (copy/paste content)
vi ehrbase-studio-deployment.yaml
```

### Step 3: Verify K8s Cluster
```bash
kubectl get nodes
# Expected: 3 master nodes + 3 worker nodes

kubectl get pods -A
# Check if EHRbase API is running
```

### Step 4: Deploy Studio
```bash
kubectl apply -f ehrbase-studio-deployment.yaml

# Watch deployment progress
kubectl get pods -n ehrbase -w
```

### Step 5: Verify Deployment
```bash
# Check pods are running
kubectl get pods -n ehrbase -l app=ehrbase-studio

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# ehrbase-studio-xxxxxxxxx-xxxxx    1/1     Running   0          1m
# ehrbase-studio-xxxxxxxxx-xxxxx    1/1     Running   0          1m

# Check logs
kubectl logs -n ehrbase -l app=ehrbase-studio --tail=50
```

### Step 6: Access Studio

**Option A: Via Port Forward (Testing)**
```bash
# On K3s master
kubectl port-forward -n ehrbase svc/ehrbase-studio-service 8081:8081

# Access from your local machine (setup SSH tunnel first)
ssh -L 8081:localhost:8081 -J user@cloud-bastion user@ehrbase-k3-master-1

# Then open: http://localhost:8081
```

**Option B: Via NodePort (Direct Access)**
```bash
# Get NodePort
kubectl get svc -n ehrbase ehrbase-studio-service

# Access via any worker node IP
http://ehrbase-worker-1:30081  # Replace 30081 with actual NodePort
```

**Option C: Via Ingress (Production)**
```bash
# Check ingress
kubectl get ingress -n ehrbase

# Access via domain
https://ehr.medzenhealth.app/studio
```

## Configure Ingress (Production Access)

### If Using Traefik (K3s default)
The deployment manifest already includes Traefik annotations.

```bash
# Verify Traefik is running
kubectl get pods -A | grep traefik

# Check ingress status
kubectl describe ingress -n ehrbase ehrbase-studio-ingress
```

### If Using pfSense Reverse Proxy
Configure HAProxy or nginx on pfSense to forward:
- `https://ehr.medzenhealth.app/studio` → `http://K3S_WORKER_IP:30081`

## Update EHRbase URL (if needed)

If your EHRbase API is not at `http://ehrbase-api-service:8080/ehrbase/rest`:

```bash
# Edit deployment
kubectl edit deployment -n ehrbase ehrbase-studio

# Change EHRBASE_REST_URL environment variable
# Save and exit - pods will restart automatically
```

Or update the YAML file and reapply:
```bash
vi ehrbase-studio-deployment.yaml
# Change EHRBASE_REST_URL value
kubectl apply -f ehrbase-studio-deployment.yaml
```

## Upload OpenEHR Templates

### Via Studio UI (Easiest)
1. Access Studio: `https://ehr.medzenhealth.app/studio`
2. Login with EHRbase credentials
3. Go to "Templates" section
4. Click "Upload Template"
5. Upload each .opt file:
   - `ehrbase.demographics.v1.opt`
   - `ehrbase.vital_signs.v1.opt`
   - `ehrbase.lab_results.v1.opt`
   - `ehrbase.prescriptions.v1.opt`

### Via API (Automated)
```bash
# From bastion or K3s master
for template in demographics vital_signs lab_results prescriptions; do
  curl -X POST \
    "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
    -H "Content-Type: application/xml" \
    -u "ehrbase-system:PASSWORD" \
    --data-binary "@templates/ehrbase.${template}.v1.opt"
done
```

## Update App Configuration

Once Studio is deployed and templates are uploaded, update your Flutter app to use Proxmox EHRbase.

### 1. Update Firebase Cloud Functions
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

firebase functions:config:set \
  ehrbase.url="https://ehr.medzenhealth.app/ehrbase/rest" \
  ehrbase.username="ehrbase-system" \
  ehrbase.password="YOUR_PASSWORD"

firebase deploy --only functions:onUserCreated
```

### 2. Update Supabase Edge Functions
```bash
npx supabase secrets set \
  EHRBASE_URL=https://ehr.medzenhealth.app/ehrbase/rest \
  EHRBASE_USERNAME=ehrbase-system \
  EHRBASE_PASSWORD=YOUR_PASSWORD

npx supabase functions deploy sync-to-ehrbase
```

### 3. Update OpenEHR MCP Server
Edit `.mcp.json`:
```json
{
  "mcpServers": {
    "openEHR": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "EHRBASE_URL=https://ehr.medzenhealth.app/ehrbase/rest",
        "-e", "EHRBASE_USERNAME=ehrbase-system",
        "-e", "EHRBASE_PASSWORD=YOUR_PASSWORD",
        "openehr-mcp-server"
      ]
    }
  }
}
```

### 4. Update Database
```sql
-- Via Supabase Studio or psql
UPDATE electronic_health_records
SET ehrbase_url = 'https://ehr.medzenhealth.app/ehrbase/rest';
```

## Monitoring & Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n ehrbase -l app=ehrbase-studio
kubectl describe pod -n ehrbase <pod-name>
```

### View Logs
```bash
# Real-time logs
kubectl logs -n ehrbase -l app=ehrbase-studio -f

# Last 100 lines
kubectl logs -n ehrbase -l app=ehrbase-studio --tail=100
```

### Restart Deployment
```bash
kubectl rollout restart deployment/ehrbase-studio -n ehrbase
```

### Scale Up/Down
```bash
# Scale to 3 replicas
kubectl scale deployment ehrbase-studio -n ehrbase --replicas=3

# Scale to 1 replica (save resources)
kubectl scale deployment ehrbase-studio -n ehrbase --replicas=1
```

### Delete Deployment
```bash
kubectl delete -f ehrbase-studio-deployment.yaml
```

## Testing End-to-End

### Test 1: Studio Access
```bash
curl -I https://ehr.medzenhealth.app/studio
# Expected: 200 OK or 302 redirect
```

### Test 2: EHRbase API
```bash
curl -u ehrbase-system:PASSWORD \
  https://ehr.medzenhealth.app/ehrbase/rest/status
# Expected: {"status":"OK"}
```

### Test 3: Create Test EHR
Use Studio UI or MCP server to create test EHR and verify it appears in Studio.

### Test 4: App Integration
Create new user in your Flutter app and verify:
- EHR created in Studio
- Demographics synced
- Vital signs create compositions

## Cost Savings

**AWS Deployment**: ~$260/month
**Proxmox Deployment**: **$0/month** (existing infrastructure)

**Annual Savings**: $3,120/year 💰

## Support

**Deployment Location**: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/proxmox-deployment/`
**K8s Manifests**: `k8s/ehrbase-studio-deployment.yaml`
**Docker Compose**: `docker/docker-compose.yml`
**Scripts**: `scripts/deploy-studio-k8s.sh` and `scripts/deploy-studio-docker.sh`

**Proxmox Access**:
- Cluster: `dr-cluster`
- Main Node: `prod-prox` (96 CPU, 503GB RAM)
- Bastion: `cloud-bastion` (VM 126) or `bastion-host` (VM 110)
- K3s Masters: VMs 101, 102, 103
- K3s Workers: VMs 105, 107, 114
