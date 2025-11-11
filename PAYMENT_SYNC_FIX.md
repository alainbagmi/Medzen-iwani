# Payment Sync Function Fix

**Date:** 2025-11-06
**Issue:** `queue_payment_for_sync()` function error blocking payment insertions
**Error:** `column "patient_id" of relation "ehrbase_sync_queue" does not exist`

---

## Problem Analysis

The `queue_payment_for_sync()` trigger function (created in migration `20251105000000_add_appointments_date_time_and_payments.sql`) contains two errors:

1. **Tries to INSERT into non-existent column:** The function attempts to insert into `ehrbase_sync_queue.patient_id`, but this column doesn't exist in the table.

2. **References non-existent column in subquery:** The function tries to SELECT `patient_id` from `patient_profiles`, but that table only has `user_id`, not `patient_id`.

**Actual `ehrbase_sync_queue` Schema:**
```
- id
- table_name
- record_id
- template_id
- sync_status
- retry_count
- error_message
- ehrbase_composition_id
- created_at
- processed_at
- user_role
- composition_category
- sync_type
- data_snapshot
- last_retry_at
- updated_at
```

**No `patient_id` column exists.**

---

## Impact

**Status:** 🔴 **CRITICAL - Blocking payment insertions**

When a payment with `payment_status = 'completed'` is inserted:
1. Trigger `trigger_queue_payment_for_sync` fires
2. Function `queue_payment_for_sync()` executes
3. INSERT into `ehrbase_sync_queue` fails with error: `column "patient_id" does not exist`
4. **Payment insertion fails** (transaction rolls back)

---

## Solution

Remove the `patient_id` column reference from the function. The sync queue doesn't need it because:
- Payment records already have `payer_id` linking to the user
- Sync queue identifies records via `table_name` + `record_id`
- Other sync trigger functions don't use `patient_id`

---

## SQL Fix (Execute in Supabase Dashboard)

**Steps:**
1. Navigate to: **Supabase Dashboard → SQL Editor**
2. Paste the SQL below
3. Click **Run** (or press Cmd/Ctrl + Enter)
4. Verify "Success" message

**SQL to Execute:**

```sql
-- =====================================================
-- Fix queue_payment_for_sync Function
-- =====================================================
-- Remove patient_id reference that doesn't exist
-- Date: 2025-11-06

CREATE OR REPLACE FUNCTION queue_payment_for_sync()
RETURNS TRIGGER AS $$
BEGIN
  -- Only sync completed payments
  IF NEW.payment_status = 'completed' THEN
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      sync_type,
      sync_status,
      data_snapshot,
      created_at
    ) VALUES (
      'payments',
      NEW.id::text,
      CASE WHEN TG_OP = 'INSERT' THEN 'create' ELSE 'update' END,
      'pending',
      row_to_json(NEW),
      NOW()
    )
    ON CONFLICT (table_name, record_id)
    DO UPDATE SET
      sync_status = 'pending',
      data_snapshot = row_to_json(NEW),
      updated_at = NOW(),
      retry_count = 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Verification

After applying the fix, verify the function was updated:

```sql
-- Check function exists and has correct definition
SELECT
  routine_name,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'queue_payment_for_sync';
```

**Expected:** Function definition should NOT contain `patient_id`.

---

## Testing

Test the fix by inserting a completed payment:

```sql
-- Test payment insertion (should succeed now)
INSERT INTO public.payments (
  payment_reference,
  payer_id,
  payment_for,
  payment_method,
  gross_amount,
  net_amount,
  payment_status
) VALUES (
  'TEST-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6),
  (SELECT id FROM users LIMIT 1),  -- Use any existing user ID
  'consultation',
  'cash',
  10000,
  10000,
  'completed'
);

-- Verify payment was created
SELECT id, payment_reference, payment_status, created_at
FROM payments
WHERE payment_reference LIKE 'TEST-%'
ORDER BY created_at DESC
LIMIT 1;

-- Verify sync queue entry was created
SELECT table_name, record_id, sync_status, created_at
FROM ehrbase_sync_queue
WHERE table_name = 'payments'
ORDER BY created_at DESC
LIMIT 1;

-- Clean up test payment (optional)
DELETE FROM payments WHERE payment_reference LIKE 'TEST-%';
```

**Expected Results:**
1. ✅ Payment inserted successfully
2. ✅ Sync queue entry created with `table_name = 'payments'`
3. ✅ No errors in response

---

## Original Error Context

**Error Log:**
```
{
  "severity": "ERROR",
  "error": "column \"patient_id\" of relation \"ehrbase_sync_queue\" does not exist",
  "code": "42703",
  "detail": null,
  "hint": null,
  "context": "PL/pgSQL function queue_payment_for_sync() line 5 at SQL statement",
  "query": "INSERT INTO \"public\".\"payments\"(...) VALUES (...)"
}
```

**Function Location:** `supabase/migrations/20251105000000_add_appointments_date_time_and_payments.sql` (lines 371-403)

---

## Migration File Created

**File:** `supabase/migrations/20251106210000_fix_queue_payment_for_sync_function.sql`

**Status:** ✅ Created, ready for future reference

**Note:** Due to migration ordering issues, this fix should be applied manually via Dashboard rather than via `npx supabase db push`.

---

## Files Reference

| File | Purpose | Status |
|------|---------|--------|
| `20251105000000_add_appointments_date_time_and_payments.sql` | Original migration with bug | ⚠️ Contains error |
| `20251106210000_fix_queue_payment_for_sync_function.sql` | Corrective migration | ✅ Created |
| `PAYMENT_SYNC_FIX.md` | This document | ✅ Documentation |

---

## Related Issues

This is similar to a previous schema mismatch issue where other sync trigger functions had UUID casting problems (fixed in migration `20251103200001_fix_all_sync_functions_comprehensive.sql`).

**Pattern:** Sync trigger functions must match the actual `ehrbase_sync_queue` schema exactly.

---

**Status:** ⏳ **Awaiting Manual Execution**
**Priority:** 🔴 **HIGH** - Blocking payment insertions
**Time Required:** 2-3 minutes

---

**Last Updated:** 2025-11-06
**Issue Tracker:** Payment sync function schema mismatch
