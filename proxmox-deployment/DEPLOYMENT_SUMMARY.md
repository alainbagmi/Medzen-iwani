# Proxmox EHRbase Studio Deployment - Summary

## What Has Been Created

I've prepared a complete deployment package for adding EHRbase Studio web interface to your existing Proxmox K3s cluster.

### Directory Structure

```
proxmox-deployment/
├── README.md                           # Complete deployment guide
├── QUICK_START.md                      # Quick start guide (start here!)
├── DEPLOYMENT_SUMMARY.md               # This file
│
├── k8s/                                # Kubernetes deployment files
│   └── ehrbase-studio-deployment.yaml  # Complete K8s manifest
│
├── docker/                             # Docker Compose alternative
│   └── docker-compose.yml              # Standalone Docker deployment
│
├── scripts/                            # Deployment automation scripts
│   ├── deploy-studio-k8s.sh           # K8s deployment script
│   └── deploy-studio-docker.sh        # Docker deployment script
│
└── templates/                          # OpenEHR templates (to be added)
    ├── ehrbase.demographics.v1.opt
    ├── ehrbase.vital_signs.v1.opt
    ├── ehrbase.lab_results.v1.opt
    └── ehrbase.prescriptions.v1.opt
```

## Your Existing Infrastructure

### Proxmox Cluster: `prod-prox`
- **96 CPU cores** (plenty of capacity)
- **503GB RAM** (only 17% used)
- **Status**: Healthy, 21+ days uptime

### Existing EHRbase K3s Cluster
You already have a production-grade EHRbase deployment:

**K3s Masters** (3 nodes):
- ehrbase-k3-master-1 (VM 101)
- ehrbase-k3-master-2 (VM 103)
- ehrbase-k3-master-3 (VM 102)

**K3s Workers** (3 nodes):
- ehrbase-worker-1 (VM 114)
- ehrbase-worker-2 (VM 105)
- ehrbase-worker-3 (VM 107)

This is **perfect** for deploying EHRbase Studio!

## What EHRbase Studio Provides

### Web-Based Admin Dashboard
Access at: `https://ehr.medzenhealth.app/studio`

**Features**:
1. **EHR Browser** - View all patient electronic health records
2. **Composition Inspector** - See detailed medical data (vital signs, prescriptions, etc.)
3. **Template Manager** - View/upload/validate OpenEHR templates
4. **AQL Query Builder** - Search patient data with visual interface
5. **Standards Validator** - Check OpenEHR compliance
6. **System Monitor** - View sync status and health metrics

### Use Cases
- **System Admins**: Monitor EHR creation, view sync status
- **Compliance Officers**: Validate OpenEHR standards compliance
- **Developers**: Test queries, inspect data structures
- **Troubleshooting**: Debug sync issues, verify data

## Deployment Options

### ⭐ Recommended: K3s Deployment
Deploy Studio as K8s deployment to your existing cluster.

**Pros**:
- Uses existing infrastructure (no new VMs)
- High availability (2 replicas)
- Zero additional cost
- Auto-healing and load balancing
- Easy updates

**Resource Usage**:
- CPU: 2 cores total (2% of available 96 cores)
- Memory: 4GB total (0.8% of available 503GB)
- Impact: Negligible

### Alternative: Docker Deployment
Deploy Studio as standalone Docker container on single worker node.

**Pros**:
- Simpler than K8s
- Good for testing
- Isolated from cluster

## Next Steps

### Step 1: Access Your K3s Cluster

```bash
# SSH to bastion host
ssh user@cloud-bastion  # VM 126

# SSH to K3s master
ssh user@ehrbase-k3-master-1  # VM 101

# Verify K8s access
kubectl get nodes
```

### Step 2: Deploy EHRbase Studio

**Option A: Automated (Recommended)**
```bash
# Copy deployment files to K3s master
# Then run:
cd ~/ehrbase-studio-deployment
./deploy-studio-k8s.sh
```

**Option B: Manual**
```bash
# Copy or create YAML manifest
kubectl apply -f ehrbase-studio-deployment.yaml

# Watch deployment
kubectl get pods -n ehrbase -w
```

### Step 3: Verify Deployment
```bash
# Check pods are running
kubectl get pods -n ehrbase -l app=ehrbase-studio

# View logs
kubectl logs -n ehrbase -l app=ehrbase-studio
```

### Step 4: Access Studio

**Testing (Port Forward)**:
```bash
kubectl port-forward -n ehrbase svc/ehrbase-studio-service 8081:8081
```

**Production (Ingress)**:
- URL: `https://ehr.medzenhealth.app/studio`
- Configure ingress or pfSense reverse proxy

