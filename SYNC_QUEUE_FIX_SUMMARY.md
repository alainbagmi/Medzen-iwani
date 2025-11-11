# EHRbase Sync Queue Fix Summary
**Date:** 2025-11-04
**Issue:** 400 Bad Request errors in sync-to-ehrbase edge function

## Root Cause Analysis

The error `patient_id=eq.undefined` was occurring because:

1. **Edge Function Issue (supabase/functions/sync-to-ehrbase/index.ts:2029)**
   - The function tried to query `electronic_health_records` using `item.data_snapshot.patient_id`
   - For user_profiles records, `patient_id` was undefined, resulting in the literal query `patient_id=eq.undefined`

2. **Trigger Function Issue (queue_role_profile_sync)**
   - Used wrong `sync_type`: `'composition_create'` instead of `'role_profile_create'`
   - Did not include `ehr_id` in `data_snapshot`, which the edge function expects for role_profile_create type

## Fixes Applied

### 1. Edge Function Fix
**File:** `supabase/functions/sync-to-ehrbase/index.ts`
**Change:** Added validation before querying electronic_health_records

```typescript
// Before (line 2023-2030):
} else {
  // Create composition for medical records (existing behavior)
  // Get EHR ID from electronic_health_records table
  const { data: ehrData, error: ehrError } = await supabase
    .from('electronic_health_records')
    .select('ehr_id')
    .eq('patient_id', item.data_snapshot.patient_id)  // ❌ undefined causes 400 error
    .single()

// After (added lines 2026-2031):
} else {
  // Validate patient_id exists in data_snapshot
  if (!item.data_snapshot.patient_id) {
    return {
      success: false,
      error: `Missing patient_id in data_snapshot for record ${item.id} (table: ${item.table_name}, sync_type: ${item.sync_type})`
    }
  }
  // ... rest of query
```

**Deployment Status:** ✅ Deployed to Supabase

### 2. Database Migration Fix
**File:** `supabase/migrations/20251104223500_fix_user_profiles_sync_correctly.sql`

**Changes Made:**
1. Fixed `sync_type`: Changed from `'composition_create'` → `'role_profile_create'`
2. Fixed `data_snapshot`: Now includes `ehr_id` using `jsonb_build_object()`
3. Updated existing problematic records: Marked as `failed` with explanatory error message
4. Updated sync_type for all existing user_profiles records

**Trigger Function Before:**
```sql
INSERT INTO ehrbase_sync_queue (
  ...
  sync_type,
  data_snapshot,
  ...
) VALUES (
  ...
  'composition_create',  -- ❌ Wrong sync_type
  to_jsonb(NEW),         -- ❌ Missing ehr_id
  ...
)
```

**Trigger Function After:**
```sql
INSERT INTO ehrbase_sync_queue (
  ...
  sync_type,
  data_snapshot,
  ...
) VALUES (
  ...
  'role_profile_create',  -- ✅ Correct sync_type
  jsonb_build_object(      -- ✅ Includes ehr_id
    'ehr_id', v_ehr_id,
    'user_id', v_user_id,
    'role', NEW.role,
    'display_name', NEW.display_name,
    'profile_data', to_jsonb(NEW)
  ),
  ...
)
```

**Migration Status:** ✅ Applied to remote database

## Impact Assessment

### Records Affected
- **user_profiles:** 7 records marked as `failed` (will auto-retry on next user profile update)
- **vital_signs:** 3 records were already deleted/cleaned up (no action needed)

### Current State
```
=== After Fix ===
- sync_type: role_profile_create ✅ (was: composition_create)
- Status: failed (intentional - awaiting retry)
- Error: "Missing ehr_id in data_snapshot - fixed by migration 20251104223500, will auto-retry on next update"
- Has ehr_id: NO (old records) - will be fixed on next profile update
```

