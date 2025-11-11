# PowerSync Secrets Configuration

**Status**: ⚠️ Pending Configuration
**Date**: 2025-10-31
**Instance URL**: `https://68f931403c148720fa432934.powersync.journeyapps.com`
**Instance ID**: `68f931403c148720fa432934`
**Region**: US

## Quick Steps (5 minutes)

### Step 1: Generate RSA Key Pair in PowerSync Dashboard

1. Open PowerSync dashboard:
   ```bash
   open https://68f931403c148720fa432934.powersync.journeyapps.com
   ```

2. Navigate to: **Settings → Security → API Keys**

3. Click: **Generate RSA Key Pair**

4. You'll see two values generated:
   - **Key ID** (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
   - **Private Key** (starts with `-----BEGIN RSA PRIVATE KEY-----`)

5. **Copy both values** - you'll need them in the next step

   **Important**: Keep the private key secure! Don't share it or commit it to version control.

### Step 2: Set Supabase Secrets

Run these commands in your terminal:

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Set PowerSync instance URL
npx supabase secrets set POWERSYNC_URL="https://68f931403c148720fa432934.powersync.journeyapps.com"

# Set Key ID (replace with your actual Key ID from Step 1)
npx supabase secrets set POWERSYNC_KEY_ID="<paste-your-key-id-here>"

# Set Private Key (replace with your actual Private Key from Step 1)
# IMPORTANT: Paste the ENTIRE key including the headers
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
<paste-your-private-key-content-here>
-----END RSA PRIVATE KEY-----"
```

**Example** (with placeholder values):
```bash
npx supabase secrets set POWERSYNC_URL="https://68f931403c148720fa432934.powersync.journeyapps.com"

npx supabase secrets set POWERSYNC_KEY_ID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"

npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN
OPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/ABCDEFGHIJKLMNOPQRSc3YMXU3MTJ1SWphS
... (multiple lines of base64 encoded key) ...
-----END RSA PRIVATE KEY-----"
```

### Step 3: Redeploy PowerSync Token Function

```bash
# Redeploy the edge function with new secrets
npx supabase functions deploy powersync-token

# Expected output:
# Deploying function powersync-token...
# Deployed function powersync-token in XX.XXs
```

### Step 4: Verify Configuration

```bash
# List all secrets to confirm they're set
npx supabase secrets list

# You should see:
# POWERSYNC_URL
# POWERSYNC_KEY_ID
# POWERSYNC_PRIVATE_KEY
```

## Testing Token Generation

After configuring the secrets, test the token function:

### Option 1: Via Supabase CLI

```bash
# Test with authenticated user
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer $(npx supabase functions get-jwt)"

# Expected successful response:
# {
#   "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjxrZXktaWQ+In0...",
#   "powersync_url": "https://68f931403c148720fa432934.powersync.journeyapps.com",
#   "expires_at": "2025-10-31T22:30:00.000Z",
#   "user_id": "uuid-of-user"
# }
```

### Option 2: Via Function Logs

```bash
# Monitor logs in real-time
npx supabase functions logs powersync-token --tail

# In another terminal, trigger the function (login to your app)
# Then check logs for success/error messages
```

## Troubleshooting

### Error: "PowerSync not configured"

**Cause**: Missing secrets (POWERSYNC_KEY_ID or POWERSYNC_PRIVATE_KEY)

**Fix**:
1. Verify secrets are set: `npx supabase secrets list`
2. If missing, run the commands in Step 2 again
3. Redeploy: `npx supabase functions deploy powersync-token`

### Error: "Invalid key format"

**Cause**: Private key not formatted correctly

**Fix**:
1. Ensure private key includes headers:
   - Starts with: `-----BEGIN RSA PRIVATE KEY-----`
   - Ends with: `-----END RSA PRIVATE KEY-----`
2. No extra spaces or newlines before/after headers
3. Use double quotes when setting the secret
4. Redeploy after fixing

### Error: "Key ID mismatch"

**Cause**: Key ID doesn't match the private key

**Fix**:
1. Delete old key pair from PowerSync dashboard
2. Generate new key pair
3. Copy both Key ID and Private Key from the same generation
4. Set both secrets again
5. Redeploy

## Security Best Practices

### Private Key Storage

- ✅ **DO**: Store in Supabase secrets (encrypted at rest)
- ✅ **DO**: Keep a secure backup (password manager, encrypted vault)
- ❌ **DON'T**: Commit to git
- ❌ **DON'T**: Share via email/Slack/Discord
- ❌ **DON'T**: Store in code files or environment variables in the codebase

### Key Rotation

Rotate your PowerSync keys every 90 days:

1. Generate new key pair in PowerSync dashboard
2. Update Supabase secrets with new values
3. Redeploy edge function
4. Delete old key pair from PowerSync dashboard

### Monitoring

Monitor token generation for anomalies:

```bash
# Check token function logs daily
npx supabase functions logs powersync-token --limit 100

# Look for:
# - Unusual number of requests
# - Failed authentication attempts
# - Error patterns
```

## Current Status

- [ ] RSA key pair generated in PowerSync dashboard
- [ ] `POWERSYNC_URL` secret set in Supabase
- [ ] `POWERSYNC_KEY_ID` secret set in Supabase
- [ ] `POWERSYNC_PRIVATE_KEY` secret set in Supabase
- [ ] `powersync-token` function redeployed
- [ ] Token generation tested successfully

## Next Steps

After secrets are configured and tested:

1. ✅ Configure PowerSync library in FlutterFlow (paste schema from `powersync_flutterflow_schema.dart`)
2. ✅ Add `initializePowerSync()` to landing pages
3. ✅ Test offline functionality
4. ✅ Verify role-based sync

See `FLUTTERFLOW_POWERSYNC_INTEGRATION_GUIDE.md` for complete integration steps.
