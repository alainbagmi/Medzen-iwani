# Fix 404 Error with Cloudflare Tunnel

## Quick Fix (5 minutes)

SSH into your K3s master node and run:

```bash
# Copy script to VM
scp proxmox-deployment/scripts/setup-cloudflare-tunnel.sh root@10.10.10.201:/tmp/

# SSH to VM 101
ssh root@10.10.10.201

# Run setup script
sudo bash /tmp/setup-cloudflare-tunnel.sh
```

The script will:
1. ✅ Install cloudflared
2. ✅ Prompt you to login to Cloudflare (browser will open)
3. ✅ Create tunnel for ehrbase
4. ✅ Route ehr.medzenhealth.app → http://10.10.10.201:30080
5. ✅ Install as systemd service

**After completion:**
```
https://ehr.medzenhealth.app/ehrbase/swagger-ui/index.html
```

## Manual Setup (If Script Fails)

### Step 1: Install cloudflared

```bash
# On VM 101
curl -L --output cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

sudo dpkg -i cloudflared.deb
```

### Step 2: Authenticate

```bash
cloudflared tunnel login
```

This opens a browser. Login to Cloudflare and authorize the tunnel.

### Step 3: Create Tunnel

```bash
cloudflared tunnel create ehrbase-tunnel
```

Note the tunnel ID shown in the output.

### Step 4: Configure Tunnel

Create `/root/.cloudflared/config.yml`:

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /root/.cloudflared/<YOUR_TUNNEL_ID>.json

ingress:
  - hostname: ehr.medzenhealth.app
    service: http://10.10.10.201:30080
    originRequest:
      noTLSVerify: true
  - service: http_status:404
```

### Step 5: Route DNS

```bash
cloudflared tunnel route dns ehrbase-tunnel ehr.medzenhealth.app
```

### Step 6: Run Tunnel

**Option A: As Service (Recommended)**
```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

**Option B: Foreground (Testing)**
```bash
cloudflared tunnel run ehrbase-tunnel
```

### Step 7: Verify

```bash
# Check tunnel status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f

# Test access
curl https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4
```

## Alternative: Quick Tunnel (No Auth Required)

For quick testing without authentication:

```bash
# On VM 101, run:
cloudflared tunnel --url http://10.10.10.201:30080
```

This will give you a temporary URL like:
```
https://random-words-1234.trycloudflare.com
```

You can access EHRbase at:
```
https://random-words-1234.trycloudflare.com/ehrbase/swagger-ui/index.html
```

**Note:** This URL is temporary and changes each time you restart cloudflared.

## Troubleshooting

### Tunnel not connecting
```bash
# Check logs
journalctl -u cloudflared -f

# Common issues:
# 1. Wrong service URL
# 2. Firewall blocking
# 3. EHRbase not running
```

### DNS not resolving
```bash
# Check DNS propagation
dig ehr.medzenhealth.app

# Should show Cloudflare IPs (like 104.x.x.x or 172.x.x.x)
```

### Still getting 404
```bash
# Verify EHRbase is running
kubectl get pods -n ehrbase

# Test internal access
curl http://10.10.10.201:30080/ehrbase/rest/openehr/v1/definition/template/adl1.4

# If this works but domain doesn't, restart tunnel:
sudo systemctl restart cloudflared
```

### Check Cloudflare Dashboard

1. Go to https://one.dash.cloudflare.com
2. Select your account
3. Go to **Zero Trust** → **Networks** → **Tunnels**
4. Find `ehrbase-tunnel`
5. Check status (should be "Healthy")
6. View traffic logs

## Benefits of Cloudflare Tunnel

✅ **Automatic HTTPS** - No SSL certificate management
✅ **DDoS Protection** - Cloudflare's network protects your origin
✅ **No Port Forwarding** - Works behind NAT/firewall
✅ **Access Control** - Add Cloudflare Access for auth
✅ **Zero Trust Security** - Origin server never exposed to internet
✅ **Performance** - Cloudflare's global CDN

## Next Steps

After tunnel is working:

1. **Add Access Control** (Optional)
   - Go to Cloudflare Dashboard → Zero Trust → Access
   - Create application for ehr.medzenhealth.app
   - Add authentication (Google, GitHub, email OTP, etc.)

2. **Monitor Traffic**
   - Cloudflare Analytics shows requests, bandwidth, threats
   - Set up alerts for errors or high traffic

3. **Configure WAF Rules**
   - Add rate limiting
   - Block suspicious requests
   - Geo-blocking if needed

## Quick Commands

```bash
# Start tunnel
sudo systemctl start cloudflared

# Stop tunnel
sudo systemctl stop cloudflared

# Restart tunnel
sudo systemctl restart cloudflared

# View logs
sudo journalctl -u cloudflared -f

# Check status
sudo systemctl status cloudflared

# List tunnels
cloudflared tunnel list

# Delete tunnel (if needed)
cloudflared tunnel delete ehrbase-tunnel
```

## Support

If issues persist:
1. Check Cloudflare status: https://www.cloudflarestatus.com/
2. View tunnel logs: `journalctl -u cloudflared -f`
3. Test EHRbase directly: `curl http://10.10.10.201:30080/ehrbase/`
4. Check Cloudflare dashboard for tunnel health
