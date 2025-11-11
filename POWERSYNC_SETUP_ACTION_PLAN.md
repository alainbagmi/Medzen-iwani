# PowerSync Setup - Action Plan

## Updated Configuration

✅ **PowerSync Instance URL Updated:**
- Old: `https://687fe5badb7a810007220898.powersync.journeyapps.com`
- New: `https://68f8702005eb05000765fba5.powersync.journeyapps.com`

## Step-by-Step Setup Guide

### Step 1: Login to PowerSync Dashboard (2 min)

1. Open browser and go to: https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/68f8702005eb05000765fba5
2. Login with:
   - **Username:** info@mylestechsolutionsllc.com
   - **Password:** Mylestech@2025

### Step 2: Connect PowerSync to Supabase (5 min)

1. In PowerSync Dashboard, find **Database** or **Data Sources** in the sidebar
2. Click **Add Database** or **Connect Database**
3. Select **PostgreSQL** or **Supabase**
4. Enter connection details:

   **Database Connection String:**
   ```
   postgresql://postgres.noaeltglphdlkbflipit:[YOUR_DB_PASSWORD]@aws-0-us-east-2.pooler.supabase.com:6543/postgres
   ```

   **Get the password from Supabase:**
   - Go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/settings/database
   - Copy the database password
   - Replace `[YOUR_DB_PASSWORD]` in the connection string above

5. Click **Test Connection**
6. If successful, click **Save**

### Step 3: Deploy Sync Rules (5 min)

1. In PowerSync Dashboard, navigate to **Sync Rules** (sidebar)
2. Delete any existing rules
3. Copy the entire content from: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/POWERSYNC_SYNC_RULES_COMPLETE.yaml`
4. Paste into PowerSync Dashboard
5. Click **Validate** (should show green checkmark)
6. Click **Deploy** or **Save**
7. Wait for deployment to complete (should see "Successfully deployed")

### Step 4: Generate RSA Keys (3 min)

1. In PowerSync Dashboard, go to **Settings** → **API Keys** or **Security**
2. Find **RSA Key Pair** section
3. Click **Generate RSA Key Pair** (or use existing if already generated)
4. Copy and save these values:
   - **Key ID** (looks like: `abc123-def456-789...`)
   - **Private Key** (looks like):
     ```
     -----BEGIN PRIVATE KEY-----
     MIIEvQIBADANBgkqhkiG9w0BAQE...
     ...
     -----END PRIVATE KEY-----
     ```

**⚠️ IMPORTANT:** Save these immediately - you can't see the private key again!

### Step 5: Set Supabase Secrets (2 min)

Run these commands in your terminal (replace placeholders with actual values from Step 4):

```bash
# Set PowerSync URL
npx supabase secrets set POWERSYNC_URL=https://68f8702005eb05000765fba5.powersync.journeyapps.com

# Set PowerSync Key ID (from Step 4)
npx supabase secrets set POWERSYNC_KEY_ID=<paste-your-key-id-here>

# Set PowerSync Private Key (from Step 4)
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
<paste-entire-private-key-here>
-----END PRIVATE KEY-----"
```

**Verify secrets were set:**
```bash
npx supabase secrets list
```

Should show:
- POWERSYNC_URL
- POWERSYNC_KEY_ID
- POWERSYNC_PRIVATE_KEY

### Step 6: Deploy PowerSync Token Function (2 min)

```bash
# Deploy the edge function
npx supabase functions deploy powersync-token

# Check deployment logs
npx supabase functions logs powersync-token
```

Expected output: "Function deployed successfully"

### Step 7: Test the Connection (3 min)

```bash
# Get a user token (you'll need to login to your app first, or use existing token)
# For now, just check if the function is deployed
npx supabase functions invoke powersync-token --headers "Authorization: Bearer $(npx supabase auth get-token)"
```

Expected response:
```json
{
  "token": "eyJhbGc...",
  "powersync_url": "https://68f8702005eb05000765fba5.powersync.journeyapps.com",
  "expires_at": "2025-...",
  "user_id": "..."
}
```

### Step 8: Verify PowerSync Instance Health

After completing all steps above, run:

```bash
# This should now show instance as healthy
```

Or I can check for you using the PowerSync MCP server.

---

## Common Issues & Solutions

### Issue: Database connection fails
**Solution:**
- Check password is correct
- Ensure Supabase project is not paused
- Verify connection string format

### Issue: Sync rules validation fails
**Solution:**
- Ensure all materialized views exist in Supabase
- Run: `SELECT refresh_powersync_materialized_views();` in Supabase SQL editor

### Issue: Edge function deploy fails
**Solution:**
- Verify all 3 secrets are set correctly
- Check private key includes BEGIN/END markers
- Ensure no extra spaces or newlines

### Issue: Token function returns error
**Solution:**
- Check function logs: `npx supabase functions logs powersync-token`
- Verify secrets: `npx supabase secrets list`
- Ensure user is authenticated in Supabase

---

## Quick Reference

**PowerSync Dashboard:** https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/68f8702005eb05000765fba5

**Supabase Project:** noaeltglphdlkbflipit

**Instance URL:** https://68f8702005eb05000765fba5.powersync.journeyapps.com

**Sync Rules File:** `POWERSYNC_SYNC_RULES_COMPLETE.yaml`

**Edge Function:** `supabase/functions/powersync-token/index.ts`

---

## Next Steps After Setup

Once all steps are complete:

1. ✅ Test Flutter app offline sync
2. ✅ Verify data syncs between devices
3. ✅ Check sync queue in Supabase
4. ✅ Monitor PowerSync dashboard for metrics

---

**Ready to start? Begin with Step 1!**

Once you complete Steps 1-6, let me know and I'll verify the connection for you.
