# FlutterFlow PowerSync Integration Guide
## MedZen-Iwani Healthcare Application

**Date:** October 22, 2025
**Status:** ✅ **COMPLETE** - FlutterFlow integration ready for use
**Purpose:** Enable offline-first database operations in FlutterFlow visual interface

---

## Overview

This guide explains how to use PowerSync from FlutterFlow's visual interface using the custom actions we've created. PowerSync provides offline-first database operations with automatic bidirectional sync to Supabase.

**Key Benefits:**
- ✅ 100% offline-capable CRUD operations
- ✅ Automatic sync when online
- ✅ Real-time data streaming
- ✅ No manual sync management required
- ✅ Works for all 4 user roles (Patient, Provider, Facility Admin, System Admin)

---

## Prerequisites

Before using PowerSync in FlutterFlow, ensure:

1. **PowerSync Cloud Instance Configured**
   - Account created at powersync.journeyapps.com
   - Instance URL obtained
   - Sync rules deployed

2. **Supabase Edge Function Deployed**
   - `powersync-token` function deployed
   - Environment secrets set (POWERSYNC_URL, POWERSYNC_KEY_ID, POWERSYNC_PRIVATE_KEY)

3. **FlutterFlow Project Exported**
   - Project exported with custom code enabled
   - Dependencies installed (`flutter pub get`)

**See POWERSYNC_IMPLEMENTATION_SUMMARY.md for setup details**

---

## Available Custom Actions

FlutterFlow PowerSync integration provides 6 custom actions:

### 1. Initialize PowerSync
**Action Name:** `initializePowerSyncAction`
**When to Use:** On app startup (initial landing page "On Page Load" action)
**Parameters:** None
**Returns:** Nothing (void)

**Usage:**
```
Page: Initial Landing Page (after auth check)
Action Flow:
  → On Page Load
    → Custom Action: initializePowerSyncAction()
    → Navigate to: Home
```

**CRITICAL:** Must be called AFTER Firebase and Supabase initialization.

---

### 2. Query Data (One-Time)
**Action Name:** `powerSyncQueryAction`
**When to Use:** Fetch data once (e.g., on button click, page load)
**Parameters:**
- `sql` (String): SQL SELECT query
- `parameters` (List<dynamic>): Query parameters (optional)

**Returns:** `List<Map<String, dynamic>>` - List of records

**FlutterFlow Setup:**
1. Add Custom Action → powerSyncQueryAction
2. Set sql parameter: `"SELECT * FROM vital_signs WHERE patient_id = ? ORDER BY recorded_at DESC LIMIT 10"`
3. Set parameters: `[FFAppState().userId]`
4. Store result in Action Output Variable: `vitalSignsResult`
5. Use in ListView: `vitalSignsResult[index]['systolic_bp']`

**Example Use Cases:**
- Load patient profile on page load
- Search medical records on button click
- Get appointment details for display
- Count records for dashboard stats

---

### 3. Watch Query (Real-Time Stream)
**Action Name:** `powerSyncWatchQueryAction`
**When to Use:** Display data that updates automatically
**Parameters:**
- `sql` (String): SQL SELECT query
- `parameters` (List<dynamic>): Query parameters (optional)

**Returns:** `Stream<List<Map<String, dynamic>>>` - Continuous updates

**FlutterFlow Setup:**
1. Add StreamBuilder widget to page
2. Set stream source: Custom Action → powerSyncWatchQueryAction
3. Set sql parameter: `"SELECT * FROM appointments WHERE patient_id = ? AND status = 'pending'"`
4. Set parameters: `[FFAppState().userId]`
5. Access data in builder: `snapshot.data[index]['appointment_date']`

**Example Use Cases:**
- Real-time vital signs dashboard
- Live appointment list (updates when modified)
- Notification counter badge
- Active prescriptions list

**Differences from Query:**

