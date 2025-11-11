# PowerSync Multi-Role Sync Rules Guide

This guide explains the role-based PowerSync synchronization system for MedZen-Iwani. The sync rules ensure that each user role only accesses data they're authorized to see, while enabling offline-first functionality.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Role Definitions](#role-definitions)
3. [Data Access Matrix](#data-access-matrix)
4. [Deployment Instructions](#deployment-instructions)
5. [Testing Role-Based Sync](#testing-role-based-sync)
6. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### How PowerSync Determines User Role

PowerSync uses **bucket definitions** to determine which data to sync for each user. The system automatically detects the user's role by checking which profile table has a record linked to their `firebase_uid`.

**Role Detection Logic:**

1. **Patient**: Has a record in `patient_profiles` table
2. **Medical Provider**: Has a record in `medical_provider_profiles` table
3. **Facility Admin**: Has a record in `facility_admin_profiles` table
4. **System Admin**: Has a record in `system_admin_profiles` table

**Important:** A user can have **multiple roles** (e.g., a doctor who is also an admin). PowerSync will create separate buckets for each role, syncing the union of all accessible data.

### Bucket System

Each role has its own **bucket definition**:

- `patient_data` - Patient-specific data access
- `provider_data` - Medical provider data access
- `facility_admin_data` - Facility-wide data access
- `system_admin_data` - Full system access

The `parameters` section in each bucket identifies users with that role, and the `data` section defines what tables/rows to sync.

---

## Role Definitions

### 1. Patient Role

**Who Gets This:**
- Users with a record in `patient_profiles` table

**What They Can Access:**
- Their own user profile
- Their own patient profile
- Their own medical data:
  - Electronic health records
  - Vital signs
  - Lab results
  - Prescriptions
  - Immunizations
  - Medical records
  - Allergies
- Their appointments
- Basic info about providers they've seen
- Provider profiles for their providers
- Sync queue for their data

**Use Cases:**
- View personal health records
- Track medications and allergies
- Access appointment history
- View provider information

**Data Scope:** ✅ **Own data only** (most restrictive)

---

### 2. Medical Provider Role

**Who Gets This:**
- Users with a record in `medical_provider_profiles` table

**What They Can Access:**
- Their own user and provider profiles
- Their appointments
- **All patients they have appointments with:**
  - Patient user records
  - Patient profiles
  - Complete medical data for their patients:
    - Electronic health records
    - Vital signs
    - Lab results
    - Prescriptions
    - Immunizations
    - Medical records
    - Allergies
- Facilities where they work (`facility_providers`)
- Their own availability and schedule
- Sync queue for their patient data

**Use Cases:**
- View patient medical histories
- Access patient records during consultations
- Manage appointments
- Update medical records offline
- View schedule and availability

**Data Scope:** ✅ **Patients they're treating** (provider-patient relationship via appointments)

**Key Security Note:**
Providers can only see patients they have appointments with. This ensures providers don't access unrelated patient data.

---

### 3. Facility Admin Role

**Who Gets This:**
- Users with a record in `facility_admin_profiles` table

**What They Can Access:**
- Their own user and facility admin profiles
- All providers working at their facility (`facility_providers`)
- Provider user records and profiles at their facility
- **All appointments at their facility**
- **All patients with appointments at their facility:**
  - Patient user records
  - Patient profiles
  - Complete medical data for facility patients:
    - Electronic health records
    - Vital signs
    - Lab results
    - Prescriptions
    - Immunizations
    - Medical records
- Facility departments
- Facility reports
- Provider availability schedules at their facility

**Use Cases:**
- Monitor facility operations
- View facility-wide appointments
- Access patient data for facility management
- Manage provider schedules
- Generate facility reports
- Oversee facility departments

**Data Scope:** ✅ **All data for their facility** (facility-wide access)

**Key Security Note:**
Admins can only access data for patients who have appointments at their facility. This prevents cross-facility data leaks.

---

### 4. System Admin Role

**Who Gets This:**
- Users with a record in `system_admin_profiles` table

**What They Can Access:**
- **EVERYTHING** - Full system access
- All users (all roles)
- All patient data (system-wide)
- All provider data (system-wide)
- All facility data (all facilities)
- All appointments (system-wide)
- All medical records (system-wide)
- System admin statistics and reports
- OpenEHR integration health monitoring
- User activity logs
- Email logs
- Feedback

**Use Cases:**
- System monitoring and administration
- Cross-facility analytics
- Data migration and maintenance
- User management
- System health monitoring
- Compliance and auditing

**Data Scope:** ✅ **ALL DATA** (superuser access)

**⚠️ Security Warning:**
System admin access should be **heavily restricted**. Only grant this role to trusted system administrators who need full data access for legitimate operational purposes.

---

## Data Access Matrix

| Data Type | Patient | Provider | Facility Admin | System Admin |
|-----------|---------|----------|----------------|--------------|
| **Own user profile** | ✅ | ✅ | ✅ | ✅ |
| **Own role profile** | ✅ | ✅ | ✅ | ✅ |
| **Own medical data** | ✅ | ❌ | ❌ | ✅ |
| **Own appointments** | ✅ | ✅ | ❌ | ✅ |
| **Patient medical data** | Own only | Via appointments | Via facility | All |
| **Provider schedules** | Limited | Own | Facility-wide | All |
| **Appointments** | Own | Own | Facility-wide | All |
| **Facility data** | ❌ | Limited | Own facility | All |
| **System statistics** | ❌ | ❌ | ❌ | ✅ |
| **User activity logs** | ❌ | ❌ | ❌ | ✅ |

### Access Patterns Explained

**Patients:**
- **Direct access:** Can only see their own data
- **No cross-patient access:** Cannot see other patients' data
- **Provider visibility:** Can see basic info about providers they've seen

**Providers:**
- **Patient data via appointments:** Can only access patients they have appointments with
- **No unrestricted patient access:** Cannot browse all patients
- **Facility-scoped:** Can see which facilities they work at

**Facility Admins:**
- **Facility-scoped access:** Can see all data for their facility
- **Patient data via facility:** Can access patients who have appointments at their facility
- **No cross-facility access:** Cannot see data from other facilities
- **Provider oversight:** Can see all providers working at their facility

**System Admins:**
- **Unrestricted access:** Can see all data across all facilities
- **System monitoring:** Access to logs, statistics, and health metrics
- **No automatic filtering:** All queries return complete datasets

---

## Deployment Instructions

### Step 1: Update PowerSync Dashboard

1. Log in to [PowerSync Dashboard](https://powersync.journeyapps.com/)
2. Navigate to your instance
3. Go to **Sync Rules** section
4. **Replace** the existing sync rules with the contents of `POWERSYNC_SYNC_RULES.yaml`
5. Click **Save** and then **Deploy**

### Step 2: Verify Sync Rules

Run this query in PowerSync Dashboard → **Data Explorer** to test role detection:

```sql
-- Test patient role detection
SELECT
  u.id as user_id,
  u.email,
  pp.id as patient_profile_id,
  'patient' as role
FROM users u
INNER JOIN patient_profiles pp ON pp.user_id = u.id::text
LIMIT 5;

-- Test provider role detection
SELECT
  u.id as user_id,
  u.email,
  mpp.id as provider_profile_id,
  'provider' as role
FROM users u
INNER JOIN medical_provider_profiles mpp ON mpp.user_id = u.id::text
LIMIT 5;

-- Test facility admin role detection
SELECT
  u.id as user_id,
  u.email,
  fap.id as facility_admin_profile_id,
  fap.facility_id,
  'facility_admin' as role
FROM users u
INNER JOIN facility_admin_profiles fap ON fap.user_id = u.id::text
LIMIT 5;

-- Test system admin role detection
SELECT
  u.id as user_id,
  u.email,
  sap.id as system_admin_profile_id,
  'system_admin' as role
FROM users u
INNER JOIN system_admin_profiles sap ON sap.user_id = u.id::text
LIMIT 5;
```

### Step 3: Update Flutter App (If Needed)

The Flutter app doesn't need changes if you're already using PowerSync. However, verify that the PowerSync token function includes the user's `firebase_uid`:

**Check `supabase/functions/powersync-token/index.ts`:**

```typescript
// Should include firebase_uid in JWT claims
const token = await generatePowerSyncToken({
  userId: userId,
  // This maps to token_parameters.user_id() in sync rules
  sub: user.id, // Supabase user ID
  user_id: firebaseUid, // Firebase UID (CRITICAL!)
});
```

### Step 4: Test Each Role

See [Testing Role-Based Sync](#testing-role-based-sync) section below.

---

## Testing Role-Based Sync

### Testing as a Patient

1. **Login as a patient** (user with `patient_profiles` record)
2. **Check synced data:**

```dart
// Custom action: testPatientSync
import 'package:medzen_iwani/powersync/database.dart';

Future<void> testPatientSync() async {
  // Should return patient's own data
  final vitals = await executeQuery('SELECT * FROM vital_signs', []);
  print('Vital signs synced: ${vitals.length}');

  // Should return patient's appointments
  final appointments = await executeQuery('SELECT * FROM appointments', []);
  print('Appointments synced: ${appointments.length}');

  // Should NOT return other patients' data
  final allVitals = await executeQuery(
    'SELECT COUNT(DISTINCT patient_id) as patient_count FROM vital_signs',
    []
  );
  print('Unique patients in vital_signs: ${allVitals[0]['patient_count']}');
  // Expected: 1 (only your own data)
}
```

### Testing as a Provider

1. **Login as a provider** (user with `medical_provider_profiles` record)
2. **Check synced data:**

```dart
// Custom action: testProviderSync
import 'package:medzen_iwani/powersync/database.dart';

Future<void> testProviderSync() async {
  // Should return provider's appointments
  final appointments = await executeQuery('SELECT * FROM appointments', []);
  print('Appointments synced: ${appointments.length}');

  // Should return data for patients with appointments
  final patients = await executeQuery(
    'SELECT COUNT(DISTINCT id) as patient_count FROM patient_profiles',
    []
  );
  print('Patients synced: ${patients[0]['patient_count']}');

  // Should return vital signs for provider's patients only
  final vitals = await executeQuery(
    'SELECT COUNT(*) as vital_count FROM vital_signs',
    []
  );
  print('Vital signs synced: ${vitals[0]['vital_count']}');

  // Verify patients match appointments
  final patientCheck = await executeQuery('''
    SELECT
      COUNT(DISTINCT a.patient_id) as appointment_patients,
      COUNT(DISTINCT pp.user_id) as synced_patients
    FROM appointments a
    LEFT JOIN patient_profiles pp ON pp.user_id = a.patient_id
  ''', []);
  print('Appointment patients: ${patientCheck[0]['appointment_patients']}');
  print('Synced patients: ${patientCheck[0]['synced_patients']}');
}
```

### Testing as a Facility Admin

1. **Login as a facility admin** (user with `facility_admin_profiles` record)
2. **Check synced data:**

```dart
// Custom action: testFacilityAdminSync
import 'package:medzen_iwani/powersync/database.dart';

Future<void> testFacilityAdminSync() async {
  // Should return all appointments at admin's facility
  final appointments = await executeQuery('SELECT * FROM appointments', []);
  print('Facility appointments synced: ${appointments.length}');

  // Should return all providers at facility
  final providers = await executeQuery(
    'SELECT COUNT(*) as provider_count FROM facility_providers',
    []
  );
  print('Facility providers synced: ${providers[0]['provider_count']}');

  // Should return patients with appointments at facility
  final patients = await executeQuery(
    'SELECT COUNT(DISTINCT user_id) as patient_count FROM patient_profiles',
    []
  );
  print('Facility patients synced: ${patients[0]['patient_count']}');

  // Verify facility scope
  final facilityCheck = await executeQuery('''
    SELECT
      COUNT(DISTINCT facility_id) as facility_count
    FROM appointments
  ''', []);
  print('Facilities in synced appointments: ${facilityCheck[0]['facility_count']}');
  // Expected: 1 (only your own facility)
}
```

### Testing as a System Admin

1. **Login as a system admin** (user with `system_admin_profiles` record)
2. **Check synced data:**

```dart
// Custom action: testSystemAdminSync
import 'package:medzen_iwani/powersync/database.dart';

Future<void> testSystemAdminSync() async {
  // Should return ALL data
  final users = await executeQuery(
    'SELECT COUNT(*) as user_count FROM users',
    []
  );
  print('Total users synced: ${users[0]['user_count']}');

  final appointments = await executeQuery(
    'SELECT COUNT(*) as appt_count FROM appointments',
    []
  );
  print('Total appointments synced: ${appointments[0]['appt_count']}');

  final vitals = await executeQuery(
    'SELECT COUNT(*) as vital_count FROM vital_signs',
    []
  );
  print('Total vital signs synced: ${vitals[0]['vital_count']}');

  // Should have access to system logs
  final logs = await executeQuery(
    'SELECT COUNT(*) as log_count FROM user_activity_logs',
    []
  );
  print('User activity logs synced: ${logs[0]['log_count']}');

  // Verify cross-facility access
  final facilities = await executeQuery('''
    SELECT COUNT(DISTINCT facility_id) as facility_count
    FROM appointments
  ''', []);
  print('Total facilities in appointments: ${facilities[0]['facility_count']}');
  // Expected: All facilities in the system
}
```

---

## Troubleshooting

### Issue: User Not Syncing Any Data

**Symptoms:**
- PowerSync connected but no data syncing
- `executeQuery()` returns empty results

**Solution:**
1. Verify user has a role profile record:

```sql
-- Check which roles this user has
SELECT 'patient' as role, COUNT(*) FROM patient_profiles WHERE user_id = 'USER_ID'
UNION ALL
SELECT 'provider' as role, COUNT(*) FROM medical_provider_profiles WHERE user_id = 'USER_ID'
UNION ALL
SELECT 'facility_admin' as role, COUNT(*) FROM facility_admin_profiles WHERE user_id = 'USER_ID'
UNION ALL
SELECT 'system_admin' as role, COUNT(*) FROM system_admin_profiles WHERE user_id = 'USER_ID';
```

2. If no role profile exists, create one:

```sql
-- Example: Add patient profile
INSERT INTO patient_profiles (user_id, created_at, updated_at)
VALUES ('USER_ID', NOW(), NOW());
```

3. Verify PowerSync token includes correct `firebase_uid`

### Issue: Provider Seeing No Patient Data

**Symptoms:**
- Provider can log in but sees no patient records
- Appointments sync but medical data doesn't

**Solution:**
1. Verify provider has appointments:

```sql
SELECT * FROM appointments WHERE provider_id = 'PROVIDER_PROFILE_ID';
```

2. Check if appointments have `patient_id` populated:

```sql
SELECT
  id,
  provider_id,
  patient_id,
  scheduled_start
FROM appointments
WHERE provider_id = 'PROVIDER_PROFILE_ID'
  AND patient_id IS NOT NULL;
```

3. If `patient_id` is NULL, appointments are incomplete. Update them:

```sql
UPDATE appointments
SET patient_id = 'PATIENT_USER_ID'
WHERE id = 'APPOINTMENT_ID';
```

### Issue: Facility Admin Seeing Wrong Facility Data

**Symptoms:**
- Facility admin seeing data from other facilities
- OR not seeing any facility data

**Solution:**
1. Verify facility admin profile has correct `facility_id`:

```sql
SELECT
  fap.user_id,
  fap.facility_id,
  u.email
FROM facility_admin_profiles fap
JOIN users u ON u.id::text = fap.user_id
WHERE fap.user_id = 'USER_ID';
```

2. Check appointments at that facility:

```sql
SELECT COUNT(*) as appt_count
FROM appointments
WHERE facility_id = 'FACILITY_ID';
```

3. If facility admin has no `facility_id`, assign one:

```sql
UPDATE facility_admin_profiles
SET facility_id = 'FACILITY_ID'
WHERE user_id = 'USER_ID';
```

### Issue: Sync Rules Not Updating

**Symptoms:**
- Updated sync rules in dashboard but old rules still active
- Data not syncing according to new rules

**Solution:**
1. **Hard refresh PowerSync sync rules:**
   - PowerSync Dashboard → Sync Rules
   - Click **Save**
   - Click **Deploy** (don't skip this!)
   - Wait for "Deployed successfully" message

2. **Force client resync:**

```dart
// Custom action: forceResync
import 'package:medzen_iwani/powersync/database.dart';

Future<void> forceResync() async {
  // Disconnect and reconnect PowerSync
  await db.disconnect();
  await Future.delayed(Duration(seconds: 2));
  await db.connect(connector: SupabaseConnector());
}
```

3. **Clear local database (nuclear option):**

```dart
// ⚠️ WARNING: This deletes all local data
import 'package:medzen_iwani/powersync/database.dart';

Future<void> clearLocalDatabase() async {
  await db.disconnectAndClear();
  await initializePowerSync();
}
```

### Issue: System Admin Not Seeing All Data

**Symptoms:**
- System admin can't access all users/facilities
- Some tables not syncing

**Solution:**
1. Verify system admin profile exists:

```sql
SELECT * FROM system_admin_profiles WHERE user_id = 'USER_ID';
```

2. Check if tables are included in sync rules:

```yaml
# In POWERSYNC_SYNC_RULES.yaml, system_admin_data should have:
data:
  - SELECT * FROM users
  - SELECT * FROM appointments
  # ... etc
```

3. Verify table permissions in Supabase:

```sql
-- Check if postgres user can read tables
SELECT
  tablename,
  has_table_privilege('postgres', schemaname || '.' || tablename, 'SELECT') as can_read
FROM pg_tables
WHERE schemaname = 'public';
```

---

## Performance Considerations

### Data Volume by Role

Estimated local database sizes based on typical usage:

| Role | Estimated Local DB Size | Sync Time (Initial) |
|------|------------------------|---------------------|
| **Patient** | 5-20 MB | 5-10 seconds |
| **Provider** | 50-200 MB | 30-60 seconds |
| **Facility Admin** | 200-500 MB | 1-3 minutes |
| **System Admin** | 1-5 GB | 5-15 minutes |

**Optimization Tips:**

1. **For Providers:** Limit appointment history in queries:

```dart
// Only sync appointments from last 6 months
final recentAppointments = await executeQuery('''
  SELECT * FROM appointments
  WHERE scheduled_start >= date('now', '-6 months')
''', []);
```

2. **For Facility Admins:** Consider archiving old data:

```sql
-- Archive appointments older than 1 year
-- (Implement in Supabase with periodic function)
```

3. **For System Admins:** Use pagination for large datasets:

```dart
// Paginate large queries
final page1 = await executeQuery(
  'SELECT * FROM user_activity_logs ORDER BY created_at DESC LIMIT 100 OFFSET 0',
  []
);
```

---

## Security Best Practices

1. **Never bypass sync rules** - Don't use direct Supabase queries in production
2. **Audit system admin access** - Log all system admin actions
3. **Test role changes** - When users change roles, verify correct data access
4. **Monitor sync errors** - Watch for unauthorized access attempts in logs
5. **Rotate PowerSync keys** - Change PowerSync credentials periodically

---

## Next Steps

1. ✅ Deploy sync rules to PowerSync Dashboard
2. ✅ Test each role thoroughly
3. ✅ Monitor sync performance
4. ✅ Document role assignment process
5. ✅ Train staff on role-based data access

For questions or issues, refer to:
- **[POWERSYNC_IMPLEMENTATION.md](./POWERSYNC_IMPLEMENTATION.md)** - Technical implementation guide
- **[EHR_SYSTEM_README.md](./EHR_SYSTEM_README.md)** - Overall system architecture
- **[PowerSync Docs](https://docs.powersync.com/)** - Official PowerSync documentation
