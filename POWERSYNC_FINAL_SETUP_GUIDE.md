# PowerSync Final Setup Guide

## Status: Ready to Connect

✅ **Supabase Configuration:** Complete
✅ **Sync Rules File:** Created
✅ **Edge Function:** Created
⏳ **PowerSync Dashboard Connection:** Needs your action

---

## Your Credentials

### PowerSync Dashboard
- **URL:** https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
- **Username:** info@mylestechsolutionsllc.com
- **Password:** Mylestech@2025

### Supabase Database Connection
- **Connection String:**
  ```
  postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
  ```

- **Individual Fields:**
  - Host: `aws-0-us-east-1.pooler.supabase.com`
  - Port: `6543`
  - Database: `postgres`
  - Username: `postgres.noaeltglphdlkbflipit`
  - Password: `Mylestech2025`
  - SSL Mode: `require`

---

## Step 1: Connect PowerSync to Supabase (10 minutes)

### 1.1 Log into PowerSync Dashboard

1. Go to: https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
2. Login with:
   - Email: `info@mylestechsolutionsllc.com`
   - Password: `Mylestech@2025`

### 1.2 Configure Database Connection

1. In the PowerSync Dashboard, navigate to **Settings** → **Database** (or **Configuration**)
2. Click **Add Database Connection** or **Configure Database**
3. Enter the Supabase connection details:

   **Option A - Connection String (Recommended):**
   ```
   postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
   ```

   **Option B - Individual Fields:**
   ```
   Connection Type: PostgreSQL
   Host: aws-0-us-east-1.pooler.supabase.com
   Port: 6543
   Database: postgres
   Username: postgres.noaeltglphdlkbflipit
   Password: Mylestech2025
   SSL Mode: require
   ```

4. Click **Test Connection**
   - Should see: ✅ Connection Successful
5. Click **Save**

### 1.3 Deploy Sync Rules

1. In PowerSync Dashboard, go to **Sync Rules**
2. Copy the entire contents of `powersync-sync-rules.yaml`:

   ```bash
   cat powersync-sync-rules.yaml
   ```

3. Paste into the PowerSync Dashboard editor
4. Click **Validate** to check syntax
5. Click **Deploy** to activate

Expected result:
- ✅ Sync rules deployed successfully
- ✅ Database connection active

---

## Step 2: Get PowerSync RSA Keys (5 minutes)

### 2.1 Generate RSA Key Pair

