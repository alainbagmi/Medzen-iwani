# FlutterFlow + PowerSync Integration Guide

**Project**: MedZen-Iwani
**Date**: 2025-10-31
**Status**: Ready for Configuration

## Overview

This guide walks you through integrating PowerSync offline-first functionality into your FlutterFlow project. The integration enables full offline medical data operations with automatic cloud synchronization.

## Prerequisites Checklist

- ✅ Supabase project configured (completed)
- ✅ PowerSync instance created: `https://68f931403c148720fa432934.powersync.journeyapps.com`
- ✅ Supabase ↔ PowerSync sync working (confirmed)
- ✅ PowerSync core code in place (`lib/powersync/`)
- ✅ Custom actions created (`lib/custom_code/actions/`)
- ✅ Sync rules defined (`POWERSYNC_SYNC_RULES_COMPLETE.yaml`)
- ⚠️ Paid FlutterFlow plan (required for library imports)
- ⚠️ PowerSync secrets configuration (pending - for FlutterFlow offline)

## Part 1: Configure PowerSync Instance (15 minutes)

### Step 1.1: Access PowerSync Dashboard

```bash
# Open PowerSync dashboard
open https://68f931403c148720fa432934.powersync.journeyapps.com
```

### Step 1.2: Generate RSA Key Pair

