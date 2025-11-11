# Get PowerSync RSA Keys for FlutterFlow Offline Functionality

**Status**: Action Required
**Date**: 2025-10-31
**PowerSync Instance**: `https://68f931403c148720fa432934.powersync.journeyapps.com`

## Background

Your Supabase ↔ PowerSync sync is already working, which means you already have RSA keys configured in your PowerSync dashboard. We now need to copy those same keys to Supabase secrets so the `powersync-token` edge function can generate JWT tokens for FlutterFlow offline functionality.

## Step 1: Get RSA Keys from PowerSync Dashboard

1. **Open PowerSync Dashboard**:
   ```bash
   open https://68f931403c148720fa432934.powersync.journeyapps.com
   ```

2. **Navigate to Security Settings**:
   - Click **Settings** (gear icon)
   - Click **Security** tab
   - Click **API Keys** section

3. **Copy Your Existing RSA Key Pair**:

   You should see an existing RSA key pair (since Supabase sync is working). Look for:

   - **Key ID**: A UUID like `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
   - **Private Key**: Starts with `-----BEGIN RSA PRIVATE KEY-----`

   **If you see existing keys**:
   - Copy the **Key ID** (you'll need this)
   - Click **View Private Key** or **Download Private Key**
   - Copy the entire private key (including the BEGIN/END headers)

   **If you don't see existing keys** (unlikely since sync is working):
   - Click **Generate RSA Key Pair**
   - Copy both the **Key ID** and **Private Key** that are generated
   - Save them securely (you can't retrieve the private key later)

## Step 2: Set RSA Keys in Supabase Secrets

Once you have the Key ID and Private Key, run these commands:

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Set Key ID (replace with your actual Key ID)
npx supabase secrets set POWERSYNC_KEY_ID="<paste-your-key-id-here>"

# Set Private Key (replace with your actual Private Key)
# IMPORTANT: Include the entire key including BEGIN/END headers
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
<paste-your-private-key-content-here>
-----END RSA PRIVATE KEY-----"
```

**Example**:
```bash
npx supabase secrets set POWERSYNC_KEY_ID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"

npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN
OPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/ABCDEFGHIJKLMNOPQRSc3YMXU3MTJ1SWphS
... (multiple lines of base64 encoded key) ...
-----END RSA PRIVATE KEY-----"
```

## Step 3: Redeploy Edge Function

```bash
# Redeploy the powersync-token function with new secrets
npx supabase functions deploy powersync-token

# Expected output:
# Deploying function powersync-token...
# Deployed function powersync-token in XX.XXs
```

## Step 4: Verify Token Function Works

```bash
# Test token generation
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer $(npx supabase functions get-jwt)"

# Expected successful response:
# {
#   "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "powersync_url": "https://68f931403c148720fa432934.powersync.journeyapps.com",
#   "expires_at": "2025-10-31T22:30:00.000Z",
#   "user_id": "uuid-of-user"
# }
```

## Current Status

- ✅ POWERSYNC_URL configured: `https://68f931403c148720fa432934.powersync.journeyapps.com`
- ❌ POWERSYNC_KEY_ID: **PENDING** (copy from dashboard)
- ❌ POWERSYNC_PRIVATE_KEY: **PENDING** (copy from dashboard)

## Why These Keys Are Needed

The `powersync-token` edge function needs to sign JWT tokens using RSA keys so that:
1. FlutterFlow app can request a PowerSync token when user logs in
2. Token is signed with your private key
3. PowerSync cloud verifies the token using the public key (already in PowerSync dashboard)
4. PowerSync grants access to user's data bucket
5. Offline sync works in FlutterFlow app

**Without these keys**: FlutterFlow app can't get PowerSync tokens → no offline functionality

## Next Steps After Configuration

Once you've set the RSA keys and tested the token function:

1. ✅ Configure PowerSync library in FlutterFlow (see FLUTTERFLOW_POWERSYNC_INTEGRATION_GUIDE.md Part 4)
2. ✅ Add `initializePowerSync()` to landing pages (see Part 5)
3. ✅ Test offline functionality (see Part 9)

---

**Need Help?**
- Check PowerSync dashboard Security → API Keys section
- See POWERSYNC_SECRETS_SETUP.md for detailed troubleshooting
- See FLUTTERFLOW_POWERSYNC_INTEGRATION_GUIDE.md for full integration steps