### Step 5: Upload OpenEHR Templates

Via Studio UI:
1. Login to Studio
2. Go to "Templates" section
3. Upload 4 template files (.opt format)

### Step 6: Update App Configuration

Update these 4 integration points to use Proxmox EHRbase:

1. **Firebase Functions**:
   ```bash
   firebase functions:config:set \
     ehrbase.url="https://ehr.medzenhealth.app/ehrbase/rest"
   firebase deploy --only functions:onUserCreated
   ```

2. **Supabase Edge Functions**:
   ```bash
   npx supabase secrets set \
     EHRBASE_URL=https://ehr.medzenhealth.app/ehrbase/rest
   npx supabase functions deploy sync-to-ehrbase
   ```

3. **OpenEHR MCP Server**: Edit `.mcp.json` environment variables

4. **Database**: Update `electronic_health_records.ehrbase_url` column

### Step 7: Test End-to-End

1. Create test user in app
2. Verify EHR appears in Studio
3. Create vital signs record
4. Verify composition in Studio
5. Test offline sync

## Cost Comparison

| Deployment | Monthly Cost | Annual Cost |
|------------|--------------|-------------|
| **AWS ECS + RDS** | $260 | $3,120 |
| **Proxmox (Your Infrastructure)** | **$0** | **$0** |
| **Savings** | **$260** | **$3,120** |

## What This Gives You vs External EHRbase

### Current External EHRbase (`ehr.medzenhealth.app`)
❌ No web interface (returns 404)
❌ Only API access
❌ Vendor dependency
❌ No visibility into data
❌ Limited control

### Your Proxmox EHRbase + Studio
✅ Full web admin dashboard
✅ Complete data visibility
✅ No vendor lock-in
✅ Zero additional cost
✅ Full control
✅ On-premise security
✅ HIPAA-compliant infrastructure

## Technical Details

### Studio Container
- **Image**: `ehrbase/ehrbase-studio:latest` (official)
- **Port**: 8081 (HTTP)
- **Environment**: Connects to your EHRbase API
- **Replicas**: 2 (high availability)
- **Health Checks**: Built-in liveness/readiness probes

### Integration
Studio connects to your EHRbase REST API:
- Internal K8s: `http://ehrbase-api-service:8080/ehrbase/rest`
- External: `https://ehr.medzenhealth.app/ehrbase/rest`

### Security
- Requires EHRbase credentials (Basic Auth)
- HTTPS via ingress/reverse proxy
- K8s network policies (optional)
- No direct database access

## Support & Documentation

### Files Created
- `README.md` - Complete deployment guide
- `QUICK_START.md` - Quick start (recommended reading)
- `k8s/ehrbase-studio-deployment.yaml` - K8s manifest
- `docker/docker-compose.yml` - Docker Compose file
- `scripts/deploy-studio-k8s.sh` - Automated K8s deployment
- `scripts/deploy-studio-docker.sh` - Automated Docker deployment

### References
- EHRbase Docs: https://ehrbase.readthedocs.io/
- EHRbase Studio: https://github.com/ehrbase/ehrbase-studio
- OpenEHR Specification: https://specifications.openehr.org/

### Your Infrastructure
- **Proxmox**: `https://prod-prox:8006`
- **Bastion**: `cloud-bastion` (VM 126) or `bastion-host` (VM 110)
- **K3s Masters**: VMs 101, 102, 103
- **K3s Workers**: VMs 105, 107, 114

## Timeline

**Deployment**: 30-60 minutes
- Step 1 (Access K8s): 5 minutes
- Step 2 (Deploy Studio): 5 minutes
- Step 3 (Verify): 5 minutes
- Step 4 (Configure Access): 15 minutes
- Step 5 (Upload Templates): 10 minutes
- Step 6 (Update Configs): 10 minutes
- Step 7 (Testing): 10 minutes

**Total**: ~1 hour to go live with EHRbase Studio!

## Questions?

**Deployment Issues**: Check `kubectl logs -n ehrbase -l app=ehrbase-studio`
**Access Issues**: Verify ingress/NodePort configuration
**EHRbase Connection**: Check `EHRBASE_REST_URL` environment variable
**Template Upload**: Use Studio UI or API (both methods documented)

## Ready to Deploy?

Start with: `proxmox-deployment/QUICK_START.md`

Or jump directly to deployment:
```bash
# SSH to K3s master
ssh -J user@cloud-bastion user@ehrbase-k3-master-1

# Deploy
kubectl apply -f ehrbase-studio-deployment.yaml
```

Good luck! 🚀
