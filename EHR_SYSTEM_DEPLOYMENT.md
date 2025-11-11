# Complete EHR System Deployment Guide

This guide walks you through deploying the complete offline-first EHR synchronization system for MedZen Iwani.

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Prerequisites](#prerequisites)
3. [Database Setup](#database-setup)
4. [Firebase Functions Setup](#firebase-functions-setup)
5. [Supabase Edge Functions Setup](#supabase-edge-functions-setup)
6. [Flutter App Configuration](#flutter-app-configuration)
7. [Testing the Complete Flow](#testing-the-complete-flow)
8. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)

## System Architecture

The complete EHR system consists of:

```
User Signup → Firebase Auth → Cloud Function → Supabase + EHRbase
                                    ↓
                            1. Create user in Supabase
                            2. Create EHR in EHRbase
                            3. Link in electronic_health_records table

User Updates Demographics → Database Trigger → Sync Queue → Edge Function → EHRbase
                                                    ↓
                                            Updates EHR_STATUS

Medical Records Created → Database Trigger → Sync Queue → Edge Function → EHRbase
                                                    ↓
                                            Creates Composition

Flutter App (Offline-First) → Monitors Connectivity → Triggers Sync → Edge Function
```

## Prerequisites

### Required Services
- Firebase project with Authentication enabled
- Supabase project with Database and Edge Functions
- EHRbase instance (v0.20.0+)
- Flutter SDK (>=3.0.0)
- Node.js 20 (for Firebase Functions)
- Deno (for Supabase Edge Functions)

### Required Credentials
- Firebase Admin SDK credentials
- Supabase service role key
- EHRbase URL, username, and password

## Database Setup

### Step 1: Run Supabase Migration

```bash
# Connect to your Supabase project
npx supabase link --project-ref YOUR_PROJECT_REF

# Run the migration
npx supabase db push
# OR manually run the migration file:
psql YOUR_SUPABASE_CONNECTION_STRING < supabase/migrations/20250121000001_enhanced_ehr_sync_system.sql
```

### Step 2: Verify Database Objects

Check that the following were created:

```sql
-- Check tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('ehrbase_sync_queue', 'electronic_health_records', 'users');

-- Check triggers
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public';

-- Expected triggers:
-- - trigger_queue_user_demographics_sync on users
-- - trigger_queue_vital_signs_sync on vital_signs
-- - trigger_queue_lab_results_sync on lab_results
-- - trigger_queue_prescriptions_sync on prescriptions

-- Check functions
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION';

-- Expected functions:
-- - queue_user_demographics_for_sync
-- - queue_vital_signs_for_sync
-- - queue_lab_results_for_sync
-- - queue_prescriptions_for_sync
-- - cleanup_old_sync_queue_entries
```

### Step 3: Verify Views

```sql
-- Check sync health view
SELECT * FROM v_sync_health_by_type;

-- Check sync status view
SELECT * FROM v_ehrbase_sync_status LIMIT 10;
```

## Firebase Functions Setup

### Step 1: Install Dependencies

```bash
cd firebase/functions
npm install
```

### Step 2: Configure Environment Variables

Set Firebase config values:

```bash
# Set Supabase credentials
firebase functions:config:set \
  supabase.url="https://YOUR_PROJECT.supabase.co" \
  supabase.service_key="YOUR_SUPABASE_SERVICE_ROLE_KEY"

# Set EHRbase credentials
firebase functions:config:set \
  ehrbase.url="https://your-ehrbase-instance.com" \
  ehrbase.username="ehrbase-user" \
  ehrbase.password="your-ehrbase-password"
```

**For local development**, create `.runtimeconfig.json`:

```json
{
  "supabase": {
    "url": "https://YOUR_PROJECT.supabase.co",
    "service_key": "YOUR_SUPABASE_SERVICE_ROLE_KEY"
  },
  "ehrbase": {
    "url": "http://localhost:8080",
    "username": "ehrbase-user",
    "password": "SuperSecretPassword"
  }
}
```

### Step 3: Test Locally (Optional)

```bash
# Start Firebase emulator
npm run serve

# In another terminal, trigger a test
firebase functions:shell
> onUserCreated({uid: 'test123', email: 'test@example.com'})
```

### Step 4: Deploy to Production

```bash
firebase deploy --only functions
```

### Step 5: Verify Deployment

Check Firebase Console:
- Go to Functions tab
- Verify `onUserCreated` and `onUserDeleted` are deployed
- Check logs for any errors

## Supabase Edge Functions Setup

### Step 1: Install Supabase CLI

```bash
# If not already installed
npm install -g supabase

# Login to Supabase
npx supabase login
```

### Step 2: Link Your Project

```bash
npx supabase link --project-ref YOUR_PROJECT_REF
```

### Step 3: Set Environment Variables

Create `.env` file for local development:

```bash
# supabase/.env
EHRBASE_URL=http://localhost:8080
EHRBASE_USERNAME=ehrbase-user
EHRBASE_PASSWORD=SuperSecretPassword
```

Set production secrets:

```bash
# Set secrets for production
npx supabase secrets set EHRBASE_URL=https://your-ehrbase-instance.com
npx supabase secrets set EHRBASE_USERNAME=ehrbase-user
npx supabase secrets set EHRBASE_PASSWORD=your-ehrbase-password
```

### Step 4: Test Locally (Optional)

```bash
# Start Supabase local development
npx supabase start

# Serve the edge function
npx supabase functions serve sync-to-ehrbase --env-file supabase/.env

# In another terminal, test it
curl -X POST http://localhost:54321/functions/v1/sync-to-ehrbase \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json"
```

### Step 5: Deploy to Production

```bash
npx supabase functions deploy sync-to-ehrbase
```

### Step 6: Verify Deployment

```bash
# Check function status
npx supabase functions list

# Test the deployed function
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json"
```

## Flutter App Configuration

### Step 1: Install Dependencies

```bash
flutter pub get
```

This will install the new `connectivity_plus` package.

### Step 2: Initialize EHR Sync in App

In your main app initialization (e.g., `lib/main.dart` or your landing page):

```dart
import 'package:medzen_iwani/custom_code/actions/initialize_ehr_sync.dart';

// In your app's init state or onLoad
@override
void initState() {
  super.initState();

  // Initialize EHR sync service
  initializeEHRSync();
}
```

**In FlutterFlow:**
1. Go to your main landing page (e.g., `HomePage`)
2. Add Action → Custom Code → `initializeEHRSync`
3. Trigger: On Page Load

### Step 3: Add Manual Sync Button (Optional)

Create a button to manually trigger sync:

```dart
import 'package:medzen_iwani/custom_code/actions/trigger_ehr_sync.dart';

ElevatedButton(
  onPressed: () async {
    await triggerEHRSync();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync triggered')),
    );
  },
  child: Text('Sync EHR Data'),
)
```

**In FlutterFlow:**
1. Add Button widget
2. Add Action → Custom Code → `triggerEHRSync`
3. Add Action → Show Snackbar → "Sync triggered"

### Step 4: Display Sync Status (Optional)

Show sync queue statistics:

```dart
import 'package:medzen_iwani/custom_code/actions/get_ehr_sync_stats.dart';

// In a FutureBuilder
FutureBuilder<Map<String, dynamic>>(
  future: getEHRSyncStats(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final stats = snapshot.data!;
    return Column(
      children: [
        Text('Pending: ${stats['pending']}'),
        Text('Completed: ${stats['completed']}'),
        Text('Failed: ${stats['failed']}'),
      ],
    );
  },
)
```

## Testing the Complete Flow

### Test 1: User Creation

**Objective:** Verify that a new user gets an EHR automatically.

```bash
# 1. Create a test user via Firebase Auth
# (Use Firebase Console or your app's signup flow)

# 2. Check Firebase Functions logs
firebase functions:log

# Expected output:
# - "Creating user record for Firebase UID: ..."
# - "User created in Supabase with ID: ..."
# - "Creating EHR in EHRbase..."
# - "EHR created in EHRbase with ID: ..."
# - "Successfully created complete user record with EHR for ..."

# 3. Verify in Supabase
# Check users table
SELECT id, firebase_uid, email, created_at FROM users
WHERE firebase_uid = 'YOUR_TEST_UID';

# Check electronic_health_records table
SELECT * FROM electronic_health_records
WHERE patient_id = 'YOUR_SUPABASE_USER_ID';

# 4. Verify in EHRbase
# Use EHRbase REST API or UI to check that the EHR exists
curl https://your-ehrbase.com/rest/openehr/v1/ehr/YOUR_EHR_ID \
  -u ehrbase-user:password
```

### Test 2: Demographic Update Sync

**Objective:** Verify that updating user demographics triggers EHR_STATUS sync.

```bash
# 1. Update user demographics in Supabase
UPDATE users
SET first_name = 'John',
    last_name = 'Doe',
    date_of_birth = '1990-01-01',
    gender = 'male'
WHERE id = 'YOUR_USER_ID';

# 2. Check sync queue was created
SELECT * FROM ehrbase_sync_queue
WHERE table_name = 'users_demographics'
AND record_id = 'YOUR_USER_ID';

# Expected:
# - sync_type = 'ehr_status_update'
# - sync_status = 'pending'
# - data_snapshot contains demographic data

# 3. Trigger the sync function
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"

# 4. Check sync queue was updated
SELECT sync_status, processed_at FROM ehrbase_sync_queue
WHERE table_name = 'users_demographics'
AND record_id = 'YOUR_USER_ID';

# Expected:
# - sync_status = 'completed'
# - processed_at is set

# 5. Verify in EHRbase that EHR_STATUS was updated
curl https://your-ehrbase.com/rest/openehr/v1/ehr/YOUR_EHR_ID/ehr_status \
  -u ehrbase-user:password
```

### Test 3: Medical Record Sync

**Objective:** Verify vital signs create compositions in EHRbase.

```bash
# 1. Insert a vital signs record
INSERT INTO vital_signs (
  patient_id,
  systolic_bp,
  diastolic_bp,
  heart_rate,
  temperature,
  recorded_at
) VALUES (
  'YOUR_USER_ID',
  120,
  80,
  72,
  36.5,
  NOW()
) RETURNING id;

# 2. Check sync queue
SELECT * FROM ehrbase_sync_queue
WHERE table_name = 'vital_signs';

# 3. Trigger sync
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"

# 4. Check completion
SELECT sync_status, ehrbase_composition_id FROM ehrbase_sync_queue
WHERE table_name = 'vital_signs'
ORDER BY created_at DESC LIMIT 1;

# 5. Query compositions in EHRbase
curl https://your-ehrbase.com/rest/openehr/v1/ehr/YOUR_EHR_ID/composition \
  -u ehrbase-user:password
```

### Test 4: Offline-First Sync (Flutter)

**Objective:** Verify offline queueing and auto-sync on reconnect.

1. **Enable Airplane Mode** on your device/emulator
2. **Update user profile** (first name, last name, etc.)
3. **Verify queue entry** was created in `ehrbase_sync_queue`
4. **Disable Airplane Mode**
5. **Wait 10-15 seconds** (or pull to refresh if implemented)
6. **Check logs** for sync activity
7. **Verify in database** that sync_status changed to 'completed'

### Test 5: Retry Failed Items

**Objective:** Verify retry logic for failed sync items.

```bash
# 1. Manually mark an item as failed
UPDATE ehrbase_sync_queue
SET sync_status = 'failed',
    retry_count = 2,
    error_message = 'Simulated error'
WHERE id = 'SOME_QUEUE_ITEM_ID';

# 2. Use Flutter app to retry
# Call retryFailedEHRSync() action

# 3. Check that item was retried
SELECT sync_status, retry_count FROM ehrbase_sync_queue
WHERE id = 'SOME_QUEUE_ITEM_ID';
```

## Monitoring and Troubleshooting

### Check Sync Health

```sql
-- Overall sync health
SELECT * FROM v_sync_health_by_type;

-- Failed items that need attention
SELECT * FROM ehrbase_sync_queue
WHERE sync_status = 'failed'
AND retry_count >= 5;

-- Pending items older than 1 hour
SELECT * FROM ehrbase_sync_queue
WHERE sync_status = 'pending'
AND created_at < NOW() - INTERVAL '1 hour';
```

### Common Issues

#### 1. EHR Not Created on Signup

**Symptoms:** User created in Supabase but no EHR in electronic_health_records.

**Check:**
```bash
# Check Firebase logs
firebase functions:log --only onUserCreated

# Common causes:
# - EHRbase URL incorrect
# - EHRbase credentials wrong
# - EHRbase service down
# - Network connectivity issues
```

**Fix:**
- Verify EHRbase configuration in Firebase config
- Test EHRbase connectivity manually
- Check EHRbase logs

#### 2. Sync Queue Items Stuck in Pending

**Symptoms:** Items remain in 'pending' status for extended time.

**Check:**
```sql
SELECT * FROM ehrbase_sync_queue
WHERE sync_status = 'pending'
ORDER BY created_at DESC;
```

**Fix:**
```bash
# Manually trigger sync
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"

# Check edge function logs
npx supabase functions logs sync-to-ehrbase
```

#### 3. Failed Items with Max Retries

**Symptoms:** Items have retry_count >= 5 and sync_status = 'failed'.

**Check:**
```sql
SELECT id, table_name, record_id, error_message, retry_count
FROM ehrbase_sync_queue
WHERE sync_status = 'failed'
AND retry_count >= 5;
```

**Fix:**
- Review error_message to understand the issue
- Fix the underlying problem (e.g., invalid data, EHRbase schema mismatch)
- Reset retry count to retry:

```sql
UPDATE ehrbase_sync_queue
SET sync_status = 'pending',
    retry_count = 0,
    error_message = NULL
WHERE id = 'PROBLEMATIC_ITEM_ID';
```

### Cleanup Old Entries

Run periodically to prevent table bloat:

```sql
SELECT cleanup_old_sync_queue_entries();
```

Set up a cron job or scheduled function to run this weekly.

## Performance Optimization

### Database Indexes

The migration already creates these indexes, but verify:

```sql
-- Check indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'ehrbase_sync_queue';

-- Expected indexes:
-- - idx_ehrbase_sync_queue_type_status
-- - idx_ehrbase_sync_queue_pending
-- - unique_table_record_sync (unique constraint)
```

### Edge Function Batching

The edge function processes 50 items per invocation. Adjust in code if needed:

```typescript
// In supabase/functions/sync-to-ehrbase/index.ts
.limit(50) // Increase for higher throughput
```

### Sync Frequency

Adjust Flutter app sync frequency:

```dart
// In lib/custom_code/actions/ehr_sync_service.dart
_syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
  // Change Duration as needed
  triggerSync();
});
```

## Security Considerations

1. **Never expose service role keys** in client code
2. **Use Row-Level Security** in Supabase for all tables
3. **Validate data** before syncing to EHRbase
4. **Rotate credentials** regularly
5. **Monitor logs** for suspicious activity

## Next Steps

1. Set up monitoring and alerting for failed sync items
2. Implement retry with exponential backoff
3. Add sync analytics/dashboards
4. Set up automated backup of EHRbase data
5. Implement data archival strategy for old sync queue entries

## Support

For issues or questions:
- Check Firebase Functions logs: `firebase functions:log`
- Check Supabase Edge Functions logs: `npx supabase functions logs`
- Review error messages in `ehrbase_sync_queue.error_message`
- Consult EHRbase documentation: https://ehrbase.org/
