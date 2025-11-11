# PowerSync Multi-Role Implementation Summary

## What Changed

### Before (Patient-Only)
```yaml
bucket_definitions:
  global:
    # Only supported patients
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()
    data:
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id
      # ... only patient data
```

**Issues:**
- ❌ Providers couldn't access patient data
- ❌ Facility admins had no facility-wide access
- ❌ System admins couldn't monitor system
- ❌ Only worked for patient role

---

### After (All 4 Roles)
```yaml
bucket_definitions:
  patient_data:
    # Patient-specific bucket
  provider_data:
    # Provider-patient relationships
  facility_admin_data:
    # Facility-wide access
  system_admin_data:
    # Full system access
```

**Benefits:**
- ✅ All 4 roles fully supported
- ✅ Proper data isolation by role
- ✅ Providers see only their patients
- ✅ Facility admins see facility data only
- ✅ System admins have full access
- ✅ Multi-role support (one user, multiple roles)

---

## Key Features

### 1. Role Detection
PowerSync automatically detects role by checking profile tables:

```sql
-- Patient detection
SELECT u.id FROM users u
INNER JOIN patient_profiles pp ON pp.user_id = u.id::text
WHERE u.firebase_uid = token_parameters.user_id()

-- Provider detection
SELECT u.id, mpp.id as provider_profile_id FROM users u
INNER JOIN medical_provider_profiles mpp ON mpp.user_id = u.id::text
WHERE u.firebase_uid = token_parameters.user_id()
```

### 2. Data Scoping

| Role | Access Level | Example |
|------|-------------|---------|
| **Patient** | Own data only | Can only see their own vital signs |
| **Provider** | Via appointments | Sees patients they have appointments with |
| **Facility Admin** | Via facility | Sees all data at their facility |
| **System Admin** | Everything | Sees all data across all facilities |

### 3. Security Boundaries

**Patient → Provider:**
- Patient can see basic info about providers they've seen
- Provider can access full medical records for their patients

**Provider → Facility:**
- Provider can see which facilities they work at
- Facility admin can see all providers at their facility

**Facility → System:**
- Facility admin sees only their facility
- System admin sees all facilities

---

## Data Access Examples

### Patient Accessing Data
```dart
// Patient logs in
// PowerSync syncs ONLY their data:
- users (own record)
- patient_profiles (own profile)
- vital_signs (WHERE patient_id = own user_id)
- appointments (WHERE patient_id = own user_id)
- medical_records (WHERE patient_id = own user_id)
```

### Provider Accessing Data
```dart
// Provider logs in
// PowerSync syncs:
- users (own record + patients they have appointments with)
- medical_provider_profiles (own profile)
- appointments (WHERE provider_id = own provider_profile_id)
- vital_signs (WHERE patient_id IN (SELECT patient_id FROM appointments WHERE provider_id = own))
- prescriptions (for their patients)
- lab_results (for their patients)
```

### Facility Admin Accessing Data
```dart
// Facility admin logs in
// PowerSync syncs:
- users (own record + all staff + all patients at facility)
- facility_admin_profiles (own profile)
- facility_providers (all providers at facility)
- appointments (WHERE facility_id = own facility_id)
- vital_signs (for patients with appointments at facility)
- All medical data for facility patients
```

### System Admin Accessing Data
```dart
// System admin logs in
// PowerSync syncs:
- ALL users
- ALL appointments
- ALL medical data
- ALL facilities
- System statistics and logs
```

---

## Migration Steps

### Step 1: Backup Current Rules
```bash
# Save old rules (already done - they're in git history)
git add POWERSYNC_SYNC_RULES.yaml
git commit -m "Backup: Patient-only sync rules"
```

### Step 2: Deploy New Rules
1. Copy contents of `POWERSYNC_SYNC_RULES.yaml`
2. Go to PowerSync Dashboard → Sync Rules
3. Paste new rules
4. Click **Save** then **Deploy**

### Step 3: Test Each Role
```dart
// See POWERSYNC_MULTI_ROLE_GUIDE.md for test scripts
await testPatientSync();
await testProviderSync();
await testFacilityAdminSync();
await testSystemAdminSync();
```

### Step 4: Monitor
- Check PowerSync Dashboard → Monitoring
- Watch sync errors in logs
- Verify data volumes per role
- Test offline functionality for each role

---

## Testing Checklist

### ✅ Patient Role
- [ ] Patient can see own vital signs
- [ ] Patient can see own appointments
- [ ] Patient can see own prescriptions
- [ ] Patient CANNOT see other patients' data
- [ ] Patient can see basic provider info
- [ ] Data syncs when offline
- [ ] Changes sync back when online