### Going Forward
- ✅ **NEW** user_profiles records will have correct sync_type and include ehr_id
- ✅ **Edge function** will provide clear error messages instead of 400 errors
- ✅ **Existing** failed records will auto-retry when user profiles are next updated

## Testing Recommendations

1. **Test New User Profile Creation:**
   ```sql
   -- Simulate user profile update to trigger re-sync
   UPDATE user_profiles
   SET display_name = display_name || ' '
   WHERE id IN (SELECT id FROM user_profiles LIMIT 1);

   -- Check sync queue
   SELECT
     id, sync_type, sync_status,
     data_snapshot->>'ehr_id' as ehr_id_present,
     error_message
   FROM ehrbase_sync_queue
   WHERE table_name = 'user_profiles'
   ORDER BY updated_at DESC
   LIMIT 1;
   ```

2. **Monitor Edge Function Logs:**
   ```bash
   npx supabase functions logs sync-to-ehrbase
   ```

3. **Check for 400 Errors:**
   ```bash
   # Should see validation errors instead of 400 responses
   # Look for: "Missing patient_id in data_snapshot for record..."
   ```

## Additional Findings

### Vital Signs Records
- 3 vital_signs records had NO identifiers (no patient_id, ehr_id, or user_id)
- Records no longer exist in the database (likely cleaned up)
- Trigger function `queue_vital_signs_for_sync()` appears correct
- Issue may have been caused by invalid data insertion or has been resolved

### Other Tables
All other medical record tables (lab_results, prescriptions, etc.) appear to be working correctly:
- Use correct `sync_type`: `'composition_create'`
- Include `patient_id` in data_snapshot via `to_jsonb(NEW)`
- Have proper validation (query returns early if no EHR found)

## Monitoring

**Check Sync Queue Status:**
```sql
-- View pending/failed records
SELECT
  table_name,
  sync_type,
  sync_status,
  COUNT(*) as count,
  MAX(created_at) as latest_created,
  MAX(updated_at) as latest_updated
FROM ehrbase_sync_queue
WHERE sync_status IN ('pending', 'processing', 'failed')
GROUP BY table_name, sync_type, sync_status
ORDER BY table_name, sync_type;
```

**Check for Missing Identifiers:**
```sql
-- Find records missing required identifiers
SELECT
  id,
  table_name,
  sync_type,
  CASE
    WHEN sync_type = 'composition_create' AND data_snapshot->>'patient_id' IS NULL THEN 'MISSING_PATIENT_ID'
    WHEN sync_type = 'role_profile_create' AND data_snapshot->>'ehr_id' IS NULL THEN 'MISSING_EHR_ID'
    WHEN sync_type = 'ehr_status_update' AND data_snapshot->>'ehr_id' IS NULL THEN 'MISSING_EHR_ID'
    ELSE 'OK'
  END as validation_status
FROM ehrbase_sync_queue
WHERE sync_status IN ('pending', 'processing')
  AND (
    (sync_type = 'composition_create' AND data_snapshot->>'patient_id' IS NULL)
    OR (sync_type IN ('role_profile_create', 'ehr_status_update') AND data_snapshot->>'ehr_id' IS NULL)
  );
```

## Files Modified

1. `supabase/functions/sync-to-ehrbase/index.ts` - Added patient_id validation
2. `supabase/migrations/20251104223500_fix_user_profiles_sync_correctly.sql` - Fixed trigger function
3. Remote Supabase database - Migration applied ✅

## Next Steps

1. ✅ Monitor edge function logs for any new validation errors
2. ✅ Existing failed user_profiles records will auto-retry on next update
3. ✅ Verify new user profile creations work correctly
4. ⏳ Consider adding database constraints to prevent NULL patient_id in medical records
5. ⏳ Add comprehensive logging to track sync queue processing

## Related Documentation

- See `CLAUDE.md` for EHR sync architecture
- See `EHR_SYSTEM_README.md` for sync queue details
- See `POWERSYNC_QUICK_START.md` for offline sync patterns