| Feature | Query Action | Watch Query Action |
|---------|-------------|-------------------|
| Return Type | Future (one-time) | Stream (continuous) |
| Updates | Manual refresh | Automatic |
| Use Case | Static data | Dynamic data |
| Performance | Faster | Slight overhead |

---

### 4. Write Data
**Action Name:** `powerSyncWriteAction`
**When to Use:** Create, update, or delete records
**Parameters:**
- `sql` (String): INSERT, UPDATE, or DELETE statement
- `parameters` (List<dynamic>): Statement parameters (optional)

**Returns:** Nothing (void) - throws error on failure

**FlutterFlow Setup:**

#### INSERT Example (Create New Record)
```
Action Flow (on Save Button):
  → Custom Action: powerSyncWriteAction
    sql: "INSERT INTO vital_signs (id, patient_id, systolic_bp, diastolic_bp, heart_rate, recorded_at) VALUES (?, ?, ?, ?, ?, ?)"
    parameters: [
      FFAppState().generateUuid(),
      FFAppState().userId,
      systolicBpField,
      diastolicBpField,
      heartRateField,
      getCurrentTimestamp.toString()
    ]
  → Show Snackbar: "Vital signs saved"
  → Navigate Back
```

#### UPDATE Example (Modify Existing)
```
Action Flow (on Update Button):
  → Custom Action: powerSyncWriteAction
    sql: "UPDATE appointments SET status = ?, updated_at = ? WHERE id = ?"
    parameters: [
      "completed",
      getCurrentTimestamp.toString(),
      appointmentId
    ]
  → Show Snackbar: "Appointment updated"
```

#### DELETE Example (Remove Record)
```
Action Flow (on Delete Button with confirmation):
  → Show Alert Dialog: "Delete prescription?"
    On Confirm:
      → Custom Action: powerSyncWriteAction
        sql: "DELETE FROM prescriptions WHERE id = ?"
        parameters: [prescriptionId]
      → Show Snackbar: "Prescription deleted"
      → Navigate Back
```

**Important Notes:**
- All writes succeed instantly, even offline
- Data automatically syncs to Supabase when online
- Use UUIDs for IDs (generate with `FFAppState().generateUuid()`)
- Always include timestamps for audit trail

---

### 5. Check Connection Status
**Action Name:** `powerSyncIsConnectedAction`
**When to Use:** Show online/offline indicators
**Parameters:** None
**Returns:** `bool` - true if online, false if offline

**FlutterFlow Setup:**

#### Connection Indicator Badge
```
Widget: Container
  Visibility: Conditional
    Condition: powerSyncIsConnectedAction() == false
    Child: Badge
      Text: "Offline"
      Color: Orange
```

#### Conditional Action Flow
```
Action Flow (on Sync Button):
  → Custom Action: isOnline = powerSyncIsConnectedAction()
  → Conditional:
    IF isOnline == true:
      → Show Snackbar: "✅ Online - Syncing..."
    ELSE:
      → Show Snackbar: "📴 Offline - Changes saved locally"
```

---

### 6. Get Detailed Status
**Action Name:** `powerSyncGetStatusAction`
**When to Use:** Show detailed sync information
**Parameters:** None
**Returns:** `Map<String, dynamic>` with fields:
- `connected` (bool): Connected to cloud
- `downloading` (bool): Currently downloading
- `uploading` (bool): Currently uploading
- `lastSyncedAt` (String?): ISO 8601 timestamp of last sync
- `hasSynced` (bool): Has completed at least one sync

**FlutterFlow Setup:**
```
Action Flow (on Refresh Button):
  → Custom Action: status = powerSyncGetStatusAction()
  → Set Local State:
    statusText = IF status['connected']:
                   IF status['uploading']: "⬆️ Uploading changes..."
                   ELSE IF status['downloading']: "⬇️ Downloading updates..."
                   ELSE: "✅ Synced at {status['lastSyncedAt']}"
                 ELSE: "📴 Offline - Changes saved locally"
  → Update UI with statusText
```

---

## Common Patterns

### Pattern 1: CRUD Page with Real-Time List

