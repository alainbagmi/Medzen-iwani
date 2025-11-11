# Demographics Sync - Complete Implementation

**Date:** 2025-11-10
**Status:** ✅ FULLY OPERATIONAL with USER ROLE
**Version:** 2.1
**Last Tested:** 2025-11-10 13:25 UTC

---

## Summary

Successfully implemented automatic synchronization of **7 demographic fields** from Supabase to EHRbase, including the user_role field that was added in response to user feedback.

---

## Demographic Fields Synced

1. **Full Name** - Computed from first/middle/last name
2. **Date of Birth** - Patient's date of birth
3. **Gender** - Patient's gender
4. **Email** - Contact email address
5. **Phone Number** - Primary phone number
6. **Country** - Country of residence
7. **User Role** ✅ - Patient, Medical Provider, Facility Admin, or System Admin

---

## Architecture

### Data Flow
```
User Profile Update (Supabase users table)
    ↓
Database Trigger: queue_user_demographics_for_sync()
    ↓ [Joins with electronic_health_records to get user_role]
ehrbase_sync_queue table
    sync_type: 'demographics'
    template_id: 'medzen.patient_demographics.v1'
    data_snapshot: { ehr_id, user_role, demographics fields }
    ↓
Edge Function: sync-to-ehrbase
    ↓
updateEHRStatus(ehr_id, user_data)
    ↓
buildDemographicItems(user_data) → 7 ELEMENT objects
    ↓
EHRbase REST API: PUT /ehr/{ehr_id}/ehr_status
    ↓
EHR_STATUS.other_details.items[] updated with 7 demographics
```

### Key Components

**1. Database Trigger**
- File: `supabase/migrations/20251110130000_add_user_role_to_demographics_sync.sql`
- Trigger: `trigger_queue_user_demographics_for_ehrbase_sync`
- Function: `queue_user_demographics_for_sync()`
- Fires on: INSERT or UPDATE to `users` table
- Special: Joins with `electronic_health_records` to get `user_role`

**2. Edge Function**
- File: `supabase/functions/sync-to-ehrbase/index.ts`
- Handler: Lines 2374-2386 (demographics routing)
- Helper: `updateEHRStatus()` (lines 147-225)
- Builder: `buildDemographicItems()` (lines 237-307)
- Deployed: 2025-11-10 13:21 UTC (legacy bundle method)

**3. Test Script**
- File: `test_demographics_trigger.sh`
- Validates: All 7 fields in data_snapshot
- Verifies: All 7 fields in EHRbase EHR_STATUS
- Updated: 2025-11-10 to include user_role verification

---

## Test Results

### Latest Test Run: 2025-11-10 13:25 UTC

**Test User:**
- Supabase User ID: `8fa578b0-b41d-4f1d-9bf6-272137914f9e`
- EHR ID: `01c28a6c-c57e-4394-b143-b8ffa0a793ff`
- Queue Entry ID: `c9c68471-edfb-438e-bec1-224aed6e343f`

**Data Snapshot (from ehrbase_sync_queue):**
```json
{
  "user_id": "8fa578b0-b41d-4f1d-9bf6-272137914f9e",
  "firebase_uid": "1mkpFd7aRtUH9leRnOqb3hCJNZA3",
  "email": "test-ehrbase-1762753310@medzen-test.com",
  "ehr_id": "01c28a6c-c57e-4394-b143-b8ffa0a793ff",
  "user_role": "patient",
  "full_name": "Test Sync Demographics",
  "date_of_birth": "1990-01-01",
  "gender": "male",
  "phone_number": "+237123456789",
  "country": "Cameroon"
}
```

**EHRbase EHR_STATUS Verification:**
```
Extracted Demographics:
  Full Name: Test Sync Demographics
  Date of Birth: 1990-01-01
  Gender: male
  Email: test-ehrbase-1762753310@medzen-test.com
  Phone Number: +237123456789
  Country: Cameroon
  User Role: patient
```

**Test Result:** ✅ **PASSED**

```
🎉 SUCCESS! Demographics sync working end-to-end

✅ Trigger fires on user UPDATE
✅ Queue entry created with data_snapshot (including user_role)
✅ Edge function processes queue
✅ Demographics stored in EHR_STATUS (7 fields)
✅ User role verified: patient
```

---

## OpenEHR Structure

Each demographic field is stored as an ELEMENT in EHR_STATUS.other_details:

```json
{
  "_type": "EHR_STATUS",
  "other_details": {
    "_type": "ITEM_TREE",
    "archetype_node_id": "at0001",
    "name": { "_type": "DV_TEXT", "value": "Tree" },
    "items": [
      {
        "_type": "ELEMENT",
        "archetype_node_id": "at0002",
        "name": { "_type": "DV_TEXT", "value": "Full Name" },
        "value": { "_type": "DV_TEXT", "value": "Test Sync Demographics" }
      },
      {
        "_type": "ELEMENT",
        "archetype_node_id": "at0003",
        "name": { "_type": "DV_TEXT", "value": "Date of Birth" },
        "value": { "_type": "DV_DATE", "value": "1990-01-01" }
      },
      {
        "_type": "ELEMENT",
        "archetype_node_id": "at0004",
        "name": { "_type": "DV_TEXT", "value": "Gender" },
        "value": { "_type": "DV_TEXT", "value": "male" }
      },
      {
        "_type": "ELEMENT",
        "archetype_node_id": "at0005",
        "name": { "_type": "DV_TEXT", "value": "Email" },
        "value": { "_type": "DV_TEXT", "value": "test-ehrbase-1762753310@medzen-test.com" }
      },
      {
        "_type": "ELEMENT",
        "archetype_node_id": "at0006",
        "name": { "_type": "DV_TEXT", "value": "Phone Number" },
        "value": { "_type": "DV_TEXT", "value": "+237123456789" }
      },
      {
        "_type": "ELEMENT",
        "archetype_node_id": "at0007",
        "name": { "_type": "DV_TEXT", "value": "Country" },
        "value": { "_type": "DV_TEXT", "value": "Cameroon" }
      },
      {
        "_type": "ELEMENT",
        "archetype_node_id": "at0008",
        "name": { "_type": "DV_TEXT", "value": "User Role" },
        "value": { "_type": "DV_TEXT", "value": "patient" }
      }
    ]
  }
}
```

