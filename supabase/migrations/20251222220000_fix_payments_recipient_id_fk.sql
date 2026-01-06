-- Migration: Fix payments.recipient_id Foreign Key
-- Date: December 22, 2025
-- Purpose: Change recipient_id FK from users(id) to medical_provider_profiles(id)
--
-- This aligns with the appointments table change where provider_id now
-- references medical_provider_profiles(id) instead of users(id)

-- =====================================================
-- PART 1: Drop existing FK constraint
-- =====================================================

DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Find the FK constraint name for recipient_id column
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    WHERE tc.table_name = 'payments'
        AND tc.table_schema = 'public'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'recipient_id';

    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE public.payments DROP CONSTRAINT %I', constraint_name);
        RAISE NOTICE 'Dropped FK constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No existing FK constraint found on recipient_id';
    END IF;
END $$;

-- =====================================================
-- PART 2: Update existing data
-- =====================================================

-- Convert any recipient_id values that are user IDs to medical_provider_profile IDs
DO $$
DECLARE
    updated_count integer;
BEGIN
    UPDATE payments p
    SET recipient_id = mpp.id
    FROM medical_provider_profiles mpp
    WHERE p.recipient_id = mpp.user_id
    AND NOT EXISTS (
        SELECT 1 FROM medical_provider_profiles
        WHERE id = p.recipient_id
    );

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count > 0 THEN
        RAISE NOTICE 'Corrected % payments with user_id as recipient_id', updated_count;
    ELSE
        RAISE NOTICE 'No payments needed recipient_id correction';
    END IF;
END $$;

-- Set recipient_id to NULL for orphaned records
DO $$
DECLARE
    nullified_count integer;
BEGIN
    UPDATE payments
    SET recipient_id = NULL
    WHERE recipient_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM medical_provider_profiles
        WHERE id = payments.recipient_id
    );

    GET DIAGNOSTICS nullified_count = ROW_COUNT;

    IF nullified_count > 0 THEN
        RAISE WARNING 'Set % orphaned recipient_id values to NULL', nullified_count;
    END IF;
END $$;

-- =====================================================
-- PART 3: Add new FK constraint
-- =====================================================

ALTER TABLE public.payments
ADD CONSTRAINT payments_recipient_id_fkey
FOREIGN KEY (recipient_id)
REFERENCES public.medical_provider_profiles(id)
ON UPDATE CASCADE
ON DELETE SET NULL;

-- Create index for better join performance
CREATE INDEX IF NOT EXISTS idx_payments_recipient_id
ON public.payments (recipient_id);

-- =====================================================
-- PART 4: Update payment_analytics view if it exists
-- =====================================================

-- Drop and recreate the view with correct join logic
DROP VIEW IF EXISTS payment_analytics CASCADE;

CREATE OR REPLACE VIEW payment_analytics AS
SELECT
    p.id,
    p.payment_reference,
    p.payer_id,
    u_payer.first_name || ' ' || u_payer.last_name AS payer_name,
    p.recipient_id,
    -- Recipient is now a medical_provider_profiles.id
    mpp.id AS recipient_profile_id,
    mpp.user_id AS recipient_user_id,
    u_recipient.first_name || ' ' || u_recipient.last_name AS recipient_name,
    mpp.professional_role AS recipient_role,
    p.facility_id,
    f.facility_name AS facility_name,
    p.payment_for,
    p.payment_method,
    p.payment_status,
    p.gross_amount,
    p.net_amount,
    p.currency,
    p.subscription_type,
    p.initiated_at,
    p.completed_at,
    p.created_at,
    CASE
        WHEN p.completed_at IS NOT NULL AND p.initiated_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (p.completed_at - p.initiated_at))
        ELSE NULL
    END AS payment_duration_seconds
FROM payments p
LEFT JOIN users u_payer ON u_payer.id = p.payer_id
LEFT JOIN medical_provider_profiles mpp ON mpp.id = p.recipient_id
LEFT JOIN users u_recipient ON u_recipient.id = mpp.user_id
LEFT JOIN facilities f ON f.id = p.facility_id;

GRANT SELECT ON payment_analytics TO authenticated;

-- =====================================================
-- PART 5: Update RLS policies
-- =====================================================

-- Drop existing recipient policy
DROP POLICY IF EXISTS "Users can view payments they received" ON payments;

-- Recreate policy using medical_provider_profiles lookup
CREATE POLICY "Providers can view payments they received"
ON payments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM medical_provider_profiles mpp
        WHERE mpp.id = recipient_id
        AND mpp.user_id = auth.uid()
    )
);

-- =====================================================
-- PART 6: Document the change
-- =====================================================

COMMENT ON COLUMN payments.recipient_id IS 'References medical_provider_profiles.id (NOT users.id). The payment recipient is the medical provider.';

-- =====================================================
-- Migration Complete
-- =====================================================