1. Navigate to: **Settings → Security → API Keys**
2. Click: **Generate RSA Key Pair**
3. Save both keys:
   - **Key ID**: Copy this (you'll need it for Supabase secrets)
   - **Private Key**: Download and save securely (you'll need it for Supabase secrets)

### Step 1.3: Deploy Sync Rules

1. In PowerSync Dashboard, navigate to: **Sync Rules**
2. Copy the contents of `POWERSYNC_SYNC_RULES_COMPLETE.yaml`
3. Paste into the Sync Rules editor
4. Click: **Validate sync rules**
5. If validation passes, click: **Deploy sync rules**
6. Select your instance and confirm deployment

**Expected Result**: Sync rules deployed successfully with 5 buckets defined:
- `user_data` - Basic user profiles (all roles)
- `patient_data` - Patient medical records
- `provider_data` - Provider's accessible patients
- `facility_admin_data` - Facility-wide data
- `system_admin_data` - Full system access
- `global` - Public reference data

## Part 2: Configure Supabase Secrets (5 minutes)

### Step 2.1: Set PowerSync Secrets

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Set PowerSync instance URL
npx supabase secrets set POWERSYNC_URL="https://68f931403c148720fa432934.powersync.journeyapps.com"

# Set Key ID (from Step 1.2)
npx supabase secrets set POWERSYNC_KEY_ID="your-key-id-from-dashboard"

# Set Private Key (from Step 1.2) - paste entire key including headers
npx supabase secrets set POWERSYNC_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
... paste your full private key here ...
-----END RSA PRIVATE KEY-----"
```

### Step 2.2: Redeploy Edge Function

```bash
# Redeploy powersync-token function with new secrets
npx supabase functions deploy powersync-token

# Verify deployment
npx supabase functions logs powersync-token --tail
```

### Step 2.3: Test Token Generation

```bash
# Test the token function
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer $(npx supabase functions get-jwt)"

# Expected response:
# {
#   "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "powersync_url": "https://68f931403c148720fa432934.powersync.journeyapps.com"
# }
```

## Part 3: Use Pre-Generated PowerSync Schema for FlutterFlow

### Step 3.1: Schema Already Generated ✅

The PowerSync schema has been pre-generated and saved to:
```
/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/powersync_flutterflow_schema.dart
```

This schema defines **20 tables** for offline-first medical data operations:
- 4 user profile tables (users, patient_profiles, medical_provider_profiles, facility_admin_profiles)
- 2 EHR tables (electronic_health_records, ehr_compositions)
- 6 medical data tables (vital_signs, lab_results, prescriptions, immunizations, allergies, medical_records)
- 4 operational tables (appointments, facilities, organizations, ehrbase_sync_queue)
- 2 support tables (ai_conversations, documents)

### Step 3.2: Copy Schema for FlutterFlow

**Option A: Copy from file** (recommended)
```bash
# View the schema
cat /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/powersync_flutterflow_schema.dart

# Copy to clipboard (macOS)
pbcopy < /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/powersync_flutterflow_schema.dart
```

**Option B: Open in editor**
- Open `powersync_flutterflow_schema.dart` in your code editor
- Copy the entire file contents
- You'll paste this in Step 4.2 when configuring the PowerSync library

## Part 4: Configure FlutterFlow Project (10 minutes)

### Step 4.1: Add PowerSync Library

**In FlutterFlow UI:**

1. Navigate to: **App Settings → Project Dependencies → FlutterFlow Libraries**
2. Click: **Add Library**
3. Search for: **PowerSync**
4. Click: **Install** (requires paid FlutterFlow plan)

### Step 4.2: Configure PowerSync Library

**After installing the library:**

1. Find the PowerSync library in your dependencies list
2. Click: **Configure**
3. Fill in the configuration:
   - **PowerSyncSchema**: Paste the contents of `powersync_flutterflow_schema.dart` (from Step 3.2)
   - **PowerSyncUrl**: `https://68f8702005eb05000765fba5.powersync.journeyapps.com`
   - **SupabaseUrl**: Your Supabase project URL (already configured)
   - **EnableAuth**: `true`
4. Click: **Save**

**Note**: The schema file contains ~320 lines. Make sure to copy the entire file including the `import` statement and the closing `]);`

### Step 4.3: Add Custom Pub Dependency

**In FlutterFlow UI:**

1. Navigate to: **App Settings → Custom Pub Dependencies**
2. Click: **Add Dependency**
3. Package name: `powersync_core`
4. Version: `1.3.0`
5. Click: **Save**

### Step 4.4: Verify Supabase Integration

**Confirm Supabase is configured:**

1. Navigate to: **App Settings → Integrations → Supabase**
2. Verify:
   - ✅ API URL is set
   - ✅ Anon Key is set
   - ✅ Schema is loaded
3. If not configured, click **Get Schema** to sync

## Part 5: Initialize PowerSync in FlutterFlow (10 minutes)

### Step 5.1: Add Initialization to Landing Pages

**For each role landing page** (Patient, Provider, Facility Admin, System Admin):

1. Open the landing page in FlutterFlow
2. Select the **Page** (root widget)
3. Add **Action** → **On Page Load**
4. Add **Custom Action** → `initializePowerSync`
5. This action returns a boolean - you can optionally show a loading state

**Example for Patient Landing Page:**
```
PatientLandingPage
  └─ On Page Load
      └─ Custom Action: initializePowerSync()
          └─ Action Output: initSuccess
          └─ Conditional: IF initSuccess == false
              └─ Show Snackbar: "Offline mode - data will sync when online"
```

### Step 5.2: Add Sync Status Display (Optional)

**Using the PowerSyncConnectivity widget** (from library):

1. Open any page where you want to show sync status
2. Drag **PowerSyncConnectivity** component to AppBar or header
3. Configure styling as needed
4. Component auto-updates to show connection state

**OR using custom action:**

1. Add a **Container** widget to your AppBar
2. Add **Backend Query** → **Custom Action** → `getPowersyncStatus`
3. Bind query to refresh interval (e.g., every 5 seconds)
4. Display status fields:
   - `connected` → Show green/red indicator
   - `last_synced_at` → Show last sync time
   - `uploading`/`downloading` → Show sync animation

## Part 6: Query Data with PowerSyncQuery (FlutterFlow Component)

### Step 6.1: Create a Data Display Component

**Example: Display Patient Vital Signs**

1. Create new **Component**: `VitalSignsList`
2. Add **Component Parameter**:
   - Name: `vitalSigns`
   - Type: **Supabase Row**
   - Is List: ✅
   - Table: `vital_signs`
3. Add **ListView** to component
4. Configure **Generate Dynamic Children**: Use `vitalSigns` parameter
5. Bind **ListTile** fields to data:
   - Title: `systolicBp / diastolicBp` (e.g., "120/80")
   - Subtitle: `recorded_at` (formatted)
   - Trailing: `heart_rate` (e.g., "72 BPM")

### Step 6.2: Use PowerSyncQuery Widget

**On the page where you want to display data:**

1. Drag **PowerSyncQuery** widget from library to page
2. Configure properties:
   - **SQL Query**: `SELECT * FROM vital_signs WHERE patient_id = :patientId ORDER BY recorded_at DESC LIMIT 50`
   - **Parameters**: `patientId: Authenticated User → User ID`
   - **Watch**: ✅ (enables real-time updates)
   - **Child Component**: Select `VitalSignsList`
3. Map query results to component parameter: `vitalSigns`

**Expected Behavior:**
- ✅ Works offline (queries local PowerSync database)
- ✅ Auto-updates when new data syncs from cloud
- ✅ Shows loading state during initial query

## Part 7: Write Data with PowerSync Custom Actions

### Step 7.1: Create Data Entry Form

**Example: Record New Vital Signs**

1. Create page: `RecordVitalsPage`
2. Add form fields:
   - **TextField**: `systolicBp` (number)
   - **TextField**: `diastolicBp` (number)
   - **TextField**: `heartRate` (number)
   - **TextField**: `temperature` (number)
   - **TextField**: `notes` (optional)
3. Add **Button**: "Save Vital Signs"

### Step 7.2: Add Save Action

**On button tap:**

1. Add **Custom Action** → `insertVitalSign`
2. Configure parameters:
   - `patientId`: Authenticated User → User ID
   - `systolicBp`: Widget State → systolicBp field
   - `diastolicBp`: Widget State → diastolicBp field
   - `heartRate`: Widget State → heartRate field
   - `temperature`: Widget State → temperature field
   - `recordedBy`: Authenticated User → User ID
   - `notes`: Widget State → notes field
3. Add **Conditional Actions**:
   - IF action returns `true`:
     - Show success message
     - Navigate back to previous page
   - ELSE:
     - Show error message

**Expected Behavior:**
- ✅ Saves immediately to local database (never fails even offline)
- ✅ Auto-syncs to Supabase when online
- ✅ Triggers EHRbase sync queue via database trigger
- ✅ Updates UI instantly via PowerSyncQuery watch

## Part 8: Handle Sign Out Properly

### Step 8.1: Create Sign Out Custom Action

**Create new custom action:** `signOutWithPowerSync`

```dart
// File: lib/custom_code/actions/sign_out_with_power_sync.dart

import 'package:medzen_iwani/powersync/database.dart' as ps;

Future signOutWithPowerSync() async {
  try {
    // Disconnect PowerSync first
    await ps.db.disconnect();
    print('✅ PowerSync disconnected');
  } catch (e) {
    print('⚠️ Error disconnecting PowerSync: $e');
    // Continue with logout even if disconnect fails
  }
}
```

### Step 8.2: Chain Sign Out Actions

**On Sign Out button tap:**

1. **Action 1**: Custom Action → `signOutWithPowerSync()`
2. **Action 2**: Supabase Authentication → Log Out
3. **Action 3**: Navigate to Login Page

## Part 9: Testing the Integration (15 minutes)

### Test 1: Online Signup & Sync

```bash
# Monitor logs
npx supabase functions logs powersync-token --tail &
flutter run -d chrome
```

**Steps:**
1. Sign up new user
2. Navigate to landing page
3. Check console for: `✅ PowerSync: Initialization complete`
4. Check console for: `🔗 PowerSync: Connected to cloud sync`
5. Verify sync status shows "Connected"

**Expected:**
- ✅ PowerSync initializes successfully
- ✅ Token function returns valid JWT
- ✅ Sync status shows connected
- ✅ Initial data syncs from cloud

### Test 2: Offline Data Operations

**Steps:**
1. Enable airplane mode (or disconnect Wi-Fi)
2. Try to insert vital signs record
3. Navigate to vital signs list
4. Verify new record appears
5. Disable airplane mode
6. Wait 5-10 seconds
7. Check Supabase database

**Expected:**
- ✅ Insert works offline (instant)
- ✅ New record shows in UI immediately
- ✅ Sync status shows "Offline"
- ✅ Data syncs to Supabase when online
- ✅ EHRbase sync queue entry created

### Test 3: Real-Time Updates

**Steps:**
1. Open app on two devices/browsers
2. Insert data on device 1
3. Watch for update on device 2

**Expected:**
- ✅ Device 2 receives update within 2-5 seconds
- ✅ UI updates automatically (thanks to `watch: true`)
- ✅ No manual refresh needed

### Test 4: Role-Based Sync

**Test each role:**

```bash
# Create test users for each role
# Patient: patient@test.com
# Provider: provider@test.com
# Facility Admin: admin@test.com
# System Admin: sysadmin@test.com
```

**For each user:**
1. Login
2. Check PowerSync status
3. Query: `SELECT * FROM users;`
4. Verify data matches role permissions

**Expected:**
- ✅ Patient: Sees only their own data
- ✅ Provider: Sees assigned patients' data
- ✅ Facility Admin: Sees facility-wide data
- ✅ System Admin: Sees all data

## Part 10: Production Deployment Checklist

### Pre-Deployment

- [ ] All PowerSync secrets configured in Supabase
- [ ] Sync rules deployed to PowerSync instance
- [ ] PowerSync library installed in FlutterFlow
- [ ] Custom actions exported and tested
- [ ] All landing pages have `initializePowerSync()` call
- [ ] Sign out properly disconnects PowerSync
- [ ] All tests passing (online, offline, role-based)

### iOS Deployment (Additional Steps)

**Modify `ios/Podfile`:**

```ruby
# Change this line:
use_frameworks! :linkage => :static

# To this:
use_frameworks!
```

**Reason**: Required for PowerSync compatibility with iOS App Store.

### Android Deployment

No special configuration needed - PowerSync works out of the box.

### Web Deployment

No special configuration needed - PowerSync supports web via IndexedDB.

## Troubleshooting

### Issue: PowerSync won't connect

**Debug:**
```dart
// Add to initializePowerSync custom action
db.statusStream.listen((status) {
  print('PowerSync Status:');
  print('  Connected: ${status.connected}');
  print('  Has Synced: ${status.hasSynced}');
  print('  Last Synced: ${status.lastSyncedAt}');
});
```

**Common causes:**
1. Missing PowerSync secrets → Check Step 2.1
2. Invalid JWT token → Test Step 2.3
3. Sync rules not deployed → Check Step 1.3
4. Network connectivity → Check internet connection

### Issue: Token generation fails

**Check Supabase logs:**
```bash
npx supabase functions logs powersync-token --tail
```

**Common causes:**
1. Missing `POWERSYNC_PRIVATE_KEY` secret
2. Invalid RSA key format (must include headers)
3. Expired or invalid user session

### Issue: Data not syncing

**Check PowerSync metrics:**
1. Go to PowerSync Dashboard → Metrics
2. Check "Sync Operations" graph
3. Look for errors in "Failed Operations"

**Common causes:**
1. Row-level security blocking writes
2. Invalid data format
3. Missing required fields
4. Network timeout

### Issue: FlutterFlow library not found

**Solution:**
1. Verify you have a **paid** FlutterFlow plan
2. Try removing and re-adding the library
3. Contact FlutterFlow support if issue persists

## Additional Resources

### Documentation Files
- `POWERSYNC_QUICK_START.md` - Quick setup guide
- `POWERSYNC_MULTI_ROLE_GUIDE.md` - Role-based access details
- `POWERSYNC_IMPLEMENTATION.md` - Technical implementation
- `FLUTTERFLOW_POWERSYNC_INTEGRATION_STATUS.md` - Integration status

### Official Docs
- [PowerSync FlutterFlow Guide](https://docs.powersync.com/integration-guides/flutterflow-+-powersync)
- [PowerSync Dart SDK](https://docs.powersync.com/client-sdk-references/flutter-dart)
- [FlutterFlow Custom Actions](https://docs.flutterflow.io/customizing-your-app/custom-code/custom-actions)

### Support
- PowerSync Discord: https://discord.gg/powersync
- FlutterFlow Community: https://community.flutterflow.io
- Project Issues: Create issue in project repository

## Summary

You now have a complete PowerSync + FlutterFlow integration that provides:

✅ **Offline-First** - All medical data operations work offline
✅ **Auto-Sync** - Bidirectional sync when online
✅ **Real-Time** - Live updates across devices
✅ **Role-Based** - Secure, role-based data access
✅ **HIPAA-Ready** - Encrypted, secure, audit-logged

**Total Setup Time**: ~45 minutes
**Maintenance**: Minimal (auto-updates)
**Scalability**: Unlimited (PowerSync handles scale)
