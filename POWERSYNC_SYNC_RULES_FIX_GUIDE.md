# PowerSync Sync Rules Fix Guide

## Problem Summary

Your original `POWERSYNC_SYNC_RULES.yaml` file contained **120+ syntax errors** due to using SQL features that PowerSync doesn't support:

### What Doesn't Work in PowerSync ❌

1. **Subqueries in WHERE clauses**
   ```yaml
   # ❌ NOT SUPPORTED
   - SELECT * FROM users WHERE id IN (SELECT user_id FROM appointments WHERE ...)
   ```

2. **Bucket parameters in expressions**
   ```yaml
   # ❌ NOT SUPPORTED
   - SELECT * FROM records WHERE user_id IN (SELECT id FROM table WHERE x = bucket.user_id)
   ```

3. **Complex nested SELECT statements**
   ```yaml
   # ❌ NOT SUPPORTED
   - SELECT * FROM table1 WHERE col IN (SELECT x FROM table2 WHERE y IN (SELECT z FROM table3))
   ```

### What DOES Work in PowerSync ✅

1. **Simple WHERE with bucket parameters**
   ```yaml
   # ✅ SUPPORTED
   - SELECT * FROM users WHERE id = bucket.user_id
   ```

2. **Direct column comparisons**
   ```yaml
   # ✅ SUPPORTED
   - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id
   ```

3. **Materialized views with pre-computed joins**
   ```yaml
   # ✅ SUPPORTED (views handle complexity)
   - SELECT * FROM v_provider_accessible_patients WHERE provider_user_id = bucket.user_id
   ```

---

## The Solution

### 🎯 Strategy: Database Materialized Views

Instead of complex sync rules with subqueries, we:
1. Create **materialized views** in Supabase that pre-compute complex joins
2. Use **simple PowerSync sync rules** that query these views
3. **Refresh views periodically** (every 5-15 minutes) to keep data fresh

### Benefits

✅ **Works within PowerSync limitations** - Only simple queries
✅ **Maintains security** - Access control enforced at database level
✅ **Better performance** - Pre-computed joins, indexed properly
✅ **HIPAA compliant** - Proper role-based access control
✅ **Easy to audit** - Clear view of who can access what

---

## Files Created

### 1. `POWERSYNC_SYNC_RULES_FIXED.yaml` (Temporary/Basic)
- **Use**: Quick fix for testing
- **Scope**: Basic patient access only
- **Limitation**: No provider/facility admin/system admin support
- **When to use**: Testing PowerSync connection, understanding basics

### 2. `supabase/migrations/20250122000000_powersync_multi_role_views.sql` ⭐
- **Use**: Production-ready multi-role support
- **Contains**: 9 materialized views for all 4 roles
- **Must deploy**: Yes - required for complete sync rules

### 3. `POWERSYNC_SYNC_RULES_COMPLETE.yaml` ⭐ (RECOMMENDED)
- **Use**: Production sync rules with full multi-role support
- **Depends on**: Migration file above
- **Supports**: Patient, Provider, Facility Admin, System Admin
- **Deploy to**: PowerSync Dashboard

### 4. This guide
- **Use**: Step-by-step deployment instructions

---

## Deployment Steps

### Step 1: Apply Database Migration

This creates the materialized views in Supabase:

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Apply the migration
npx supabase db push
```

**Expected output:**
```
Applying migration 20250122000000_powersync_multi_role_views.sql...
Migration applied successfully ✓
```

---

### Step 2: Initial View Refresh

The views need to be populated with data before PowerSync can use them:

1. **Go to Supabase Dashboard** → SQL Editor
2. **Run this command:**

```sql
SELECT refresh_powersync_materialized_views();
```

**Expected output:**
```
refresh_powersync_materialized_views
------------------------------------

(1 row)
```

3. **Verify views were created:**

```sql
-- Check provider views
SELECT COUNT(*) FROM v_provider_accessible_patients;
SELECT COUNT(*) FROM v_provider_accessible_vital_signs;
SELECT COUNT(*) FROM v_provider_appointments;