**Scenario:** Vital signs page with list and add form

**Page Structure:**
1. StreamBuilder → powerSyncWatchQueryAction (live list)
2. Form fields (systolic BP, diastolic BP, heart rate)
3. Save button → powerSyncWriteAction (INSERT)
4. Delete icon per item → powerSyncWriteAction (DELETE)

**Why This Works:**
- StreamBuilder shows real-time list
- When user adds new vital sign (INSERT), StreamBuilder automatically updates
- When user deletes item (DELETE), StreamBuilder removes it from list
- No manual refresh needed!

---

### Pattern 2: Offline-Capable Form

**Scenario:** Appointment booking that works offline

**Action Flow (on Book Button):**
```
1. Custom Action: isOnline = powerSyncIsConnectedAction()
2. Custom Action: powerSyncWriteAction
   sql: "INSERT INTO appointments (...) VALUES (...)"
   parameters: [...]
3. Show Snackbar:
   IF isOnline:
     "✅ Appointment booked and synced"
   ELSE:
     "📴 Appointment saved - Will sync when online"
4. Navigate Back
```

**Why This Works:**
- Works identically online and offline
- User gets appropriate feedback based on connection
- Data automatically syncs when device comes online

---

### Pattern 3: Search with Filter

**Scenario:** Search medical records with date range

**Page Elements:**
1. Search field (patientName)
2. Date pickers (startDate, endDate)
3. Search button
4. Results list (displays searchResults)

**Action Flow (on Search Button):**
```
1. Custom Action: searchResults = powerSyncQueryAction
   sql: "SELECT * FROM medical_records WHERE patient_name LIKE ? AND created_at BETWEEN ? AND ? ORDER BY created_at DESC"
   parameters: [
     "%${patientName}%",
     startDate.toString(),
     endDate.toString()
   ]
2. Update State: searchResults
3. ListView displays searchResults
```

---

### Pattern 4: Dashboard Counters

**Scenario:** Dashboard showing counts that update real-time

**Widget Structure:**
```
Row:
  - Card (Pending Appointments)
    StreamBuilder → powerSyncWatchQueryAction
      sql: "SELECT COUNT(*) as count FROM appointments WHERE status = 'pending' AND patient_id = ?"
      parameters: [userId]
      Display: snapshot.data[0]['count']

  - Card (Active Prescriptions)
    StreamBuilder → powerSyncWatchQueryAction
      sql: "SELECT COUNT(*) as count FROM prescriptions WHERE status = 'active' AND patient_id = ?"
      parameters: [userId]
      Display: snapshot.data[0]['count']

  - Card (Recent Labs)
    StreamBuilder → powerSyncWatchQueryAction
      sql: "SELECT COUNT(*) as count FROM lab_results WHERE created_at > ? AND patient_id = ?"
      parameters: [sevenDaysAgo, userId]
      Display: snapshot.data[0]['count']
```

**Why This Works:**
- Counts update automatically when data changes
- Single query per card (efficient)
- No polling or manual refresh needed

---

## SQL Query Guidelines

### Table Names
All medical data tables available in PowerSync:

**Patient Data:**
- `vital_signs` - Blood pressure, heart rate, temperature
- `prescriptions` - Medications and dosages
- `lab_results` - Lab test results
- `immunizations` - Vaccination records
- `medical_records` - General medical history

**Appointments & Scheduling:**
- `appointments` - Patient-provider appointments
- `appointment_slots` - Available time slots

**Users & Profiles:**
- `users` - Basic user information
- `patient_profiles` - Extended patient information
- `provider_profiles` - Medical provider details

**See lib/powersync/schema.dart for complete list and field names**

### Common Columns
Most tables include:
- `id` (UUID): Primary key
- `created_at` (DateTime): Record creation time
- `updated_at` (DateTime): Last modification time
- `created_by` (UUID): User who created record