1. In PowerSync Dashboard, go to **Settings** → **RSA Keys** (or **API Keys**)
2. Click **Generate RSA Key Pair** (if you don't have one)
3. Copy and save:
   - **Key ID** (example: `abc123...`)
   - **Private Key** (entire key including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)

### 2.2 Get PowerSync API Key (OPTIONAL - for MCP Server only)

**Note:** This step is optional! The API key is only needed for the MCP server monitoring tool. Your Flutter app and PowerSync sync will work without it.

If you want to enable the MCP server:
1. In PowerSync Dashboard, look for **Settings** → **API Keys** or **Integrations**
2. If you see an option to **Generate New API Key** or **Create Token**, click it
3. Copy the API key (might start with `ps_api_...` or similar format)
4. Save it securely

**Can't find it?** See `HOW_TO_GET_POWERSYNC_API_KEY.md` for detailed instructions, or skip this step and continue without the MCP server.

---

## Step 3: Configure Supabase Secrets (5 minutes)

Run these commands to set PowerSync credentials in Supabase:

```bash
# Set PowerSync instance URL
npx supabase secrets set POWERSYNC_URL=https://687fe5badb7a810007220898.powersync.journeyapps.com

# Set PowerSync RSA Key ID (from Step 2.1)
npx supabase secrets set POWERSYNC_KEY_ID=YOUR_KEY_ID_HERE

# Set PowerSync Private Key (paste entire key from Step 2.1)
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_CONTENT_HERE
-----END PRIVATE KEY-----"
```

**Verify secrets were set:**
```bash
npx supabase secrets list
```

Expected output:
```
POWERSYNC_URL
POWERSYNC_KEY_ID
POWERSYNC_PRIVATE_KEY
```

---

## Step 4: Deploy Edge Function (2 minutes)

Deploy the PowerSync token generation function:

```bash
npx supabase functions deploy powersync-token
```

Expected output:
```
✅ Function deployed successfully
URL: https://noaeltglphdlkbflipit.supabase.co/functions/v1/powersync-token
```

---

## Step 5: Update MCP Configuration (OPTIONAL - 2 minutes)

**Note:** This step is optional! Skip it if you don't have a PowerSync API key yet.

If you got the API key in Step 2.2, update `.mcp.json`:

```json
{
  "mcpServers": {
    "powersync": {
      "env": {
        "POWERSYNC_URL": "https://687fe5badb7a810007220898.powersync.journeyapps.com",
        "POWERSYNC_API_KEY": "YOUR_API_KEY_HERE"
      }
    }
  }
}
```

Then restart Claude Code to load the MCP server.

**Don't have the API key?** That's fine! Continue to Step 6. The MCP server is just for monitoring and isn't required for PowerSync to work.

---

## Step 6: Verification (5 minutes)

### 6.1 Check PowerSync Dashboard

In PowerSync Dashboard → **Status** or **Metrics**:
- ✅ Database: Connected
- ✅ Sync Rules: Deployed
- ✅ Replication Lag: < 1 second

### 6.2 Check Supabase Health

Run this query in Supabase:
```sql
SELECT * FROM check_powersync_health();
```

Expected output:
```
check_name              | status | details
-----------------------|--------|---------------------------
Replication Enabled    | OK     | Publication exists
Active Replication... | OK     | 1 active slot(s)
Table Permissions      | OK     | 99 tables accessible
```

### 6.3 Test Data Sync

1. **Insert test data in Supabase:**
```sql
INSERT INTO users (id, firebase_uid, email, first_name, last_name, created_at)
VALUES (
  gen_random_uuid(),
  'test-powersync-sync-' || extract(epoch from now())::text,
  'powersync-test@medzen.com',
  'PowerSync',
  'Test',
  NOW()
)
RETURNING id, firebase_uid, email;
```

2. **Check PowerSync Dashboard:**
   - Go to **Data** or **Metrics**
   - Should see the new record within 1-2 seconds
   - If it appears: ✅ Sync is working!

3. **Clean up test data:**
```sql
DELETE FROM users WHERE email = 'powersync-test@medzen.com';
```

### 6.4 Test MCP Server

Ask Claude Code:
```
Check PowerSync instance health
```

Expected response:
```
✅ Instance: Healthy
Response Time: X.XXs
```

---

## Troubleshooting

### Issue: "Connection Failed"

**Check:**
1. Password is exactly: `Mylestech2025` (case-sensitive)
2. Host is: `aws-0-us-east-1.pooler.supabase.com`
3. Port is: `6543` (not 5432)
4. SSL mode is: `require`

**Test manually:**
```bash
psql "postgresql://postgres.noaeltglphdlkbflipit:Mylestech2025@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require"
```

### Issue: "Sync Rules Validation Error"

**Fix:**
1. Validate YAML syntax online: https://www.yamllint.com/
2. Test SQL queries in Supabase SQL Editor
3. Check table names match exactly (case-sensitive)

### Issue: "Edge Function Deployment Failed"

**Fix:**
```bash
# Check Supabase is linked
npx supabase link --project-ref noaeltglphdlkbflipit

# Try deploying again
npx supabase functions deploy powersync-token
```

### Issue: "No Data Syncing"

**Check:**
1. PowerSync Dashboard shows "Connected"
2. Run health check: `SELECT * FROM check_powersync_health();`
3. Check sync rules are deployed
4. Verify test data appears in PowerSync within seconds

---

## Completion Checklist

- [ ] Logged into PowerSync Dashboard
- [ ] Connected PowerSync to Supabase database
- [ ] Deployed sync rules to PowerSync
- [ ] Generated RSA key pair in PowerSync
- [ ] Generated PowerSync API key
- [ ] Set Supabase secrets (POWERSYNC_URL, KEY_ID, PRIVATE_KEY)
- [ ] Deployed powersync-token Edge Function
- [ ] Updated .mcp.json with API key
- [ ] Restarted Claude Code
- [ ] Verified PowerSync health (all OK)
- [ ] Tested data sync (works within seconds)
- [ ] Tested MCP server (responds to queries)

---

## What Happens Next

Once all steps are complete, you'll have:

1. **Offline-First Flutter App:**
   - Local SQLite database
   - Automatic bidirectional sync
   - Works offline, syncs when online

2. **Real-Time Data Flow:**
   ```
   Flutter App (SQLite) ←→ PowerSync ←→ Supabase ←→ EHRbase
   ```

3. **Monitoring:**
   - PowerSync Dashboard: Real-time metrics
   - Claude Code MCP: Query sync status
   - Supabase: Health checks via SQL

---

## Next Steps (After Setup)

1. **Initialize PowerSync in Flutter:**
   - Already coded in `lib/powersync/database.dart`
   - Call `initializePowerSync()` in `main.dart`

2. **Test Offline Functionality:**
   - Disable internet
   - Create/update medical records
   - Re-enable internet
   - Watch data sync automatically

3. **Monitor in Production:**
   - PowerSync Dashboard: Track sync lag
   - Health checks: Run daily
   - Error alerts: Configure in PowerSync

---

**Estimated Total Time:** 30 minutes
**Difficulty:** Medium (requires manual steps)

Let me know when you've completed the steps and I'll help verify everything is working correctly!