---

## User Role Values

The `user_role` field can have the following values based on the application's 4-tier user system:

- **`patient`** - Patient users (can view own records, book appointments)
- **`medical_provider`** - Medical providers (can access patient records, prescribe)
- **`facility_admin`** - Facility administrators (can manage staff, facilities)
- **`system_admin`** - System administrators (full system access)

---

## Monitoring Queries

### Check Recent Demographics Syncs
```sql
SELECT
  id,
  record_id,
  sync_type,
  sync_status,
  data_snapshot->>'user_role' as user_role,
  data_snapshot->>'full_name' as full_name,
  created_at,
  updated_at,
  error_message
FROM ehrbase_sync_queue
WHERE sync_type = 'demographics'
ORDER BY created_at DESC
LIMIT 10;
```

### Verify User Role in EHRbase
```bash
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"
EHR_ID="<ehr_id>"

curl -s "$EHRBASE_URL/rest/openehr/v1/ehr/$EHR_ID/ehr_status" \
  -H "Authorization: Basic $(echo -n \"$EHRBASE_USER:$EHRBASE_PASS\" | base64)" \
  -H "Accept: application/json" | \
  jq '.other_details.items[] | select(.name.value == "User Role")'
```

### AQL Query for User Demographics
```sql
SELECT
  e/ehr_id/value as ehr_id,
  e/ehr_status/other_details/items[at0002]/value/value as full_name,
  e/ehr_status/other_details/items[at0003]/value/value as date_of_birth,
  e/ehr_status/other_details/items[at0004]/value/value as gender,
  e/ehr_status/other_details/items[at0005]/value/value as email,
  e/ehr_status/other_details/items[at0006]/value/value as phone_number,
  e/ehr_status/other_details/items[at0007]/value/value as country,
  e/ehr_status/other_details/items[at0008]/value/value as user_role
FROM EHR e
WHERE e/ehr_id/value = '<ehr_id>'
```

---

## Files Modified

1. ✅ `supabase/migrations/20251110050000_fix_demographics_trigger_columns.sql` (initial)
2. ✅ `supabase/migrations/20251110060000_fix_demographics_trigger_schema.sql` (v2.0)
3. ✅ `supabase/migrations/20251110130000_add_user_role_to_demographics_sync.sql` (v2.1)
4. ✅ `supabase/functions/sync-to-ehrbase/index.ts` (lines 297-304 for user_role)
5. ✅ `test_demographics_trigger.sh` (updated to verify 7 fields)
6. ✅ `DEMOGRAPHICS_SYNC_USER_ROLE_UPDATE.md` (user_role update documentation)
7. ✅ `DEMOGRAPHICS_SYNC_COMPLETE.md` (this document)

---

## Production Status

✅ **Database Trigger:** Deployed (2025-11-10 13:18 UTC)
✅ **Edge Function:** Deployed (2025-11-10 13:21 UTC via legacy bundle)
✅ **End-to-End Test:** Passed (2025-11-10 13:25 UTC)
✅ **User Role Field:** Verified in EHRbase

---

## Key Learnings

1. **EHR_STATUS vs Compositions** - Demographics belong in EHR_STATUS, not compositions
2. **User Role Source** - User role comes from `electronic_health_records` table, not `users` table
3. **Database Joins in Triggers** - Trigger must join with `electronic_health_records` to get user_role
4. **NULL Composition ID** - Demographics sync entries have `ehrbase_composition_id=NULL` (correct)
5. **Generated Columns** - `full_name` cannot be updated directly (auto-computed)
6. **Legacy Bundle Deployment** - Use `--legacy-bundle` flag when Docker isn't running
7. **GET-Modify-PUT Pattern** - EHR_STATUS updates require fetching current version first

---

## Next Steps (Future Enhancements)

### Phase 1: Additional Demographics
- [ ] Add address fields (address, city, state, postal_code)
- [ ] Add emergency contact information
- [ ] Add insurance information

### Phase 2: History Tracking
- [ ] Implement demographics change history
- [ ] Track who made changes and when
- [ ] Audit log for compliance

### Phase 3: Monitoring
- [ ] Create dashboard for sync status
- [ ] Add webhook notifications for failures
- [ ] Real-time sync metrics

---

## Documentation References

- **Implementation Guide:** `DEMOGRAPHICS_SYNC_IMPLEMENTATION.md`
- **Summary:** `DEMOGRAPHICS_SYNC_SUMMARY.md`
- **User Role Update:** `DEMOGRAPHICS_SYNC_USER_ROLE_UPDATE.md`
- **Test Script:** `test_demographics_trigger.sh`
- **Edge Function:** `supabase/functions/sync-to-ehrbase/index.ts`

---

**Implementation Complete: 2025-11-10 13:25 UTC**
**Status: PRODUCTION READY with 7 FIELDS (including user_role)**
