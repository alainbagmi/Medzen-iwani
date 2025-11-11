# PowerSync + Supabase Integration Setup Guide

**Status:** ✅ Code is implemented, infrastructure needs configuration

This guide walks you through setting up PowerSync for offline-first data synchronization in MedZen Iwani.

## What's Already Done ✅

Your codebase already has:
- ✅ PowerSync package installed (`pubspec.yaml`)
- ✅ PowerSync schema defined (`lib/powersync/schema.dart`)
- ✅ PowerSync connector implemented (`lib/powersync/supabase_connector.dart`)
- ✅ PowerSync initialization logic (`lib/powersync/database.dart`)
- ✅ PowerSync Edge Function (`supabase/functions/powersync-token/index.ts`)
- ✅ Database migration with permissions (`supabase/migrations/20250121000002_powersync_permissions.sql`)
- ✅ Automatic initialization in `main.dart` via `InitializationManager`

## What You Need to Do 🔧

Follow these 6 steps to complete the setup:

---

## Step 1: Run Supabase Database Migration

First, apply the PowerSync permissions migration to your Supabase database:

```bash
# Make sure you're in the project directory
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Push the migration to Supabase
npx supabase db push
```

**What this does:**
- Creates a PostgreSQL publication called `powersync` for logical replication
- Grants SELECT permissions to the `postgres` user on all tables
- Enables Row Level Security (RLS) on medical data tables
- Creates helper views and functions for monitoring PowerSync health

**Verify it worked:**
```bash
# Check if publication exists
npx supabase db remote --execute "SELECT * FROM pg_publication WHERE pubname = 'powersync';"

# Should return: powersync | postgres | true | true | true | true
```

---

## Step 2: Create PowerSync Cloud Instance