**Role-Specific Filters:**
- Patient role: `patient_id = FFAppState().userId`
- Provider role: `provider_id = FFAppState().userId` OR `assigned_to = FFAppState().userId`
- Facility Admin: `facility_id = FFAppState().userFacilityId`
- System Admin: No filter (sees all data)

### SQL Best Practices

**✅ DO:**
```sql
-- Use parameterized queries (prevents SQL injection)
"SELECT * FROM vital_signs WHERE patient_id = ?"
parameters: [userId]

-- Use LIMIT for large result sets
"SELECT * FROM medical_records WHERE patient_id = ? ORDER BY created_at DESC LIMIT 50"

-- Use specific columns instead of * (better performance)
"SELECT id, systolic_bp, diastolic_bp, recorded_at FROM vital_signs WHERE patient_id = ?"

-- Use timestamps in ISO 8601 format
getCurrentTimestamp.toString()  // "2025-10-22T10:30:00.000Z"
```

**❌ DON'T:**
```sql
-- Never concatenate user input (SQL injection risk!)
"SELECT * FROM vital_signs WHERE patient_id = '${userId}'"  // UNSAFE!

-- Don't fetch unlimited rows
"SELECT * FROM medical_records"  // Could return thousands of rows

-- Don't use raw dates without timezone
"2025-10-22"  // Use ISO 8601 with timezone instead
```

---

## Testing PowerSync Integration

### Test Checklist

Before deploying to production, test these scenarios:

#### ✅ Test 1: Initialization
1. Open app (fresh install)
2. Sign in with test account
3. Check FlutterFlow logs for: `"[Main] ✅ PowerSync initialized successfully"`
4. Verify no errors in console

**Expected:** App starts successfully, no errors

#### ✅ Test 2: Query Data (Online)
1. Navigate to page with query action
2. Verify data loads from PowerSync
3. Check data matches Supabase

**Expected:** Data displays correctly

#### ✅ Test 3: Real-Time Updates
1. Open page with watch query
2. From another device/browser, modify the same data in Supabase
3. Verify FlutterFlow page updates automatically (within 1-2 seconds)

**Expected:** UI updates without refresh

#### ✅ Test 4: Create Record (Online)
1. Fill out form
2. Click Save (calls powerSyncWriteAction with INSERT)
3. Verify record appears in list immediately
4. Check Supabase - record should appear within 1-2 seconds

**Expected:** Instant UI update, quick sync to cloud

#### ✅ Test 5: Update Record (Online)
1. Click edit on existing record
2. Modify fields
3. Click Save (calls powerSyncWriteAction with UPDATE)
4. Verify changes appear immediately
5. Check Supabase - changes should sync within 1-2 seconds

**Expected:** Instant UI update, quick sync to cloud

#### ✅ Test 6: Delete Record (Online)
1. Click delete on record
2. Confirm deletion (calls powerSyncWriteAction with DELETE)
3. Verify record disappears from list immediately
4. Check Supabase - record should be deleted within 1-2 seconds

**Expected:** Instant UI removal, quick sync to cloud

#### ✅ Test 7: Create Record (Offline)
1. Enable airplane mode / disable WiFi
2. Fill out form
3. Click Save
4. Verify record appears in list immediately
5. Check connection indicator shows offline
6. Re-enable internet
7. Verify record syncs to Supabase within 5 seconds

**Expected:** Works offline, syncs when online

#### ✅ Test 8: Connection Indicator
1. Start with internet on
2. Check connection indicator shows online
3. Disable internet
4. Check connection indicator shows offline
5. Re-enable internet
6. Check connection indicator shows online again

**Expected:** Indicator updates correctly

#### ✅ Test 9: Sync Status
1. Go offline (airplane mode)
2. Create 3 new records
3. Call powerSyncGetStatusAction
4. Verify status shows: `connected: false`, `uploading: false`
5. Go online
6. Call powerSyncGetStatusAction within 2 seconds
7. Verify status shows: `connected: true`, `uploading: true`
8. Wait 5 seconds
9. Call powerSyncGetStatusAction again
10. Verify status shows: `connected: true`, `uploading: false`, `lastSyncedAt` updated

