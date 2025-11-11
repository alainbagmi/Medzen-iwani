-- ============================================================================
-- Migration: Remove Payment Sync from EHRbase
-- Date: 2025-11-10
-- ============================================================================
--
-- ARCHITECTURAL DECISION: Payment data is administrative/financial data
-- and should NOT be synced to EHRbase (Electronic Health Records).
--
-- EHRbase Purpose: Clinical data only (vital signs, lab results, diagnoses, etc.)
-- Payments Purpose: Financial/administrative records (billing, insurance, transactions)
--
-- Separation of Concerns:
-- - Clinical records (EHR) = what care was provided
-- - Payment records = who paid and when
--
-- This migration:
-- 1. Disables the payment sync trigger
-- 2. Adds documentation explaining the decision
-- 3. Keeps the function for historical reference
--
-- ============================================================================

-- Drop the trigger that queues payments for EHRbase sync
DROP TRIGGER IF EXISTS trigger_queue_payment_for_sync ON payments;

-- Add table comment documenting the architectural decision
COMMENT ON TABLE payments IS 'Payment records are administrative/financial data and NOT synced to EHRbase. EHR (Electronic Health Records) contains clinical data only. This maintains proper separation between clinical records (what care was provided) and financial records (who paid and when).';

-- Keep the function for historical reference
-- The function queue_payment_for_sync() remains in the database but is no longer triggered
COMMENT ON FUNCTION queue_payment_for_sync() IS 'Historical function - no longer in use. Payment data is administrative and should not be synced to EHRbase. Kept for reference only.';

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After this migration:
-- ✅ Trigger removed: SELECT * FROM pg_trigger WHERE tgname = 'trigger_queue_payment_for_sync'; (should be empty)
-- ✅ Function preserved: SELECT proname FROM pg_proc WHERE proname = 'queue_payment_for_sync'; (should exist)
-- ✅ Comment added: SELECT obj_description('payments'::regclass);
--
-- Total active EHR sync functions: 22 (previously 23)
-- ============================================================================