-- Check facility admin views
SELECT COUNT(*) FROM v_facility_admin_accessible_appointments;
SELECT COUNT(*) FROM v_facility_admin_accessible_providers;
```

---

### Step 3: Set Up Automatic View Refresh

Materialized views need periodic refresh to stay current with data changes.

#### Option A: pg_cron Extension (Recommended for Supabase)

1. **Enable pg_cron** (if not already enabled):
   - Go to: Supabase Dashboard → Database → Extensions
   - Enable: `pg_cron`

2. **Schedule automatic refresh** (run in SQL Editor):

```sql
-- Refresh every 5 minutes
SELECT cron.schedule(
    'refresh-powersync-views',
    '*/5 * * * *',  -- Cron expression: every 5 minutes
    'SELECT refresh_powersync_materialized_views();'
);
```

3. **Verify schedule was created:**

```sql
SELECT * FROM cron.job WHERE jobname = 'refresh-powersync-views';
```

**Adjust frequency based on your needs:**
- `*/5 * * * *` - Every 5 minutes (recommended for active systems)
- `*/15 * * * *` - Every 15 minutes (less load, slightly stale data)
- `*/1 * * * *` - Every minute (high load, real-time needs)

#### Option B: Supabase Edge Function (Alternative)

If pg_cron is not available, create an Edge Function:

1. **Create the function:**

```bash
mkdir -p supabase/functions/refresh-powersync-views
```

2. **Create `supabase/functions/refresh-powersync-views/index.ts`:**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Call the refresh function
    const { error } = await supabase.rpc('refresh_powersync_materialized_views');

    if (error) throw error;

    return new Response(
      JSON.stringify({ success: true, refreshed_at: new Date().toISOString() }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
```

3. **Deploy the function:**

```bash
npx supabase functions deploy refresh-powersync-views
```

4. **Schedule it** using an external cron service like:
   - Cron-job.org
   - GitHub Actions (scheduled workflow)
   - Vercel Cron
   - AWS EventBridge

---

### Step 4: Deploy Sync Rules to PowerSync

1. **Copy the complete sync rules:**

```bash
cat POWERSYNC_SYNC_RULES_COMPLETE.yaml
```

2. **Go to PowerSync Dashboard:**
   - URL: `https://YOUR_INSTANCE.journeyapps.com/`
   - Navigate to: **Sync Rules**

3. **Paste the rules:**
   - Clear existing rules (if any)
   - Paste entire contents of `POWERSYNC_SYNC_RULES_COMPLETE.yaml`

4. **Validate:**
   - Click **Validate** button
   - **Should show: "✓ No errors"**

5. **Deploy:**
   - Click **Save**
   - Click **Deploy**
   - Wait for deployment confirmation

---

### Step 5: Test Each Role

#### Test as Patient

1. **Log in** as a user with patient role
2. **Check data access:**
   - Should see: Own medical records, appointments, profile
   - Should NOT see: Other patients' data, provider-only data

```dart
// In Flutter app
final vitalSigns = await executeQuery(
  'SELECT * FROM vital_signs',
  []
);
print('Patient can access ${vitalSigns.length} vital sign records');
// Should only return patient's own records
```

#### Test as Medical Provider

1. **Log in** as a user with provider role
2. **Check data access:**
   - Should see: Own profile, appointments, patients' data
   - Should NOT see: Unrelated patients, other providers' patients

```dart
// In Flutter app
final accessiblePatients = await executeQuery(
  'SELECT * FROM v_provider_accessible_patients',
  []
);
print('Provider can access ${accessiblePatients.length} patients');
```

#### Test as Facility Admin

1. **Log in** as facility admin
2. **Check data access:**
   - Should see: All facility appointments, providers, patients
   - Should NOT see: Other facilities' data

```dart
// In Flutter app
final facilityAppointments = await executeQuery(
  'SELECT * FROM v_facility_admin_accessible_appointments',
  []
);
print('Facility admin can access ${facilityAppointments.length} appointments');
```

#### Test as System Admin

1. **Log in** as system admin
2. **Check data access:**
   - Should see: ALL data across entire system

```dart
// In Flutter app
final allUsers = await executeQuery('SELECT * FROM users', []);
final allAppointments = await executeQuery('SELECT * FROM appointments', []);
print('System admin: ${allUsers.length} users, ${allAppointments.length} appointments');
```

---

### Step 6: Monitor Performance

#### Check View Refresh Time

```sql
-- See how long refreshes take
SELECT
    jobname,
    last_run,
    next_run,
    status
FROM cron.job_run_details
WHERE jobname = 'refresh-powersync-views'
ORDER BY start_time DESC
LIMIT 10;
```

#### Monitor PowerSync Sync Status

1. **Go to PowerSync Dashboard** → Metrics
2. **Check:**
   - Sync latency (should be < 5 seconds)
   - Active connections
   - Data transfer rates

#### Optimize if Needed

If view refreshes take too long:

1. **Add more indexes:**

```sql
-- Example: Index frequently filtered columns
CREATE INDEX idx_appointments_patient_scheduled
    ON appointments(patient_id, scheduled_start);
```

2. **Reduce refresh frequency** (e.g., every 15 minutes instead of 5)

3. **Use CONCURRENTLY for large tables:**