**Expected:** Status reflects sync activity accurately

---

## Troubleshooting

### Issue 1: "PowerSync not initialized" Error

**Symptoms:**
```
Error: PowerSync is not initialized. Call initializePowerSync() first.
```

**Causes:**
- initializePowerSyncAction() not called on app startup
- Called on wrong page (not initial landing page)
- Called before Firebase/Supabase initialization

**Solutions:**
1. Check initial landing page has "On Page Load" action
2. Verify action order: Firebase → Supabase → PowerSync
3. Check logs for PowerSync initialization success message

---

### Issue 2: Queries Return Empty Results

**Symptoms:**
- powerSyncQueryAction returns `[]` (empty array)
- Data exists in Supabase but not showing

**Causes:**
- PowerSync not synced yet (first time)
- Role-based filter too restrictive
- Wrong table name or column name

**Solutions:**
1. Wait 10-30 seconds after initialization for initial sync
2. Check PowerSync sync rules in dashboard
3. Call powerSyncGetStatusAction() - verify `hasSynced: true`
4. Verify table name matches schema (e.g., `vital_signs` not `vitalSigns`)
5. Test query in SQLite directly to isolate issue

**Debug Query:**
```
sql: "SELECT * FROM vital_signs LIMIT 1"
parameters: []
```
If this returns data, your filters are the issue.

---

### Issue 3: Watch Query Doesn't Update

**Symptoms:**
- StreamBuilder shows initial data
- Data changes but UI doesn't update

**Causes:**
- Using powerSyncQueryAction instead of powerSyncWatchQueryAction
- StreamBuilder not properly configured

**Solutions:**
1. Verify using powerSyncWatchQueryAction (not powerSyncQueryAction)
2. Check StreamBuilder stream parameter points to watch action
3. Verify builder function accesses `snapshot.data` correctly

---

### Issue 4: Write Succeeds But Doesn't Sync

**Symptoms:**
- powerSyncWriteAction completes without error
- Record shows in local list
- Record doesn't appear in Supabase

**Causes:**
- Network offline (data queued for sync)
- Supabase credentials invalid
- RLS (Row Level Security) blocking insert

**Solutions:**
1. Check connection: powerSyncIsConnectedAction()
2. Check PowerSync logs: Look for upload errors
3. Test Supabase connection: Direct insert via Supabase client
4. Check Supabase RLS policies: Ensure user can insert

**Verify Sync Queue:**
```
sql: "SELECT * FROM ps_crud WHERE status = 'pending'"
```
If records stuck in queue, sync is failing.

---

### Issue 5: "Package not found" Errors

**Symptoms:**
```
Error: The library 'package:medzen_iwani/powersync/database.dart' is not imported.
```

**Causes:**
- Custom actions not properly exported
- Import path incorrect

**Solutions:**
1. Check `lib/custom_code/actions/index.dart` includes exports
2. Verify import path in custom action files
3. Run `flutter pub get`
4. Clean and rebuild: `flutter clean && flutter pub get`

---

### Issue 6: Dependency Version Conflicts

**Symptoms:**
```
Error: Because supabase depends on powersync and custom_code depends on powersync, version solving failed.
```

**Causes:**
- Package versions incompatible
- FlutterFlow requirements not met

**Solutions:**
1. Check DEPENDENCY_UPDATE_SUMMARY.md for correct versions
2. Verify pubspec.yaml matches required versions:
   ```yaml
   powersync: ^1.7.1
   supabase: 2.7.0
   supabase_flutter: 2.9.0
   ```
3. Run `flutter pub get` after changes

---

## Performance Optimization

### Query Optimization

**Use LIMIT:**
```sql
-- ✅ Good - Limits results
"SELECT * FROM medical_records WHERE patient_id = ? ORDER BY created_at DESC LIMIT 50"

-- ❌ Bad - Could return thousands
"SELECT * FROM medical_records WHERE patient_id = ?"
```

