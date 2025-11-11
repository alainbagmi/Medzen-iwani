-- =====================================================
-- CRITICAL FIX: Payment Sync Function
-- =====================================================
-- Issue: queue_payment_for_sync() function has TWO errors:
--   1. Tries to INSERT patient_id column that doesn't exist in ehrbase_sync_queue
--   2. Tries to SELECT patient_id from patient_profiles (column doesn't exist there either)
--
-- Root Cause: Migration 20251105000000_add_appointments_date_time_and_payments.sql
--             created the function with incorrect column references
--
-- Fix: Remove the patient_id reference entirely
--      The payment already has payer_id which links to the user
-- =====================================================

-- Replace the function with corrected version
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

-- Add function documentation
COMMENT ON FUNCTION queue_payment_for_sync() IS
'Trigger function to queue completed payment records for EHRbase synchronization.
Only payments with payment_status = ''completed'' are synced to maintain data integrity.
The payment data is stored in data_snapshot as JSONB for offline-first sync.';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these after applying the fix to verify:

-- 1. Check the function was updated correctly
SELECT
  routine_name,
  routine_definition
FROM information_schema.routines
WHERE routine_name = 'queue_payment_for_sync';

-- 2. Verify trigger exists and is active
SELECT
  trigger_name,
  event_manipulation,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_queue_payment_for_sync';

-- 3. Check ehrbase_sync_queue columns (should NOT include patient_id)
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'ehrbase_sync_queue'
ORDER BY ordinal_position;

-- =====================================================
-- TEST QUERY (Optional - only if you want to test)
-- =====================================================
-- This simulates a payment insert to verify the trigger works
-- UNCOMMENT TO TEST (will create actual data):
/*
INSERT INTO payments (
  gross_amount,
  net_amount,
  payer_id,
  payment_for,
  payment_method,
  payment_reference,
  payment_status
) VALUES (
  100.00,
  100.00,
  'some-valid-user-id-here', -- Replace with actual user ID
  'consultation',
  'card',
  'TEST-PAY-' || NOW()::TEXT,
  'completed'
);

-- Then check if it was queued
SELECT * FROM ehrbase_sync_queue
WHERE table_name = 'payments'
ORDER BY created_at DESC
LIMIT 1;
*/

-- =====================================================
-- STATUS: Ready to apply via Supabase Dashboard
-- =====================================================
-- HOW TO APPLY:
-- 1. Go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql
-- 2. Copy this ENTIRE file contents
-- 3. Paste into SQL Editor
-- 4. Click "Run" to execute
-- 5. Verify success with the verification queries above
-- =====================================================
