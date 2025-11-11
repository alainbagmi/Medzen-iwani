# PowerSync Backend Deployment Guide

**Time Required:** 15-20 minutes
**Difficulty:** Intermediate
**Status:** Step-by-step instructions ready to execute

## Overview

This guide will deploy all backend components needed for PowerSync offline-first sync:

1. ✅ Get PowerSync credentials
2. ✅ Set Supabase secrets
3. ✅ Deploy PowerSync token Edge Function
4. ✅ Configure PowerSync instance
5. ✅ Test the deployment

---

## Prerequisites

Before starting, ensure you have:

- [ ] PowerSync account created
- [ ] Supabase project set up
- [ ] Supabase CLI installed (`npx supabase --version`)
- [ ] Terminal/command line access
- [ ] 15-20 minutes

### Check Supabase CLI

```bash
# Check if Supabase CLI is available
npx supabase --version

# Should output: supabase 1.x.x (or similar)
```

If not installed, it will be installed automatically when you run `npx supabase` commands.

---

## Step 1: Get PowerSync Credentials (5 minutes)

### 1.1 Login to PowerSync Dashboard

Open your PowerSync dashboard:
```
https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
```

Or visit: [PowerSync Console](https://powersync.journeyapps.com/)

### 1.2 Generate RSA Key Pair

1. In the PowerSync dashboard, go to **Settings** → **API Keys**
2. Click **"Generate RSA Key Pair"** button
3. You'll see two values generated:

**Save These Values - You'll Need Them Soon!**

```
Key ID: abc123def456...
```

```
Private Key:
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
[multiple lines of random characters]
...
-----END PRIVATE KEY-----
```

**Important:**
- Copy the **entire private key** including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines
- Save both values in a secure location
- You can't retrieve the private key later - if you lose it, you'll need to generate a new pair

### 1.3 Get Your PowerSync Instance URL

Your PowerSync instance URL is:
```
https://687fe5badb7a810007220898.powersync.journeyapps.com
```

This is visible in the PowerSync dashboard URL or under **Settings** → **Instance**.

---

## Step 2: Set Supabase Secrets (3 minutes)

Now we'll configure the secrets that the PowerSync token Edge Function needs.

### 2.1 Navigate to Your Project

```bash
# Make sure you're in your project directory
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
```

### 2.2 Link to Supabase (if not already linked)

```bash
# Check if already linked
npx supabase status

# If not linked, link your project
npx supabase link --project-ref YOUR_PROJECT_REF
```

**Where to find your project ref:**
- Go to your Supabase dashboard: https://supabase.com/dashboard/project/YOUR_PROJECT_ID
- Project ref is in the URL or under Project Settings → General → Reference ID

### 2.3 Set PowerSync URL Secret

```bash
npx supabase secrets set POWERSYNC_URL="https://687fe5badb7a810007220898.powersync.journeyapps.com"
```

Expected output:
```
Finished supabase secrets set.
```

### 2.4 Set PowerSync Key ID Secret

Replace `YOUR_KEY_ID` with the Key ID you got from Step 1.2:

```bash
npx supabase secrets set POWERSYNC_KEY_ID="YOUR_KEY_ID"
```

Example:
```bash
npx supabase secrets set POWERSYNC_KEY_ID="abc123def456ghi789"
```

### 2.5 Set PowerSync Private Key Secret

This one is tricky because the private key has multiple lines. Here's the correct way:

**Option A: Using a heredoc (Recommended)**

```bash
npx supabase secrets set POWERSYNC_PRIVATE_KEY="$(cat <<'EOF'
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
[paste your entire private key here]
...
-----END PRIVATE KEY-----
EOF
)"
```

**Option B: Using a file (Alternative)**

1. Create a temporary file with your private key:
```bash
cat > /tmp/powersync_key.pem << 'EOF'
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
[paste your entire private key here]
...
-----END PRIVATE KEY-----
EOF
```

2. Set the secret:
```bash
npx supabase secrets set POWERSYNC_PRIVATE_KEY="$(cat /tmp/powersync_key.pem)"
```

3. Delete the temporary file:
```bash
rm /tmp/powersync_key.pem
```

### 2.6 Verify Secrets Set

```bash
npx supabase secrets list
```

Expected output:
```
POWERSYNC_URL
POWERSYNC_KEY_ID
POWERSYNC_PRIVATE_KEY
```

**Note:** You can't see the actual values, only the names. This is for security.

---

## Step 3: Deploy PowerSync Token Function (2 minutes)

Now we'll deploy the Edge Function that generates PowerSync tokens.

### 3.1 Deploy the Function

```bash
npx supabase functions deploy powersync-token
```

Expected output:
```
Deploying powersync-token (project ref: your-project-ref)
Bundled powersync-token in XXms
...
Deployed Function powersync-token on project your-project-ref
```

### 3.2 Verify Deployment

```bash
npx supabase functions list
```

You should see `powersync-token` in the list.

---

## Step 4: Test the Deployment (5 minutes)

Let's make sure everything works!

### 4.1 Get a User Token

**Option A: Login via Flutter App**

1. Run your Flutter app
2. Login with a test user
3. The app will get a Supabase session token automatically

**Option B: Get Token via Supabase CLI**

```bash
# This will open a browser to login
npx supabase auth login
```

### 4.2 Test the Edge Function

```bash
# Get your auth token
USER_TOKEN=$(npx supabase auth token)

# Test the function
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer $USER_TOKEN"
```

**Expected Successful Response:**

```json
{
  "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6ImFiYzEyMyJ9.eyJzdWIiOiJ1c2VyLWlkIiwiYXVkIjoiaHR0cHM6Ly82ODdmZTViYWRiN2E4MTAwMDcyMjA4OTgucG93ZXJzeW5jLmpvdXJuZXlhcHBzLmNvbSIsImlhdCI6MTcwNjk2NDQ4MCwiZXhwIjoxNzA2OTkzMjgwfQ...",
  "powersync_url": "https://687fe5badb7a810007220898.powersync.journeyapps.com",
  "expires_at": "2025-10-22T20:30:00.000Z",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**If you see this, SUCCESS! ✅ The function is working!**

### 4.3 Common Test Errors

**Error: "No authorization header"**
```json
{"error": "No authorization header"}
```
**Solution:** Make sure you included the `--headers` parameter with a valid token.

**Error: "Unauthorized"**
```json
{"error": "Unauthorized"}
```
**Solution:** Your token is invalid or expired. Get a fresh token:
```bash
npx supabase auth login
```

**Error: "PowerSync not configured"**
```json
{"error": "PowerSync not configured"}
```
**Solution:** The secrets aren't set correctly. Go back to Step 2 and verify:
```bash
npx supabase secrets list
```

**Error: Invalid private key format**
```json
{"error": "Failed to import private key"}
```
**Solution:** The private key wasn't set correctly. Re-do Step 2.5, making sure to copy the ENTIRE key including headers.

---

## Step 5: Configure PowerSync Instance (5 minutes)

Now we need to connect PowerSync to your Supabase database.

### 5.1 Open PowerSync Dashboard

Visit:
```
https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
```

### 5.2 Configure Supabase Connection

1. Go to **Settings** → **Database**
2. Click **"Connect Database"** (or **"Edit"** if already configured)
3. Fill in your Supabase credentials:

**Supabase Project URL:**
```
Find this in your Supabase dashboard → Project Settings → API → URL
Example: https://abcdefghijk.supabase.co
```

**Supabase Database Connection String:**
```
Find this in your Supabase dashboard → Project Settings → Database → Connection String → Direct connection

Format: postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres
```

**Important:**
- Use the **Transaction** connection string (port 6543), not Session (port 5432)
- Make sure to replace `[password]` with your actual database password

4. Click **"Test Connection"**
5. If successful, click **"Save"**

### 5.3 Deploy Sync Rules

1. In PowerSync dashboard, go to **Sync Rules**
2. You should see the sync rules already there (from `powersync-sync-rules.yaml`)
3. If not, paste this:

```yaml
bucket_definitions:
  user_data:
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()
    data:
      - SELECT * FROM users WHERE id = bucket.user_id
      - SELECT * FROM electronic_health_records WHERE patient_id = bucket.user_id
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id
      - SELECT * FROM lab_results WHERE patient_id = bucket.user_id
      - SELECT * FROM prescriptions WHERE patient_id = bucket.user_id
      - SELECT * FROM immunizations WHERE patient_id = bucket.user_id
      - SELECT * FROM medical_records WHERE patient_id = bucket.user_id
      - SELECT * FROM ehrbase_sync_queue
        WHERE (table_name = 'users_demographics' AND record_id = bucket.user_id::text)
        OR (table_name IN ('vital_signs', 'lab_results', 'prescriptions', 'immunizations', 'medical_records')
            AND record_id IN (
              SELECT id::text FROM vital_signs WHERE patient_id = bucket.user_id
              UNION
              SELECT id::text FROM lab_results WHERE patient_id = bucket.user_id
              UNION
              SELECT id::text FROM prescriptions WHERE patient_id = bucket.user_id
              UNION
              SELECT id::text FROM immunizations WHERE patient_id = bucket.user_id
              UNION
              SELECT id::text FROM medical_records WHERE patient_id = bucket.user_id
            ))

parameters:
  user_id: SELECT request.jwt() ->> 'sub'
```

4. Click **"Validate"** to check for errors
5. Click **"Deploy"**

### 5.4 Verify Replication

1. Go to **Monitoring** → **Replication**
2. Check that status shows **"Connected"** or **"Syncing"**
3. If you see errors, check:
   - Database connection string is correct
   - Database password is correct
   - Supabase database is accessible (not paused)

---

## Step 6: Test End-to-End (5 minutes)

Final verification that everything works together!

### 6.1 Run Flutter App

```bash
flutter run
```

### 6.2 Login

Login with a test user in the app.

### 6.3 Check PowerSync Initialization

Look for these log messages in your console:

```
🔑 PowerSync: Fetching credentials from powersync-token function...
✅ PowerSync: Credentials fetched successfully
   Endpoint: https://687fe5badb7a810007220898.powersync.journeyapps.com
   Expires: 2025-10-22T20:30:00.000Z
PowerSync initialized successfully at: /path/to/medzen_powersync.db
PowerSync Status: connected=true, downloading=true, uploading=false, lastSyncedAt=2025-10-22T12:30:00Z
```

### 6.4 Test Data Sync

1. **Create a test record** (while online):
```dart
await db.execute('''
  INSERT INTO vital_signs
  (patient_id, systolic_bp, diastolic_bp, recorded_at, created_at, updated_at)
  VALUES (?, ?, ?, ?, ?, ?)
''', [userId, 120, 80, DateTime.now().toIso8601String(), DateTime.now().toIso8601String(), DateTime.now().toIso8601String()]);
```

2. **Wait 5-10 seconds** for sync

3. **Check Supabase** - Go to Supabase dashboard → Table Editor → vital_signs
   - You should see the new record there! ✅

4. **Test offline mode**:
   - Enable airplane mode on device/simulator
   - Create another vital signs record
   - Record appears immediately in app (written to local SQLite)
   - Disable airplane mode
   - Wait 5-10 seconds
   - Check Supabase - new record should sync! ✅

### 6.5 Run Diagnostic

Use the diagnostic tool we created:

```dart
import 'package:medzen_iwani/custom_code/actions/check_powersync_sync_status.dart';

final status = await checkPowerSyncSyncStatus();
print(status);
```

**Expected Result:**
```json
{
  "overall_status": "success",
  "powersync": {
    "connected": true,
    "downloading": false,
    "uploading": false,
    "last_synced_at": "2025-10-22T12:35:00Z"
  },
  "vital_signs_comparison": {
    "supabase": 5,
    "local": 5,
    "in_sync": true
  },
  "pending_uploads": 0
}
```

---

## Troubleshooting

### Problem: "Error fetching credentials" in app logs

**Symptom:**
```
❌ PowerSync: Error fetching credentials (attempt 1/3): ...
```

**Solutions:**

1. **Check Edge Function is deployed:**
```bash
npx supabase functions list
```
Should show `powersync-token`.

2. **Check secrets are set:**
```bash
npx supabase secrets list
```
Should show `POWERSYNC_URL`, `POWERSYNC_KEY_ID`, `POWERSYNC_PRIVATE_KEY`.

3. **Test Edge Function manually:**
```bash
USER_TOKEN=$(npx supabase auth token)
npx supabase functions invoke powersync-token --headers "Authorization: Bearer $USER_TOKEN"
```

4. **Check function logs:**
```bash
npx supabase functions logs powersync-token
```

### Problem: PowerSync connected but not syncing

**Symptom:**
```
connected=true, downloading=false, uploading=false
```
But no data appears in Supabase.

**Solutions:**

1. **Check sync rules in PowerSync dashboard** - Ensure they're deployed
2. **Check RLS policies in Supabase** - Make sure they allow inserts
3. **Check PowerSync instance replication** - Dashboard → Monitoring → Replication
4. **Check for errors in PowerSync logs** - Dashboard → Logs

### Problem: "Invalid private key" error

**Symptom:**
```json
{"error": "Failed to import private key"}
```

**Solution:**

Re-set the private key secret, ensuring you copy the ENTIRE key:

```bash
npx supabase secrets set POWERSYNC_PRIVATE_KEY="$(cat <<'EOF'
-----BEGIN PRIVATE KEY-----
[paste ENTIRE key here, including these header/footer lines]
-----END PRIVATE KEY-----
EOF
)"
```

### Problem: Sync rules validation fails

**Symptom:**
PowerSync dashboard shows errors when validating sync rules.

**Solutions:**

1. **Check table names match exactly** - Case-sensitive
2. **Verify all tables exist in Supabase**
3. **Check JWT extraction** - `token_parameters.user_id()` should return Firebase UID
4. **Test sync rules** - Use PowerSync dashboard's "Test Rules" feature

---

## Verification Checklist

After deployment, verify these checkpoints:

- [ ] **Secrets Set**
  ```bash
  npx supabase secrets list
  # Shows: POWERSYNC_URL, POWERSYNC_KEY_ID, POWERSYNC_PRIVATE_KEY
  ```

- [ ] **Edge Function Deployed**
  ```bash
  npx supabase functions list
  # Shows: powersync-token
  ```

- [ ] **Edge Function Works**
  ```bash
  npx supabase functions invoke powersync-token --headers "Authorization: Bearer $USER_TOKEN"
  # Returns: token, powersync_url, expires_at, user_id
  ```

- [ ] **PowerSync Instance Connected**
  - PowerSync dashboard → Settings → Database
  - Status: "Connected"

- [ ] **Sync Rules Deployed**
  - PowerSync dashboard → Sync Rules
  - Status: "Active"

- [ ] **App Connects to PowerSync**
  - Flutter app logs show: "PowerSync initialized successfully"
  - Logs show: "connected=true"

- [ ] **Data Syncs to Supabase**
  - Create record in app
  - Record appears in Supabase table within 10 seconds

- [ ] **Offline Mode Works**
  - Disable network
  - Create record in app (appears immediately)
  - Enable network
  - Record syncs to Supabase within 10 seconds

---

## Next Steps

After successful deployment:

1. **Add to Test Page** - Add PowerSync sync status check to your test page
2. **Monitor Sync Health** - Use diagnostic tool regularly
3. **Set Up Alerts** - Configure PowerSync dashboard alerts for sync failures
4. **Review Logs** - Periodically check PowerSync and Supabase function logs
5. **Test Edge Cases** - Test with poor connectivity, large data sets, concurrent users

---

## Quick Reference Commands

```bash
# Set secrets
npx supabase secrets set POWERSYNC_URL="https://687fe5badb7a810007220898.powersync.journeyapps.com"
npx supabase secrets set POWERSYNC_KEY_ID="YOUR_KEY_ID"
npx supabase secrets set POWERSYNC_PRIVATE_KEY="YOUR_PRIVATE_KEY"

# Deploy function
npx supabase functions deploy powersync-token

# Test function
npx supabase functions invoke powersync-token --headers "Authorization: Bearer $(npx supabase auth token)"

# View logs
npx supabase functions logs powersync-token

# List secrets
npx supabase secrets list

# List functions
npx supabase functions list
```

---

## Support

If you encounter issues:

1. **Check logs:**
   ```bash
   npx supabase functions logs powersync-token
   ```

2. **Review PowerSync dashboard:**
   - Monitoring → Logs
   - Monitoring → Replication

3. **Run diagnostic:**
   ```dart
   await checkPowerSyncSyncStatus()
   ```

4. **Refer to documentation:**
   - POWERSYNC_SYNC_STATUS.md
   - POWERSYNC_QUICK_START.md

---

**Deployment Status:** Ready to execute! 🚀

Follow the steps in order and you'll have PowerSync backend fully deployed in 15-20 minutes.