**Select Specific Columns:**
```sql
-- ✅ Good - Only needed columns
"SELECT id, systolic_bp, diastolic_bp, recorded_at FROM vital_signs WHERE patient_id = ?"

-- ❌ Bad - Fetches all columns
"SELECT * FROM vital_signs WHERE patient_id = ?"
```

**Use Indexes:**
PowerSync automatically creates indexes on:
- Primary keys (`id`)
- Foreign keys (`patient_id`, `provider_id`, etc.)
- Timestamp columns (`created_at`, `updated_at`)

Queries filtering on these columns will be fast.

### Watch Query Usage

**✅ Use watch queries for:**
- Lists that users can modify (CRUD)
- Real-time dashboards
- Notification counters
- Data that changes frequently

**❌ Don't use watch queries for:**
- Static data (user profile, settings)
- Data fetched once per page
- Large result sets (hundreds of rows)
- Data that never changes

**Optimization Example:**
```
// ❌ Bad - watch query for static data
StreamBuilder → powerSyncWatchQueryAction("SELECT * FROM users WHERE id = ?", [userId])

// ✅ Good - one-time query for static data
On Page Load → powerSyncQueryAction("SELECT * FROM users WHERE id = ?", [userId])
```

### Memory Management

**Dispose StreamBuilders:**
FlutterFlow automatically disposes StreamBuilders when navigating away from pages. No manual cleanup needed.

**Batch Operations:**
```
// ❌ Bad - Multiple separate writes
FOR EACH item IN items:
  powerSyncWriteAction("INSERT INTO ...", [item.data])

// ✅ Good - Single batch write (if supported by your schema)
powerSyncWriteAction("INSERT INTO ... VALUES (?, ?), (?, ?), (?, ?)", [flattenedData])
```

---

## Security Considerations

### SQL Injection Prevention

**Always use parameterized queries:**
```
// ✅ Safe
sql: "SELECT * FROM vital_signs WHERE patient_id = ?"
parameters: [userId]

// ❌ UNSAFE - DO NOT DO THIS!
sql: "SELECT * FROM vital_signs WHERE patient_id = '${userId}'"
```

### Role-Based Access

PowerSync sync rules automatically enforce role-based access:
- Patients: See only their own data
- Providers: See patients they're assigned to
- Facility Admins: See facility data
- System Admins: See all data

**You still need to filter queries by role:**
```
// Patient role query
sql: "SELECT * FROM vital_signs WHERE patient_id = ?"
parameters: [FFAppState().userId]

// Provider role query
sql: "SELECT * FROM appointments WHERE provider_id = ? OR assigned_to = ?"
parameters: [FFAppState().userId, FFAppState().userId]
```

### HIPAA Compliance

PowerSync + Supabase is HIPAA-compliant when:
- ✅ Supabase project has BAA (Business Associate Agreement)
- ✅ PowerSync enterprise account with BAA
- ✅ All devices have device encryption enabled
- ✅ App follows HIPAA security rules

**Best Practices:**
- Never log sensitive medical data
- Use secure storage for credentials
- Implement session timeouts
- Require authentication for all operations

---

## Advanced Usage

### Custom Sync Trigger

Want to manually trigger sync after specific operations?

```
Action Flow (after critical write):
  → Custom Action: powerSyncWriteAction(sql, params)
  → Wait: 500ms
  → Custom Action: status = powerSyncGetStatusAction()
  → Show Snackbar:
    IF status['uploading']:
      "Syncing changes..."
    ELSE IF status['connected']:
      "Changes synced ✅"
    ELSE:
      "Saved locally - Will sync when online"
```

### Sync Progress Indicator

Show sync progress in UI:

```
Widget: Container (always visible)
  StreamBuilder → Custom Dart Code
    Stream: Custom Code that polls powerSyncGetStatusAction every 2 seconds
    Builder:
      IF snapshot.data['uploading']:
        LinearProgressIndicator + Text("Syncing...")
      ELSE IF snapshot.data['connected']:
        Icon(check) + Text("Synced")
      ELSE:
        Icon(cloud_off) + Text("Offline")
```