### ✅ Provider Role
- [ ] Provider can see their appointments
- [ ] Provider can see patient data for their appointments
- [ ] Provider CANNOT see unrelated patient data
- [ ] Provider can see facility relationships
- [ ] Provider can update medical records offline
- [ ] Updates sync to EHRbase when online

### ✅ Facility Admin Role
- [ ] Facility admin can see all facility appointments
- [ ] Facility admin can see all facility providers
- [ ] Facility admin can see all facility patients
- [ ] Facility admin CANNOT see other facilities' data
- [ ] Facility admin can access facility reports
- [ ] Data syncs correctly for facility scope

### ✅ System Admin Role
- [ ] System admin can see ALL users
- [ ] System admin can see ALL appointments
- [ ] System admin can see ALL medical data
- [ ] System admin can access system logs
- [ ] System admin can view statistics
- [ ] No data is filtered out

---

## Rollback Plan

If new rules cause issues:

### Rollback to Patient-Only Rules
```bash
# 1. Restore old rules from git
git show HEAD~1:POWERSYNC_SYNC_RULES.yaml > POWERSYNC_SYNC_RULES_OLD.yaml

# 2. Copy old rules to PowerSync Dashboard

# 3. Force resync all clients
```

### Quick Fix: Disable Problematic Bucket
```yaml
# Comment out problematic bucket
bucket_definitions:
  patient_data:
    # Works fine
  # provider_data:
  #   # Having issues - temporarily disabled
  facility_admin_data:
    # Works fine
  system_admin_data:
    # Works fine
```

---

## Performance Impact

### Expected Sync Times

| Role | Initial Sync | Incremental Sync |
|------|-------------|------------------|
| Patient | 5-10 sec | < 1 sec |
| Provider | 30-60 sec | 2-5 sec |
| Facility Admin | 1-3 min | 5-10 sec |
| System Admin | 5-15 min | 30-60 sec |

### Database Size Estimates

| Role | Local DB Size | Notes |
|------|--------------|-------|
| Patient | 5-20 MB | Minimal data |
| Provider | 50-200 MB | Depends on patient count |
| Facility Admin | 200-500 MB | Depends on facility size |
| System Admin | 1-5 GB | Full system data |

**Optimization Tip:** For large datasets, consider:
- Time-based filtering (e.g., appointments from last 6 months)
- Pagination in queries
- Archiving old records

---

## Common Issues & Solutions

### Issue 1: Provider Sees No Patient Data
**Cause:** Provider has no appointments
**Solution:** Create appointments linking provider to patients

```sql
INSERT INTO appointments (provider_id, patient_id, ...)
VALUES ('PROVIDER_PROFILE_ID', 'PATIENT_USER_ID', ...);
```

### Issue 2: Facility Admin Sees Wrong Facility
**Cause:** `facility_admin_profiles.facility_id` incorrect
**Solution:** Update facility_id

```sql
UPDATE facility_admin_profiles
SET facility_id = 'CORRECT_FACILITY_ID'
WHERE user_id = 'USER_ID';
```

### Issue 3: User Has No Role
**Cause:** No profile record in role tables
**Solution:** Create profile record

```sql
-- For patient
INSERT INTO patient_profiles (user_id, created_at, updated_at)
VALUES ('USER_ID', NOW(), NOW());

-- For provider
INSERT INTO medical_provider_profiles (user_id, provider_number, ...)
VALUES ('USER_ID', 'PRV-001', ...);
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| **POWERSYNC_SYNC_RULES.yaml** | Actual sync rules (deploy to PowerSync) |
| **POWERSYNC_MULTI_ROLE_GUIDE.md** | Complete guide with examples |
| **POWERSYNC_MULTI_ROLE_SUMMARY.md** | This document (quick reference) |
| **CLAUDE.md** | Project documentation (includes PowerSync) |

---

## Next Steps

1. ✅ **Deploy** new sync rules to PowerSync Dashboard
2. ✅ **Test** each role thoroughly using test scripts
3. ✅ **Monitor** PowerSync Dashboard for errors
4. ✅ **Update** Flutter app if needed (token function)
5. ✅ **Document** role assignment process for team
6. ✅ **Train** staff on role-based data access

---

## Support

For issues or questions:
- **Technical Guide:** See `POWERSYNC_MULTI_ROLE_GUIDE.md`
- **PowerSync Docs:** https://docs.powersync.com/
- **Troubleshooting:** See guide's Troubleshooting section
- **System Architecture:** See `EHR_SYSTEM_README.md`
