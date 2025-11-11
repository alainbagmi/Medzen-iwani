# EHRbase Production Access Setup

## Current Status ✅

**EHRbase API is running and accessible:**
- Internal K8s: `http://ehrbase:8080`
- NodePort: `http://10.10.10.201:30080`
- Swagger UI: `http://10.10.10.201:30080/ehrbase/swagger-ui/index.html`

**LoadBalancer IPs:**
- 10.10.10.201 (primary)
- 10.10.10.202-206 (additional)

## Immediate Access

### 1. Access Swagger UI
```bash
http://10.10.10.201:30080/ehrbase/swagger-ui/index.html
```

### 2. Get Credentials
```bash
# On your local machine
npx supabase secrets list | grep EHRBASE
```

### 3. Test API
```bash
curl -u username:password \
  http://10.10.10.201:30080/ehrbase/rest/openehr/v1/definition/template/adl1.4
```

## Production Setup Options

### Option 1: Cloudflare Tunnel (Recommended - HTTPS + Security)

**Advantages:**
- Automatic HTTPS/SSL
- DDoS protection
- Access control
- Zero exposed ports

**Steps:**
1. Install cloudflared on VM 101 (K3s master):
```bash
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

2. Authenticate:
```bash
cloudflared tunnel login
```

3. Create tunnel:
```bash
cloudflared tunnel create ehrbase
```

4. Configure tunnel (`~/.cloudflared/config.yml`):
```yaml
tunnel: <TUNNEL_ID>
credentials-file: /home/<user>/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: ehrbase.mylestechsolutions.com
    service: http://10.10.10.201:30080
  - service: http_status:404
```

5. Route DNS:
```bash
cloudflared tunnel route dns ehrbase ehrbase.mylestechsolutions.com
```

6. Run tunnel as service:
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
```

**Access:**
```
https://ehrbase.mylestechsolutions.com/ehrbase/swagger-ui/index.html
```

### Option 2: Traefik Ingress (K8s Native - Production Grade)

**Complete setup script saved at:** `proxmox-deployment/scripts/setup-traefik-production.sh`

Run on K3s master (VM 101):
```bash
bash /path/to/setup-traefik-production.sh
```

**What it does:**
- Installs Traefik v2.10 with proper RBAC
- Creates IngressClass
- Configures Ingress for EHRbase
- Sets up LoadBalancer service
- Configures Let's Encrypt for SSL (optional)

**Access:**
```
https://ehrbase.mylestechsolutions.com/ehrbase/swagger-ui/index.html
```

### Option 3: Direct DNS + Nginx Reverse Proxy

**Best for:** Simple setup without K8s complexity

1. Update Cloudflare DNS:
   - Type: A
   - Name: ehrbase
   - Content: 10.10.10.201
   - Proxy: OFF (disable orange cloud)

2. Install nginx on bastion/proxy VM:
```bash
sudo apt install nginx certbot python3-certbot-nginx
```

3. Configure nginx (`/etc/nginx/sites-available/ehrbase`):
```nginx
server {
    server_name ehrbase.mylestechsolutions.com;

    location / {
        proxy_pass http://10.10.10.201:30080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

4. Enable and get SSL:
```bash
sudo ln -s /etc/nginx/sites-available/ehrbase /etc/nginx/sites-enabled/
sudo certbot --nginx -d ehrbase.mylestechsolutions.com
sudo systemctl restart nginx
```

**Access:**
```
https://ehrbase.mylestechsolutions.com/ehrbase/swagger-ui/index.html
```

## Security Recommendations

### 1. Enable Authentication
EHRbase is currently using Basic Auth. For production:

- Configure OAuth2/OIDC via Traefik middleware
- Use Firebase/Supabase JWT tokens
- Implement IP whitelisting

### 2. Network Policies
```bash
# Restrict access to EHRbase pods
kubectl apply -f proxmox-deployment/k8s/network-policy-ehrbase.yaml
```

### 3. Rate Limiting
Add to Traefik middleware or Cloudflare WAF rules.

### 4. Monitoring
```bash
# Check EHRbase health
kubectl get pods -n ehrbase
kubectl logs -n ehrbase -l app=ehrbase --tail=50

# Monitor ingress
kubectl get ingress -n ehrbase
```

## Troubleshooting

### 404 Error on Domain
1. Check DNS propagation: `dig ehrbase.mylestechsolutions.com`
2. Verify LoadBalancer: `kubectl get svc -n kube-system traefik`
3. Check ingress: `kubectl describe ingress -n ehrbase`
4. Review Traefik logs: `kubectl logs -n kube-system -l app=traefik`

### Connection Refused
1. Verify EHRbase pods running: `kubectl get pods -n ehrbase`
2. Check service: `kubectl get svc -n ehrbase ehrbase`
3. Test internal connectivity: `kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://ehrbase:8080/ehrbase/`

### SSL/TLS Issues
1. Check certificates: `kubectl get certificates -A`
2. Verify cert-manager: `kubectl get pods -n cert-manager`
3. Review Let's Encrypt logs

## Next Steps

1. **Choose access method** (Cloudflare Tunnel recommended)
2. **Update DNS** to point to your chosen solution
3. **Test access** via domain
4. **Configure authentication** for production
5. **Set up monitoring** and alerting
6. **Document credentials** in secure vault

## Quick Reference

| Component | Access | Port | Protocol |
|-----------|--------|------|----------|
| Swagger UI | `/ehrbase/swagger-ui/index.html` | 30080 | HTTP |
| REST API | `/ehrbase/rest/openehr/v1/` | 30080 | HTTP |
| Admin API | `/ehrbase/rest/admin/` | 30080 | HTTP |

**Default Credentials Location:**
- Supabase Secrets: `EHRBASE_USERNAME`, `EHRBASE_PASSWORD`
- Firebase Config: `ehrbase.username`, `ehrbase.password`
