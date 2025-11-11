-- Hotfix: Remove patient_id reference from queue_payment_for_sync function
-- Date: 2025-11-07
-- Issue: Function tries to insert patient_id into ehrbase_sync_queue, but column doesn't exist
-- This is a critical hotfix to restore payment processing functionality

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

-- Add comment for documentation
COMMENT ON FUNCTION queue_payment_for_sync() IS
'Queues completed payment records for EHRbase synchronization.
Only payments with status=completed are synced to maintain data integrity.';
