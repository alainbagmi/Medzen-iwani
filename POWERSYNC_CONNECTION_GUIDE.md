# PowerSync Account Connection Guide

## Step 1: Get Your PowerSync Credentials

### A. Log into PowerSync Dashboard

1. Open your PowerSync dashboard:
   https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898

2. Log in with your credentials

### B. Get API Key (for MCP Server)

1. In the dashboard, navigate to **Settings** (gear icon)
2. Click on **API Keys**
3. Click **Generate New API Key** or **Create API Key**
4. Copy the API key (it will look like: `ps_api_xxxxxxxxxxxxxxxx`)
5. Save it securely - you'll need it in Step 2

### C. Get Instance URL

Your instance URL is:
```
https://687fe5badb7a810007220898.powersync.journeyapps.com
```

### D. Get RSA Key Pair (for Flutter App Authentication)

1. In the dashboard, go to **Settings** → **RSA Keys**
2. If you don't have a key pair, click **Generate RSA Key Pair**
3. Copy both:
   - **Key ID** (e.g., `abc123...`)
   - **Private Key** (entire key including `-----BEGIN PRIVATE KEY-----`)

## Step 2: Configure MCP Server

Update your `.mcp.json` file with the API key:

```json
{
  "mcpServers": {
    "powersync": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "powersync-mcp-server",
        "python",
        "src/powersync_mcp_server.py"
      ],
      "env": {
        "POWERSYNC_URL": "https://687fe5badb7a810007220898.powersync.journeyapps.com",
        "POWERSYNC_API_KEY": "YOUR_API_KEY_HERE"
      }
    }
  }
}
```

## Step 3: Configure Supabase Edge Function

Set the PowerSync credentials for your token generation function:

```bash
# Set PowerSync instance URL
npx supabase secrets set POWERSYNC_URL=https://687fe5badb7a810007220898.powersync.journeyapps.com

# Set PowerSync RSA Key ID
npx supabase secrets set POWERSYNC_KEY_ID=your-key-id-from-dashboard

# Set PowerSync Private Key (paste entire key)
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
... (paste your entire private key here) ...
-----END PRIVATE KEY-----"
```

## Step 4: Verify Connection

After configuration, restart Claude Code and test:

### Test MCP Server Connection

Ask Claude:
```
Check PowerSync instance health
```

Expected response:
```
PowerSync Instance Health:

Instance: https://687fe5badb7a810007220898.powersync.journeyapps.com
Status: ✅ Healthy
Response Time: X.XXs

The PowerSync instance is reachable and responding.
```

### Test Supabase Edge Function

```bash
# Test the token function
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer YOUR_USER_JWT"
```

Expected response:
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
  "powersync_url": "https://687fe5badb7a810007220898.powersync.journeyapps.com",
  "expires_at": "2025-01-22T...",
  "user_id": "..."
}
```

## Step 5: Test Flutter App Connection

In your Flutter app, PowerSync should now connect automatically:

```dart
import 'package:medzen_iwani/powersync/database.dart';

// Check connection status
print('PowerSync connected: ${isPowerSyncConnected()}');
print('Last synced: ${getLastSyncedAt()}');

// Watch connection status
db.statusStream.listen((status) {
  print('PowerSync Status:');
  print('  Connected: ${status.connected}');
  print('  Downloading: ${status.downloading}');
  print('  Uploading: ${status.uploading}');
  print('  Last Synced: ${status.lastSyncedAt}');
});
```

## Troubleshooting

### Issue: "Unauthorized" or "Invalid credentials"

**Solution:**
- Verify API key is correct
- Ensure RSA private key is complete (including BEGIN/END markers)
- Check Key ID matches the one in dashboard

### Issue: "Instance not found"

**Solution:**
- Verify instance URL is correct: `https://687fe5badb7a810007220898.powersync.journeyapps.com`
- Check instance is active in dashboard

### Issue: MCP Server can't connect

**Solution:**
1. Restart Claude Code to reload MCP servers
2. Check `.mcp.json` syntax is valid
3. Verify API key is set correctly

### Issue: Flutter app not connecting

**Solution:**
1. Check Supabase secrets are set:
   ```bash
   npx supabase secrets list
   ```
2. Verify token function is deployed:
   ```bash
   npx supabase functions list
   ```
3. Check Flutter app logs for connection errors

## Quick Reference

### Your PowerSync Details

- **Dashboard:** https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
- **Instance URL:** https://687fe5badb7a810007220898.powersync.journeyapps.com
- **Org ID:** 687fe5b9be0f9c000799e9c5
- **App ID:** 687fe5badb7a810007220898

### Files to Update

1. `.mcp.json` - Add PowerSync API key
2. Supabase secrets - Set POWERSYNC_URL, POWERSYNC_KEY_ID, POWERSYNC_PRIVATE_KEY

### Commands

```bash
# Set Supabase secrets
npx supabase secrets set POWERSYNC_URL=...
npx supabase secrets set POWERSYNC_KEY_ID=...
npx supabase secrets set POWERSYNC_PRIVATE_KEY="..."

# Deploy token function
npx supabase functions deploy powersync-token

# Test token function
npx supabase functions invoke powersync-token

# Check secrets
npx supabase secrets list
```

## Next Steps

After completing these steps:

1. ✅ MCP Server connected (can ask Claude about PowerSync status)
2. ✅ Supabase Edge Function configured (generates PowerSync tokens)
3. ✅ Flutter app ready (will sync via PowerSync when initialized)

You'll have full PowerSync integration with:
- Real-time monitoring via MCP server
- Automatic JWT token generation
- Offline-first data sync in Flutter app

---

**Need Help?**

If you get stuck on any step, let me know which step and I'll help you troubleshoot!