```sql
-- Already done in migration, but for reference:
REFRESH MATERIALIZED VIEW CONCURRENTLY v_provider_accessible_patients;
-- ^ Doesn't lock the view during refresh
```

---

## Troubleshooting

### Error: "Function token_parameters.user_id not defined"

**Cause:** Using old sync rules without parentheses
**Fix:** Use `token_parameters.user_id()` with parentheses

### Error: "Cannot use bucket parameters in expressions"

**Cause:** Bucket parameters in subqueries or complex expressions
**Fix:** Use materialized views (already implemented in `POWERSYNC_SYNC_RULES_COMPLETE.yaml`)

### Error: "Table ... not found"

**Cause:** Materialized views not created
**Fix:** Run Step 1 again (`npx supabase db push`)

### Error: "Select not supported here"

**Cause:** Subqueries in WHERE clause
**Fix:** Use `POWERSYNC_SYNC_RULES_COMPLETE.yaml` (already fixed)

### Views are empty

**Cause:** Views not refreshed after creation
**Fix:** Run Step 2 again (`SELECT refresh_powersync_materialized_views();`)

### Data is stale/not updating

**Cause:** Automatic refresh not set up
**Fix:** Complete Step 3 (set up cron job)

### PowerSync not syncing data

**Checks:**

1. **Verify PowerSync connection:**
   ```dart
   final status = getPowerSyncStatus();
   print('Connected: ${status.connected}');
   ```

2. **Check sync rules deployed:**
   - PowerSync Dashboard → Sync Rules
   - Should show your complete rules

3. **Verify token is valid:**
   ```bash
   # Test token function
   npx supabase functions invoke powersync-token \
     --headers "Authorization: Bearer YOUR_TOKEN"
   ```

4. **Check replication:**
   ```sql
   SELECT * FROM v_powersync_replication_status;
   -- Should show active slots
   ```

---

## Performance Considerations

### View Refresh Frequency

| Data Change Frequency | Recommended Refresh | Use Case |
|----------------------|-------------------|----------|
| Real-time critical | Every 1-2 minutes | ICU, Emergency Room |
| Active usage | Every 5 minutes | General clinic hours |
| Moderate usage | Every 15 minutes | Administrative tasks |
| Low usage | Every hour | Reports, analytics |

### Database Load

Each refresh runs 9 materialized view refreshes. Monitor:

```sql
-- Check database load
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Check table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename LIKE 'v_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Optimization Tips

1. **Index foreign keys:**
   ```sql
   CREATE INDEX IF NOT EXISTS idx_appointments_provider_id ON appointments(provider_id);
   CREATE INDEX IF NOT EXISTS idx_appointments_facility_id ON appointments(facility_id);
   CREATE INDEX IF NOT EXISTS idx_vital_signs_patient_id ON vital_signs(patient_id);
   ```

2. **Refresh during low-traffic periods** (if using manual scheduling)

3. **Use CONCURRENTLY** (already implemented) - doesn't lock tables

4. **Monitor and adjust** based on actual usage patterns

---

## Migration from Old Rules

If you already deployed the broken `POWERSYNC_SYNC_RULES.yaml`:

1. **Follow all steps above** (deployment is the same)
2. **No data migration needed** - PowerSync will automatically re-sync
3. **Users may need to re-login** once to get new sync rules
4. **Monitor sync status** for first hour after deployment

---

## Success Criteria

✅ **All steps completed without errors**
✅ **`npx supabase db push` succeeded**
✅ **Views populated with data** (`SELECT COUNT(*)` shows records)
✅ **Automatic refresh scheduled** (cron job active)
✅ **Sync rules deployed** to PowerSync Dashboard (no validation errors)
✅ **All 4 roles tested** (patient, provider, facility admin, system admin)
✅ **PowerSync status shows "connected"** in app
✅ **Data syncs correctly** for each role
✅ **No errors** in PowerSync Dashboard → Logs

---

## Need Help?

1. **Check logs:**
   - Supabase: Dashboard → Database → Logs
   - PowerSync: Dashboard → Logs
   - Flutter: Check `db.statusStream` output

2. **Review created files:**
   - `POWERSYNC_SYNC_RULES_COMPLETE.yaml` - Final sync rules
   - `supabase/migrations/20250122000000_powersync_multi_role_views.sql` - Views
   - This guide - Step-by-step instructions

3. **Verify prerequisites:**
   - Supabase database running
   - PowerSync instance active
   - `powersync-token` Edge Function deployed
   - Migration applied successfully

---

**Last Updated:** 2025-10-22
**Compatible with:** PowerSync SDK v1.0+, Supabase PostgreSQL 15+