1. Go to [PowerSync Dashboard](https://powersync.journeyapps.com/)
2. **Sign up** or **Log in**
3. Click **"Create Instance"** or **"New Instance"**
4. Configure your instance:
   - **Instance Name:** `medzen-iwani-production` (or `medzen-iwani-dev` for development)
   - **Region:** Choose closest to your users (US, EU, JP, AU, or BR)
   - **Service Version:** Select **"Stable"** for production
5. Click **"Create"** or **"Next"**
6. **Save your instance URL** (you'll need this later):
   ```
   https://YOUR_INSTANCE_ID.journeyapps.com
   ```

---

## Step 3: Generate PowerSync API Credentials

Still in the PowerSync Dashboard:

1. Navigate to **Settings → API Keys**
2. Click **"Generate RSA Key Pair"**
3. **IMPORTANT:** Save these values immediately (you can't retrieve them later):

   **Key ID** (will look like):
   ```
   abc123def456ghi789
   ```

   **Private Key** (PEM format, including headers):
   ```
   -----BEGIN PRIVATE KEY-----
   MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
   (many more lines)
   ...
   -----END PRIVATE KEY-----
   ```

⚠️ **Store these securely** - you'll need them in the next step.

---

## Step 4: Connect PowerSync to Supabase Database

### 4.1 Get Your Supabase Connection String

1. Open your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your **MedZen Iwani** project
3. Go to **Project Settings → Database**
4. Under **Connection string**, select **"Connection pooling"** tab
5. Copy the **"Transaction"** connection string (will look like):
   ```
   postgresql://postgres.PROJECT_REF:[YOUR-PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres
   ```
6. **Replace `[YOUR-PASSWORD]`** with your actual database password

### 4.2 Configure PowerSync Connection

Back in PowerSync Dashboard:

1. Click **"Connect to Database"** or navigate to **"Database"** section
2. **Paste your Supabase connection string**
3. Click **"Test Connection"**
   - ✅ Should show: "Connection successful"
   - ❌ If it fails, check:
     - Password is correct
     - Connection string is from "Transaction" mode
     - Your database migration ran successfully (Step 1)

4. **Configure Supabase Authentication:**
   - Go to your Supabase Dashboard → **Project Settings → API**
   - Copy the **JWT Secret** (under "JWT Settings")
   - Return to PowerSync Dashboard
   - Paste JWT Secret into the **"JWT Secret"** field
   - Enable **"Supabase Authentication"**

5. Click **"Save"** or **"Finalize"**

---

## Step 5: Configure PowerSync Sync Rules

Sync Rules determine which data PowerSync syncs to each user's device.

1. In PowerSync Dashboard, go to **"Sync Rules"** section
2. **Replace the entire sync rules file** with:

```yaml
bucket_definitions:
  global:
    # User can only access their own data
    # This creates a "bucket" per user based on their Firebase UID
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()

    data:
      # User's own profile
      - SELECT * FROM users WHERE id = bucket.user_id

      # User's electronic health records
      - SELECT * FROM electronic_health_records WHERE patient_id = bucket.user_id

      # User's vital signs
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id

      # User's lab results
      - SELECT * FROM lab_results WHERE patient_id = bucket.user_id

      # User's prescriptions
      - SELECT * FROM prescriptions WHERE patient_id = bucket.user_id

      # User's immunizations
      - SELECT * FROM immunizations WHERE patient_id = bucket.user_id

      # User's medical records
      - SELECT * FROM medical_records WHERE patient_id = bucket.user_id

      # User's sync queue entries
      - SELECT * FROM ehrbase_sync_queue
        WHERE record_id IN (
          SELECT id::text FROM users WHERE id = bucket.user_id
        )
```

3. Click **"Validate"** to check for syntax errors
4. Click **"Save & Deploy"**

**What this does:**
- Each user gets their own isolated "bucket" of data
- Users can only sync their own medical records (enforced at PowerSync level)
- Changes are bidirectional: writes from Flutter → Supabase → other devices

---

## Step 6: Configure Supabase Edge Function Secrets

The `powersync-token` Edge Function needs your PowerSync credentials.

### Set the secrets:

```bash
# Set PowerSync instance URL
npx supabase secrets set POWERSYNC_URL=https://YOUR_INSTANCE_ID.journeyapps.com

# Set PowerSync Key ID (from Step 3)
npx supabase secrets set POWERSYNC_KEY_ID=abc123def456ghi789

# Set PowerSync Private Key (from Step 3)
# NOTE: Paste the ENTIRE private key including -----BEGIN PRIVATE KEY----- headers
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
(paste all lines here)
...
-----END PRIVATE KEY-----"
```

**Important:**
- Replace `YOUR_INSTANCE_ID` with your actual PowerSync instance ID
- Paste the **entire** private key with headers and line breaks
- Use **double quotes** around the private key

### Verify secrets were set:

```bash
npx supabase secrets list

# Should show:
# POWERSYNC_URL
# POWERSYNC_KEY_ID
# POWERSYNC_PRIVATE_KEY
```

### Deploy the Edge Function:

```bash
# Deploy the powersync-token function
npx supabase functions deploy powersync-token

# Should output:
# ✅ Deployed Function powersync-token
```

### Test the Edge Function:

```bash
# Get a test token (replace with your actual user JWT)
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer YOUR_USER_JWT_TOKEN"

# Should return:
# {
#   "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
#   "powersync_url": "https://YOUR_INSTANCE_ID.journeyapps.com",
#   "expires_at": "2025-01-22T14:00:00.000Z",
#   "user_id": "user-uuid"
# }
```

---

## Step 7: Test the Integration ✅

### 7.1 Run the Flutter App

```bash
flutter run
```

### 7.2 Monitor Initialization Logs

When the app starts, you should see in the console:

```
🚀 Starting system initialization...
🔥 Firebase: Verifying initialization...
✅ Firebase: Initialized (User: Not authenticated)
🟢 Supabase: Verifying initialization...
✅ Supabase: Initialized (Session: No session)
⚡ PowerSync: Initializing...
⚠️  PowerSync: No user session - skipping (will initialize after login)

📊 System Status:
  Firebase:   ✅ initialized
  Supabase:   ✅ initialized
  PowerSync:  ⚠️  offline
  EHRbase:    ⏸️  notStarted
  Network:    🟢 Online
```

### 7.3 Sign Up / Log In

After authentication, PowerSync should initialize:

```
⚡ PowerSync: Initializing...
🔑 PowerSync: Fetching credentials from powersync-token function...
✅ PowerSync: Credentials fetched successfully
   Endpoint: https://YOUR_INSTANCE_ID.journeyapps.com
   Expires: 2025-01-22T14:00:00.000Z
✅ PowerSync: Initialized and connected

📊 System Status:
  Firebase:   ✅ initialized
  Supabase:   ✅ initialized
  PowerSync:  ✅ initialized
  EHRbase:    ✅ initialized
  Network:    🟢 Online
```

### 7.4 Test Offline Mode

1. Put device in **Airplane Mode**
2. Try creating a new vital sign or medical record
3. It should succeed and save locally
4. Turn **Airplane Mode** off
5. PowerSync should automatically sync the data to Supabase

---

## Troubleshooting 🔍

### Issue: "PowerSync not configured" error

**Solution:**
```bash
# Check if secrets are set
npx supabase secrets list

# If missing, go back to Step 6
```

---

### Issue: PowerSync token request fails

**Check:**
1. Edge Function is deployed: `npx supabase functions list`
2. Secrets are set: `npx supabase secrets list`
3. User is authenticated (has valid Supabase session)

**Debug:**
```bash
# View Edge Function logs
npx supabase functions logs powersync-token --follow

# Test manually
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/powersync-token \
  -H "Authorization: Bearer YOUR_USER_JWT"
```

---

### Issue: PowerSync can't connect to database

**Check:**
1. Database migration ran: `npx supabase db push`
2. Publication exists:
   ```sql
   SELECT * FROM pg_publication WHERE pubname = 'powersync';
   ```
3. PowerSync instance is correctly connected to Supabase in PowerSync Dashboard

---

### Issue: No data syncing to device

**Check Sync Rules:**
1. Go to PowerSync Dashboard → Sync Rules
2. Click **"Validate"**
3. Make sure all table names match your Supabase schema
4. Check that `firebase_uid` column exists in `users` table

**Debug Query:**
```sql
-- Test the sync rules query manually
SELECT id as user_id
FROM users
WHERE firebase_uid = 'YOUR_FIREBASE_UID';

-- Should return the user's ID
```

---

### Issue: "Replication slot not found" or connection issues

**Solution:**
```bash
# Check PowerSync health
npx supabase db remote --execute "SELECT * FROM check_powersync_health();"

# Should show:
# ✅ Replication Enabled: OK
# ✅ Active Replication Slots: OK
# ✅ Table Permissions: OK
```

---

## Architecture Overview

```
┌─────────────────────────────────────────┐
│  Flutter App                            │
│  ┌─────────────────────────────────┐   │
│  │ PowerSync Local SQLite DB       │   │ ← Offline writes succeed here
│  └──────────────┬──────────────────┘   │
└─────────────────┼────────────────────────┘
                  │
                  ▼ (when online)
┌─────────────────────────────────────────┐
│  PowerSync Cloud Instance               │
│  https://YOUR_INSTANCE.journeyapps.com  │ ← Bidirectional sync
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Supabase PostgreSQL                    │
│  (Source of truth)                      │
└──────────────┬──────────────────────────┘
               │
               ▼ (via database triggers)
┌─────────────────────────────────────────┐
│  ehrbase_sync_queue                     │
└──────────────┬──────────────────────────┘
               │
               ▼ (via Edge Function)
┌─────────────────────────────────────────┐
│  EHRbase (OpenEHR Server)               │
└─────────────────────────────────────────┘
```

---

## Next Steps 🚀

Once PowerSync is working:

1. **Test Offline Scenarios:**
   - Create records offline
   - Verify they sync when back online
   - Test conflict resolution (edit same record on two devices)

2. **Monitor Sync Status:**
   - Use `lib/services/initialization_manager.dart`'s status methods
   - Add sync status UI indicator to your app
   - Monitor PowerSync Dashboard for replication health

3. **Optimize Performance:**
   - Review sync rules to ensure only necessary data syncs
   - Consider pagination for large datasets
   - Monitor PowerSync logs for slow queries

4. **Production Checklist:**
   - [ ] PowerSync instance in correct region
   - [ ] Sync rules validated and tested
   - [ ] Edge Function deployed to production Supabase
   - [ ] Secrets configured in production
   - [ ] Database migration applied
   - [ ] Offline mode tested thoroughly
   - [ ] Sync conflict resolution tested

---

## Quick Reference Commands

```bash
# Deploy Edge Function
npx supabase functions deploy powersync-token

# Push database migration
npx supabase db push

# Set secrets (do all 3)
npx supabase secrets set POWERSYNC_URL=https://YOUR_INSTANCE.journeyapps.com
npx supabase secrets set POWERSYNC_KEY_ID=YOUR_KEY_ID
npx supabase secrets set POWERSYNC_PRIVATE_KEY="YOUR_PRIVATE_KEY"

# Test Edge Function
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer YOUR_JWT"

# Check database health
npx supabase db remote --execute "SELECT * FROM check_powersync_health();"

# View Edge Function logs
npx supabase functions logs powersync-token --follow

# Run Flutter app
flutter run
```

---

## Support Resources

- **PowerSync Docs:** https://docs.powersync.com/
- **PowerSync + Supabase Guide:** https://docs.powersync.com/integration-guides/supabase-+-powersync
- **PowerSync Dashboard:** https://powersync.journeyapps.com/
- **Supabase Dashboard:** https://supabase.com/dashboard
- **Discord/Support:** Check PowerSync docs for community links

---

## Questions?

If you encounter issues not covered here:

1. Check PowerSync Dashboard → Logs
2. Check Supabase Edge Function logs: `npx supabase functions logs powersync-token`
3. Run database health check: `SELECT * FROM check_powersync_health();`
4. Enable Flutter debug mode to see detailed PowerSync logs
5. Review CLAUDE.md for architecture context

---

**Created:** 2025-01-22
**Last Updated:** 2025-01-22
**Version:** 1.0
