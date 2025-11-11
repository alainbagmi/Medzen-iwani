# Copy-Paste Deployment Instructions

Since Proxmox MCP cannot execute commands (QEMU guest agent not configured), here's a simple copy-paste deployment method.

## Step 1: SSH to K3s Master

```bash
ssh user@ehrbase-k3-master-1
# Or via bastion: ssh -J user@bastion-host user@ehrbase-k3-master-1
```

## Step 2: Verify K8s Access

```bash
kubectl get nodes
```

You should see 6 nodes (3 masters + 3 workers).

## Step 3: Deploy EHRbase Studio

Copy and paste this entire block into your terminal:

```bash
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

kubectl apply -f /tmp/ehrbase-studio.yaml
```

## Step 4: Wait for Deployment

```bash
kubectl get pods -n ehrbase -w
```

Wait until you see:
```
NAME                              READY   STATUS    RESTARTS   AGE
ehrbase-studio-xxxxxxxxx-xxxxx    1/1     Running   0          1m
ehrbase-studio-xxxxxxxxx-xxxxx    1/1     Running   0          1m
```

Press `Ctrl+C` to exit watch mode.

## Step 5: Get Access URL

```bash
echo "Studio URL: http://$(hostname -I | awk '{print $1}'):30081"
```

Copy this URL and open it in your browser.

## Step 6: Verify Deployment

```bash
# Check pods
kubectl get pods -n ehrbase

# Check logs
kubectl logs -n ehrbase -l app=ehrbase-studio --tail=50

# Check service
kubectl get svc -n ehrbase
```

## Alternative: One-Line Deployment

If the above doesn't work, try this single command:

```bash
kubectl create namespace ehrbase 2>/dev/null || true && \
kubectl create deployment ehrbase-studio --image=ehrbase/ehrbase-studio:latest --replicas=2 -n ehrbase && \
kubectl set env deployment/ehrbase-studio -n ehrbase EHRBASE_REST_URL=http://ehrbase-api-service:8080/ehrbase/rest && \
kubectl expose deployment ehrbase-studio --type=NodePort --port=8081 --target-port=8081 --name=ehrbase-studio-service -n ehrbase && \
kubectl patch service ehrbase-studio-service -n ehrbase -p '{"spec":{"ports":[{"port":8081,"targetPort":8081,"nodePort":30081}]}}'
```

## Access Studio

Once deployed, access Studio at:
- **NodePort**: `http://ANY_WORKER_IP:30081`
- **Port Forward**: `kubectl port-forward -n ehrbase svc/ehrbase-studio-service 8081:8081`

## Troubleshooting

### Pods not starting?
```bash
kubectl describe pod -n ehrbase -l app=ehrbase-studio
kubectl logs -n ehrbase -l app=ehrbase-studio
```

### Can't access Studio?
```bash
# Check if service exists
kubectl get svc -n ehrbase ehrbase-studio-service

# Check if pods are ready
kubectl get pods -n ehrbase -l app=ehrbase-studio

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://ehrbase-studio-service.ehrbase:8081
```

### Wrong EHRbase URL?
```bash
# Update environment variable
kubectl set env deployment/ehrbase-studio -n ehrbase \
  EHRBASE_REST_URL=https://ehr.medzenhealth.app/ehrbase/rest

# Or use external URL
kubectl set env deployment/ehrbase-studio -n ehrbase \
  EHRBASE_REST_URL=http://ehrbase-api-service.ehrbase.svc.cluster.local:8080/ehrbase/rest
```

## Next Steps After Deployment

1. ✅ Access Studio in browser
2. ✅ Login with EHRbase credentials
3. ✅ Upload 4 OpenEHR templates
4. ✅ Test browsing EHRs
5. ✅ Update app configuration to use Proxmox EHRbase

## Need to Remove/Restart?

```bash
# Delete deployment
kubectl delete -f /tmp/ehrbase-studio.yaml

# Or delete namespace (removes everything)
kubectl delete namespace ehrbase

# Restart pods
kubectl rollout restart deployment/ehrbase-studio -n ehrbase
```

## Enable QEMU Guest Agent (For Future MCP Access)

To enable Proxmox MCP commands in the future:

```bash
# SSH to each VM and run:
sudo apt-get update
sudo apt-get install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

After this, you'll be able to use Proxmox MCP to execute commands remotely.
