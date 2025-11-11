# Demographics Sync - User Role Update

**Date:** 2025-11-10
**Status:** ✅ COMPLETED
**Update Version:** 2.1

## Overview

Added `user_role` field to demographics synchronization from Supabase to EHRbase EHR_STATUS.

## Changes Made

### 1. Database Trigger Update
**File:** `supabase/migrations/20251110130000_add_user_role_to_demographics_sync.sql`

**Change:** Modified `queue_user_demographics_for_sync()` function to include `user_role` from `electronic_health_records` table in the `data_snapshot`:

```sql
snapshot_data := jsonb_build_object(
  ...
  'user_role', ehr_record.user_role,  -- ✅ Added user_role from EHR record
  ...
);
```

**Deployment:** Applied via direct SQL execution on 2025-11-10 13:18 UTC

### 2. Edge Function Update
**File:** `supabase/functions/sync-to-ehrbase/index.ts`

**Change:** Added user_role to `buildDemographicItems()` function (lines 297-304):

```typescript
if (userData.user_role) {
  items.push({
    _type: 'ELEMENT',
    archetype_node_id: 'at0008',
    name: { _type: 'DV_TEXT', value: 'User Role' },
    value: { _type: 'DV_TEXT', value: userData.user_role }
  })
}
```

**Deployment:** Deployed using legacy bundle method on 2025-11-10 13:21 UTC

## Test Results

**Test Run:** 2025-11-10 13:21 UTC
**Test User:** `8fa578b0-b41d-4f1d-9bf6-272137914f9e`
**EHR ID:** `01c28a6c-c57e-4394-b143-b8ffa0a793ff`
**Queue ID:** `2588037e-d7c2-4397-b34c-35182dd81615`

### Data Snapshot (from ehrbase_sync_queue)
```json
{
  "user_role": "patient",
  "full_name": "Test Sync Demographics",
  "date_of_birth": "1990-01-01",
  "gender": "male",
  "email": "test-ehrbase-1762753310@medzen-test.com",
  "phone_number": "+237123456789",
  "country": "Cameroon"
}
```

### EHRbase EHR_STATUS Verification
```json
[
  { "name": "Full Name", "value": "Test Sync Demographics" },
  { "name": "Date of Birth", "value": "1990-01-01" },
  { "name": "Gender", "value": "male" },
  { "name": "Email", "value": "test-ehrbase-1762753310@medzen-test.com" },
  { "name": "Phone Number", "value": "+237123456789" },
  { "name": "Country", "value": "Cameroon" },
  { "name": "User Role", "value": "patient" }  ✅ NOW INCLUDED
]
```

**Result:** ✅ All 7 demographic fields verified in EHRbase EHR_STATUS

## Updated Field Count

**Previous:** 6 demographic fields synced
**Current:** 7 demographic fields synced

### Complete Field List:
1. Full Name
2. Date of Birth
3. Gender
4. Email
5. Phone Number
6. Country
7. **User Role** (NEW)

## Integration Points

### Database Trigger
- Reads `user_role` from `electronic_health_records.user_role` column
- Includes in queue `data_snapshot` JSONB object
- No changes to `users` table schema required

### Edge Function
- Processes `user_role` from `data_snapshot`
- Creates OpenEHR ELEMENT with `archetype_node_id: 'at0008'`
- Stores in EHR_STATUS.other_details.items array

### OpenEHR Structure
```json
{
  "_type": "ELEMENT",
  "archetype_node_id": "at0008",
  "name": { "_type": "DV_TEXT", "value": "User Role" },
  "value": { "_type": "DV_TEXT", "value": "patient" }
}
```

## Possible User Role Values

Based on the application's 4-tier user system:
- `patient` - Patient users
- `medical_provider` - Medical providers
- `facility_admin` - Facility administrators
- `system_admin` - System administrators

## Monitoring

### Check User Role in Queue
```sql
SELECT
  id,
  record_id,
  sync_type,
  data_snapshot->>'user_role' as user_role,
  sync_status,
  created_at
FROM ehrbase_sync_queue
WHERE sync_type = 'demographics'
ORDER BY created_at DESC
LIMIT 10;
```

### Verify User Role in EHRbase
```bash
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHR_ID="<ehr_id>"

curl -s "$EHRBASE_URL/rest/openehr/v1/ehr/$EHR_ID/ehr_status" \
  -H "Authorization: Basic $(echo -n 'ehrbase-admin:EvenMoreSecretPassword' | base64)" \
  -H "Accept: application/json" | jq '.other_details.items[] | select(.name.value == "User Role")'
```

### AQL Query for User Role
```sql
SELECT
  e/ehr_id/value as ehr_id,
  e/ehr_status/other_details/items[at0002]/value/value as full_name,
  e/ehr_status/other_details/items[at0008]/value/value as user_role
FROM EHR e
WHERE e/ehr_id/value = '<ehr_id>'
```

## Backward Compatibility

✅ **Fully backward compatible:**
- Existing demographics without user_role will continue to work
- User role is optional (checked with `if (userData.user_role)`)
- No breaking changes to existing records
- Previous demographics entries remain valid

## Production Deployment

✅ **Database Trigger:** Deployed to production (2025-11-10 13:18 UTC)
✅ **Edge Function:** Deployed to production (2025-11-10 13:21 UTC)
✅ **End-to-End Test:** Passed (2025-11-10 13:21 UTC)

## Files Modified

1. ✅ `supabase/migrations/20251110130000_add_user_role_to_demographics_sync.sql` (NEW)
2. ✅ `supabase/functions/sync-to-ehrbase/index.ts` (lines 297-304)
3. ✅ `DEMOGRAPHICS_SYNC_USER_ROLE_UPDATE.md` (this document)

## Next Steps

- [x] Database trigger updated
- [x] Edge function updated and deployed
- [x] End-to-end test passed
- [x] Documentation created
- [ ] Update main DEMOGRAPHICS_SYNC_IMPLEMENTATION.md with user_role reference
- [ ] Update DEMOGRAPHICS_SYNC_SUMMARY.md with 7-field count
- [ ] Update test script to verify user_role field

---

**Update Complete:** User role is now successfully syncing to EHRbase EHR_STATUS.
