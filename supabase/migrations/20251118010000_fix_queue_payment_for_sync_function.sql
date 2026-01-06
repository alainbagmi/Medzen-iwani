-- Migration: Fix queue_payment_for_sync function
-- Date: 2025-11-06
-- Description: Remove patient_id reference that doesn't exist in ehrbase_sync_queue table
--
-- Issue: The function tries to insert patient_id into ehrbase_sync_queue, but:
--   1. ehrbase_sync_queue table doesn't have a patient_id column
--   2. patient_profiles table doesn't have a patient_id column (it has user_id)
--
-- Fix: Remove patient_id from the INSERT statement since it's not needed.
--      The payment record already has payer_id which links to the user.

-- =====================================================
-- Fix the queue_payment_for_sync function
-- =====================================================

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

-- =====================================================
-- Verification query
-- =====================================================
-- After applying this migration, you can verify with:
--
-- SELECT routine_name, routine_definition
-- FROM information_schema.routines
-- WHERE routine_name = 'queue_payment_for_sync';
--
-- Then test by inserting a payment with status 'completed'
-- =====================================================