### Complex Queries

**JOIN Example:**
```sql
SELECT
  a.id,
  a.appointment_date,
  a.status,
  p.first_name,
  p.last_name,
  pr.specialty
FROM appointments a
JOIN patient_profiles p ON a.patient_id = p.user_id
JOIN provider_profiles pr ON a.provider_id = pr.user_id
WHERE a.provider_id = ?
ORDER BY a.appointment_date DESC
LIMIT 20
```

**Aggregation Example:**
```sql
SELECT
  DATE(recorded_at) as date,
  AVG(systolic_bp) as avg_systolic,
  AVG(diastolic_bp) as avg_diastolic,
  AVG(heart_rate) as avg_heart_rate
FROM vital_signs
WHERE patient_id = ?
  AND recorded_at > ?
GROUP BY DATE(recorded_at)
ORDER BY date DESC
```

---

## Migration Guide

### Migrating from Direct Supabase to PowerSync

If you have existing FlutterFlow pages using Supabase directly, follow this migration process:

#### Step 1: Identify Direct Supabase Calls

Find all instances of:
```dart
SupaFlow.client.from('table_name').select()
SupaFlow.client.from('table_name').insert()
SupaFlow.client.from('table_name').update()
SupaFlow.client.from('table_name').delete()
```

#### Step 2: Replace with PowerSync Actions

**Before (Direct Supabase):**
```
Backend Query → Supabase Query
  Table: vital_signs
  Filter: patient_id = FFAppState().userId
  Order: recorded_at DESC
  Limit: 10
Store in: vitalSignsResult
```

**After (PowerSync):**
```
Custom Action → powerSyncQueryAction
  sql: "SELECT * FROM vital_signs WHERE patient_id = ? ORDER BY recorded_at DESC LIMIT 10"
  parameters: [FFAppState().userId]
Store in: vitalSignsResult
```

#### Step 3: Test Offline Functionality

1. Run app online - verify data loads
2. Disable internet
3. Verify app still works
4. Create/update/delete records offline
5. Re-enable internet
6. Verify changes sync to Supabase

---

## Next Steps

Now that FlutterFlow is connected to PowerSync:

1. **✅ Test Integration**
   - Run through test checklist above
   - Verify online and offline functionality
   - Test on real devices (iOS, Android, Web)

2. **📋 Update FlutterFlow Pages**
   - Replace direct Supabase calls with PowerSync actions
   - Add offline indicators to UI
   - Implement sync status displays

3. **🚀 Deploy PowerSync Cloud**
   - If not done yet: Configure PowerSync instance
   - Deploy sync rules
   - Set up monitoring

4. **🧪 Production Testing**
   - Test with real users
   - Monitor sync performance
   - Check error rates

5. **📖 Document Custom Workflows**
   - Document page-specific PowerSync usage
   - Create team guidelines
   - Train developers

---

## Related Documentation

- `POWERSYNC_IMPLEMENTATION_SUMMARY.md` - Complete PowerSync technical implementation
- `POWERSYNC_QUICK_START.md` - Initial setup guide
- `POWERSYNC_MULTI_ROLE_GUIDE.md` - Role-based access patterns
- `DEPENDENCY_UPDATE_SUMMARY.md` - Package version requirements
- `CLAUDE.md` - Overall project architecture

---

## Support

**Issues:**
- Check troubleshooting section above
- Review PowerSync logs in FlutterFlow debug console
- Test connection status with custom actions

**Further Help:**
- PowerSync Documentation: https://docs.powersync.com
- Supabase Documentation: https://supabase.com/docs
- FlutterFlow Documentation: https://docs.flutterflow.io

---

*FlutterFlow PowerSync integration guide completed by Claude Code on October 22, 2025*
*For questions or issues, refer to related documentation*
