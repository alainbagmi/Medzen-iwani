# Connect Supabase to PowerSync - Complete Guide

## Overview

PowerSync needs to connect to your Supabase database to sync data bidirectionally. Here's what we'll set up:

```
Supabase Database ←→ PowerSync Instance ←→ Flutter App (SQLite)
```

## Prerequisites

- ✅ Supabase project: `noaeltglphdlkbflipit`
- ✅ PowerSync instance: `687fe5badb7a810007220898`
- ⏳ Connection credentials (we'll get these)

## Step-by-Step Connection

### Step 1: Get Supabase Connection Details

You need these from your Supabase project:

1. **Go to Supabase Dashboard:**
   https://supabase.com/dashboard/project/noaeltglphdlkbflipit

2. **Get Database URL:**
   - Go to **Settings** → **Database**
   - Copy **Connection string** (URI format)
   - It looks like: `postgresql://postgres:[YOUR-PASSWORD]@db.noaeltglphdlkbflipit.supabase.co:5432/postgres`

3. **Get Database Password:**
   - You set this when creating the project
   - If forgotten, reset it in **Settings** → **Database** → **Reset Database Password**

4. **Get Direct Connection String:**
   - In **Settings** → **Database**
   - Under **Connection string**, select **URI** tab
   - Copy the full string

### Step 2: Configure PowerSync to Connect to Supabase

1. **Open PowerSync Dashboard:**
   https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898

2. **Navigate to Instance Settings:**
   - Click on your instance
   - Go to **Settings** or **Configuration**

3. **Add Database Connection:**
   - Look for **Database** or **Data Source** settings
   - Click **Add Connection** or **Configure Database**

4. **Enter Supabase Connection Details:**
   ```
   Connection Type: PostgreSQL
   Host: db.noaeltglphdlkbflipit.supabase.co
   Port: 5432
   Database: postgres
   Username: postgres
   Password: [YOUR-SUPABASE-PASSWORD]
   SSL Mode: require
   ```

   Or use the full connection string:
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.noaeltglphdlkbflipit.supabase.co:5432/postgres
   ```

5. **Test Connection:**
   - Click **Test Connection**
   - Should see ✅ Success

6. **Save Configuration**

### Step 3: Configure Sync Rules

PowerSync needs to know which data to sync. Create sync rules:

1. **In PowerSync Dashboard, go to Sync Rules**

2. **Paste this configuration:**

```yaml
# PowerSync Sync Rules for MedZen
# Defines which data syncs to each user

bucket_definitions:
  # User's personal medical data bucket
  user_data:
    # Parameters: Get the user's Supabase ID based on their Firebase UID
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()

    # Data to sync for this user
    data:
      # User's own profile
      - SELECT * FROM users WHERE id = bucket.user_id

      # User's EHR record
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

      # User's sync queue items
      - SELECT * FROM ehrbase_sync_queue
        WHERE table_name = 'users_demographics'
        AND record_id = bucket.user_id::text
        OR table_name IN ('vital_signs', 'lab_results', 'prescriptions', 'immunizations', 'medical_records')
        AND record_id IN (
          SELECT id::text FROM vital_signs WHERE patient_id = bucket.user_id
          UNION SELECT id::text FROM lab_results WHERE patient_id = bucket.user_id
          UNION SELECT id::text FROM prescriptions WHERE patient_id = bucket.user_id
          UNION SELECT id::text FROM immunizations WHERE patient_id = bucket.user_id
          UNION SELECT id::text FROM medical_records WHERE patient_id = bucket.user_id
        )

# Global parameters available to all queries
parameters:
  # Extract user_id from JWT token's 'sub' claim
  user_id: SELECT request.jwt() ->> 'sub'
```

3. **Click Save** or **Deploy**

4. **Test Sync Rules:**
   - Use the built-in **Test** feature
   - Enter a test Firebase UID
   - Verify it returns expected data

### Step 4: Configure Supabase for PowerSync

PowerSync needs certain Supabase configurations:

#### A. Enable Supabase Realtime (for efficient sync)

In Supabase Dashboard:

1. Go to **Database** → **Replication**
2. Enable replication for these tables:
   - ✅ users
   - ✅ electronic_health_records
   - ✅ vital_signs
   - ✅ lab_results
   - ✅ prescriptions
   - ✅ immunizations
   - ✅ medical_records
   - ✅ ehrbase_sync_queue

#### B. Grant PowerSync User Permissions

Run this SQL in Supabase SQL Editor:

```sql
-- Create a dedicated user for PowerSync (if not using default postgres user)
-- CREATE USER powersync_user WITH PASSWORD 'your-secure-password';

-- Grant necessary permissions to PowerSync user
GRANT USAGE ON SCHEMA public TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Grant permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO postgres;

-- Enable Row Level Security bypass for PowerSync (it handles security via sync rules)
-- Note: Be cautious with this in production
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE electronic_health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE vital_signs ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE immunizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE ehrbase_sync_queue ENABLE ROW LEVEL SECURITY;

-- Create policy to allow PowerSync to read all data (sync rules filter per user)
CREATE POLICY "PowerSync read all" ON users FOR SELECT TO postgres USING (true);
CREATE POLICY "PowerSync read all" ON electronic_health_records FOR SELECT TO postgres USING (true);
CREATE POLICY "PowerSync read all" ON vital_signs FOR SELECT TO postgres USING (true);
CREATE POLICY "PowerSync read all" ON lab_results FOR SELECT TO postgres USING (true);
CREATE POLICY "PowerSync read all" ON prescriptions FOR SELECT TO postgres USING (true);
CREATE POLICY "PowerSync read all" ON immunizations FOR SELECT TO postgres USING (true);
CREATE POLICY "PowerSync read all" ON medical_records FOR SELECT TO postgres USING (true);
CREATE POLICY "PowerSync read all" ON ehrbase_sync_queue FOR SELECT TO postgres USING (true);
```

### Step 5: Verify Connection

#### A. Check PowerSync Dashboard

In PowerSync Dashboard:

1. Go to **Metrics** or **Status**
2. Look for:
   - ✅ Database: Connected
   - ✅ Sync Status: Active
   - ✅ Last Sync: Recent timestamp

#### B. Test Data Flow

1. **Insert test data in Supabase:**

```sql
-- In Supabase SQL Editor
INSERT INTO users (id, firebase_uid, email, first_name, last_name, created_at)
VALUES (
  gen_random_uuid(),
  'test-firebase-uid-123',
  'test@example.com',
  'Test',
  'User',
  NOW()
);
```

2. **Check PowerSync Dashboard:**
   - Go to **Data** or **Explorer**
   - Search for the test user
   - Should appear within seconds

#### C. Check Sync Metrics

In PowerSync Dashboard → **Metrics**:

- **Sync Latency:** Should be < 1 second
- **Error Rate:** Should be 0%
- **Data Volume:** Should show records syncing

### Step 6: Troubleshooting

#### Issue: "Connection Failed"

**Possible causes:**
- ❌ Wrong password
- ❌ Incorrect host/port
- ❌ SSL not enabled

**Solutions:**
1. Verify connection string is correct
2. Check password (try resetting in Supabase)
3. Ensure SSL mode is set to `require`
4. Test connection from your local machine:
   ```bash
   psql "postgresql://postgres:[PASSWORD]@db.noaeltglphdlkbflipit.supabase.co:5432/postgres"
   ```

#### Issue: "Sync Rules Error"

**Possible causes:**
- ❌ Syntax error in YAML
- ❌ Table doesn't exist
- ❌ Missing permissions

**Solutions:**
1. Validate YAML syntax
2. Verify all tables exist in Supabase
3. Check SQL queries run correctly in Supabase SQL Editor
4. Use PowerSync's **Test** feature to debug

#### Issue: "No Data Syncing"

**Possible causes:**
- ❌ Replication not enabled
- ❌ RLS blocking PowerSync
- ❌ Sync rules too restrictive

**Solutions:**
1. Enable replication for all tables
2. Check RLS policies allow PowerSync user
3. Test sync rules with known data
4. Check PowerSync logs for errors

## Connection Checklist

Before proceeding, verify:

- [ ] Supabase database connection string obtained
- [ ] PowerSync configured with Supabase connection
- [ ] Connection test successful in PowerSync
- [ ] Sync rules configured and deployed
- [ ] Supabase replication enabled for all tables
- [ ] RLS policies configured
- [ ] Test data synced successfully
- [ ] Metrics showing active sync

## What Happens Next

Once connected:

1. **PowerSync monitors Supabase** for changes
2. **Changes replicate** to PowerSync in real-time
3. **Flutter apps sync** from PowerSync
4. **Local changes** upload through PowerSync to Supabase
5. **Bidirectional sync** maintains consistency

## Architecture Flow

```
User creates record in Flutter
         ↓
PowerSync Local SQLite
         ↓
PowerSync Upload Queue
         ↓
PowerSync Instance
         ↓
Supabase Database
         ↓
Database Trigger
         ↓
ehrbase_sync_queue
         ↓
Edge Function
         ↓
EHRbase
```

## Next Steps

After connection is complete:

1. ✅ **Deploy PowerSync token function** (for JWT generation)
2. ✅ **Initialize PowerSync in Flutter app**
3. ✅ **Test offline writes**
4. ✅ **Monitor sync in dashboard**

---

**Need Help?**

If you get stuck at any step, let me know:
- Which step you're on
- What error you're seeing
- I'll help you troubleshoot!

**Your Details:**
- Supabase Project: `noaeltglphdlkbflipit`
- PowerSync Instance: `687fe5badb7a810007220898`
- Dashboard: https://powersync.journeyapps.com/org/687fe5b9be0f9c000799e9c5/app/687fe5badb7a810007220898
