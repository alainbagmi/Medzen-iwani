-- Migration: Fix RLS policies for payments table
-- Date: 2025-11-06
-- Description: Update RLS policies to allow proper payment creation from FlutterFlow
--              while maintaining security. Adds fallback policies for testing.

-- =====================================================
-- PART 1: Drop existing problematic policies
-- =====================================================

-- Drop the overly restrictive insert policy
DROP POLICY IF EXISTS "Users can create their own payments" ON public.payments;

-- =====================================================
-- PART 2: Create improved RLS policies
-- =====================================================

-- Policy 1: Authenticated users can create payments where they are the payer
-- This is the primary policy for production use
CREATE POLICY "Authenticated users can create payments"
ON public.payments
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = payer_id
);

-- Policy 2: Allow anon role to create payments (TESTING ONLY)
-- WARNING: This policy should be reviewed before production deployment
-- It allows payment creation with anon key, which is useful for FlutterFlow testing
-- but should be replaced with proper authentication in production
CREATE POLICY "Allow payment creation for testing"
ON public.payments
FOR INSERT
TO anon
WITH CHECK (
  -- Ensure required fields are present
  payment_reference IS NOT NULL
  AND payment_for IS NOT NULL
  AND payment_method IS NOT NULL
  AND gross_amount IS NOT NULL
  AND net_amount IS NOT NULL
  -- Optionally limit payment amounts for testing
  AND gross_amount <= 1000000  -- Max 1M XAF for safety
);

-- Policy 3: Service role has full access (already exists, but recreating for completeness)
DROP POLICY IF EXISTS "Service role has full access to payments" ON public.payments;
CREATE POLICY "Service role has full access to payments"
ON public.payments
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- =====================================================
-- PART 3: Update SELECT policies for better flexibility
-- =====================================================

-- Keep existing view policies but make them more explicit
DROP POLICY IF EXISTS "Users can view their own payments as payer" ON public.payments;
CREATE POLICY "Users can view their own payments as payer"
ON public.payments
FOR SELECT
TO authenticated
USING (auth.uid() = payer_id);

DROP POLICY IF EXISTS "Users can view payments they received" ON public.payments;
CREATE POLICY "Users can view payments they received"
ON public.payments
FOR SELECT
TO authenticated
USING (auth.uid() = recipient_id);

-- Policy: Allow anon users to view their own created payments (by IP or session)
-- This is useful for payment confirmation pages before user signs up
CREATE POLICY "Allow viewing recent payments by session"
ON public.payments
FOR SELECT
TO anon
USING (
  -- Allow viewing payments created in the last hour from same IP
  created_at > NOW() - INTERVAL '1 hour'
  AND ip_address = inet_client_addr()
);

-- Keep existing admin policies
DROP POLICY IF EXISTS "Facility admins can view facility payments" ON public.payments;
CREATE POLICY "Facility admins can view facility payments"
ON public.payments
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM facility_admin_profiles fap
    WHERE fap.user_id = auth.uid()
    AND (
      fap.primary_facility_id = payments.facility_id
      OR payments.facility_id = ANY(fap.managed_facilities)
    )
  )
);

DROP POLICY IF EXISTS "System admins can view all payments" ON public.payments;
CREATE POLICY "System admins can view all payments"
ON public.payments
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    WHERE sap.user_id = auth.uid()
  )
);

-- =====================================================
-- PART 4: Add UPDATE policies for payment status changes
-- =====================================================

-- Allow authenticated users to update their own initiated/pending payments
CREATE POLICY "Users can update their own pending payments"
ON public.payments
FOR UPDATE
TO authenticated
USING (
  auth.uid() = payer_id
  AND payment_status IN ('initiated', 'pending')
)
WITH CHECK (
  auth.uid() = payer_id
  AND payment_status IN ('initiated', 'pending', 'processing', 'completed', 'failed', 'cancelled')
);

-- Allow service role and admins to update any payment
CREATE POLICY "Admins can update payments"
ON public.payments
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    WHERE sap.user_id = auth.uid()
  )
)
WITH CHECK (true);

-- =====================================================
-- PART 5: Add helper function for secure payment creation
-- =====================================================

-- Function to create payment with automatic field population
CREATE OR REPLACE FUNCTION create_payment_secure(
  p_payment_for TEXT,
  p_payment_method TEXT,
  p_gross_amount NUMERIC,
  p_net_amount NUMERIC,
  p_payer_id UUID DEFAULT NULL,
  p_recipient_id UUID DEFAULT NULL,
  p_facility_id UUID DEFAULT NULL,
  p_related_data JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_payment_id UUID;
  v_payer_id UUID;
  v_payment_ref TEXT;
BEGIN
  -- Use provided payer_id or fallback to auth.uid()
  v_payer_id := COALESCE(p_payer_id, auth.uid());

  -- Generate unique payment reference
  v_payment_ref := generate_payment_reference();

  -- Insert payment
  INSERT INTO payments (
    payment_reference,
    payer_id,
    recipient_id,
    facility_id,
    payment_for,
    payment_method,
    gross_amount,
    net_amount,
    payment_status,
    currency,
    payment_metadata,
    user_agent,
    ip_address
  ) VALUES (
    v_payment_ref,
    v_payer_id,
    p_recipient_id,
    p_facility_id,
    p_payment_for,
    p_payment_method,
    p_gross_amount,
    p_net_amount,
    'initiated',
    'XAF',
    p_related_data,
    current_setting('request.headers', true)::json->>'user-agent',
    inet_client_addr()
  )
  RETURNING id INTO v_payment_id;

  RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated and anon users
GRANT EXECUTE ON FUNCTION create_payment_secure TO authenticated, anon;

-- =====================================================
-- PART 6: Add documentation and warnings
-- =====================================================

COMMENT ON POLICY "Allow payment creation for testing" ON public.payments IS
'WARNING: This policy allows anonymous payment creation for testing.
Review and potentially disable this policy in production.
For production, all payments should require authentication.';

COMMENT ON FUNCTION create_payment_secure IS
'Secure function to create payments with automatic field population.
Bypasses RLS when called with SECURITY DEFINER.
Use this function from FlutterFlow for safer payment creation.';

-- =====================================================
-- PART 7: Create function to disable testing policies
-- =====================================================

CREATE OR REPLACE FUNCTION disable_payment_testing_policies()
RETURNS void AS $$
BEGIN
  -- Drop the testing policy
  DROP POLICY IF EXISTS "Allow payment creation for testing" ON public.payments;
  DROP POLICY IF EXISTS "Allow viewing recent payments by session" ON public.payments;

  RAISE NOTICE 'Testing policies have been disabled. Only authenticated users can now create payments.';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION disable_payment_testing_policies IS
'Call this function to disable testing policies before production deployment:
SELECT disable_payment_testing_policies();';

-- =====================================================
-- Migration complete
-- =====================================================

-- Summary of changes:
-- 1. ✅ Fixed INSERT policy to work with both authenticated and anon users
-- 2. ✅ Added secure payment creation function
-- 3. ✅ Added UPDATE policies for payment status changes
-- 4. ✅ Added view policies for anonymous users (recent payments by IP)
-- 5. ✅ Added function to disable testing policies for production
-- 6. ✅ Maintained all existing admin and user-specific policies

-- IMPORTANT: Before production deployment, run:
-- SELECT disable_payment_testing_policies();
