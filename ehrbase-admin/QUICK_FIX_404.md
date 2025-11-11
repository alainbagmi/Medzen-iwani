# Quick Fix for 404 Error

If you're seeing "HTTP Status 404 – Not Found", the dashboard hasn't been deployed yet or the pods aren't running.

## Option 1: Quick Deploy (Recommended)

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin
./deploy.sh
```

This will automatically deploy the dashboard and show you the access URLs.

## Option 2: Manual Deploy

```bash
kubectl apply -f /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin/kubernetes/complete-deployment.yaml
```

Wait for pods to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=ehrbase-admin-ui -n ehrbase --timeout=120s
```

## Option 3: Check What's Wrong

Run the troubleshooting script:
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-admin
./troubleshoot.sh
```

This will check:
- ✓ Namespace exists
- ✓ ConfigMap exists
- ✓ Deployment exists
- ✓ Pods are running
- ✓ Service is configured
- ✓ Endpoints are available

## After Deployment

Access the dashboard at:
- http://10.10.10.101:30090
- http://10.10.10.102:30090
- http://10.10.10.103:30090
- http://10.10.10.104:30090
- http://10.10.10.105:30090
- http://10.10.10.106:30090

## Still Getting 404?

1. **Check if deployment was applied:**
   ```bash
   kubectl get deployment ehrbase-admin-ui -n ehrbase
   ```

2. **Check if pods are running:**
   ```bash
   kubectl get pods -n ehrbase -l app=ehrbase-admin-ui
   ```

   You should see 2 pods with status "Running" and ready count "1/1".

3. **Check service:**
   ```bash
   kubectl get svc ehrbase-admin-ui -n ehrbase
   ```

   You should see NodePort 30090.

4. **Check pod logs for errors:**
   ```bash
   kubectl logs -n ehrbase -l app=ehrbase-admin-ui
   ```

5. **Verify you're using the correct URL:**
   - ✅ http://10.10.10.101:30090 (correct)
   - ❌ http://10.10.10.101:30090/ehrbase (wrong - no path needed)
   - ❌ https://10.10.10.101:30090 (wrong - use http not https)

## Common Causes of 404

1. **Deployment not applied** - Run `./deploy.sh`
2. **Pods not ready** - Wait for pods to start (can take 30-60 seconds)
3. **Wrong URL** - Use http://<node-ip>:30090 (no /ehrbase path)
4. **Service not created** - Check with `kubectl get svc -n ehrbase`
5. **ConfigMap missing** - Check with `kubectl get cm -n ehrbase ehrbase-admin-html`

## Quick Test

```bash
# This should show the dashboard HTML
kubectl exec -n ehrbase deployment/ehrbase-admin-ui -- cat /usr/share/nginx/html/index.html | head -20
```

If you see HTML output, the deployment is working and it's likely a networking/URL issue.
