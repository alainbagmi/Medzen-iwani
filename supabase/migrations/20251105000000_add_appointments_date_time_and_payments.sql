-- Migration: Add start_date and start_time to appointments, create payments table
-- Date: 2025-11-05
-- Description:
--   1. Add start_date and start_time fields to appointments table
--   2. Create comprehensive payments table with links to all relevant tables
--   3. Set up indexes, constraints, and RLS policies

-- =====================================================
-- PART 1: Update appointments table
-- =====================================================

-- Add start_date and start_time columns to appointments
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS start_date date,
ADD COLUMN IF NOT EXISTS start_time time without time zone;

-- Create indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_appointments_start_date
ON public.appointments USING btree (start_date)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_appointments_start_time
ON public.appointments USING btree (start_time)
TABLESPACE pg_default;

-- Create a composite index for date+time lookups
CREATE INDEX IF NOT EXISTS idx_appointments_start_date_time
ON public.appointments USING btree (start_date, start_time)
TABLESPACE pg_default;

-- Add a function to auto-populate start_date and start_time from scheduled_start
CREATE OR REPLACE FUNCTION sync_appointment_datetime()
RETURNS TRIGGER AS $$
BEGIN
  -- If scheduled_start is set, auto-populate start_date and start_time
  IF NEW.scheduled_start IS NOT NULL THEN
    NEW.start_date := NEW.scheduled_start::date;
    NEW.start_time := NEW.scheduled_start::time;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-sync date/time fields
DROP TRIGGER IF EXISTS sync_appointment_datetime_trigger ON public.appointments;
CREATE TRIGGER sync_appointment_datetime_trigger
  BEFORE INSERT OR UPDATE OF scheduled_start
  ON public.appointments
  FOR EACH ROW
  EXECUTE FUNCTION sync_appointment_datetime();

-- Backfill existing appointments with start_date and start_time
UPDATE public.appointments
SET
  start_date = scheduled_start::date,
  start_time = scheduled_start::time
WHERE scheduled_start IS NOT NULL
  AND (start_date IS NULL OR start_time IS NULL);

-- =====================================================
-- PART 2: Create payments table
-- =====================================================

CREATE TABLE IF NOT EXISTS public.payments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  payment_reference text NOT NULL,
  transaction_id text NULL,
  external_transaction_id text NULL,
  payer_id uuid NULL,
  recipient_id uuid NULL,
  facility_id uuid NULL,
  payment_for text NOT NULL,
  related_service_id text NULL,
  consultation_id uuid NULL,
  prescription_id uuid NULL,
  lab_order_id uuid NULL,
  appointment_id uuid NULL,  -- Added link to appointments
  payment_method text NOT NULL,
  payment_provider_id uuid NULL,
  payment_account_info jsonb NULL DEFAULT '{}'::jsonb,
  gross_amount numeric(10, 2) NOT NULL,
  tax_amount numeric(10, 2) NULL DEFAULT 0,
  service_fee numeric(10, 2) NULL DEFAULT 0,
  processing_fee numeric(10, 2) NULL DEFAULT 0,
  discount_amount numeric(10, 2) NULL DEFAULT 0,
  net_amount numeric(10, 2) NOT NULL,
  currency text NULL DEFAULT 'XAF'::text,
  insurance_coverage_amount numeric(10, 2) NULL DEFAULT 0,
  patient_copay_amount numeric(10, 2) NULL DEFAULT 0,
  deductible_amount numeric(10, 2) NULL DEFAULT 0,
  insurance_claim_id uuid NULL,
  payment_status text NULL DEFAULT 'initiated'::text,
  initiated_at timestamp with time zone NULL DEFAULT now(),
  authorized_at timestamp with time zone NULL,
  completed_at timestamp with time zone NULL,
  failed_at timestamp with time zone NULL,
  expires_at timestamp with time zone NULL DEFAULT (now() + '00:30:00'::interval),
  authorization_code text NULL,
  failure_reason text NULL,
  failure_code text NULL,
  provider_response_code text NULL,
  provider_response_message text NULL,
  refund_amount numeric(10, 2) NULL,
  refund_reason text NULL,
  refunded_at timestamp with time zone NULL,
  refund_reference text NULL,
  reconciled boolean NULL DEFAULT false,
  reconciliation_date date NULL,
  reconciliation_batch_id text NULL,
  receipt_number text NULL,
  receipt_url text NULL,
  invoice_number text NULL,
  invoice_url text NULL,
  risk_score integer NULL DEFAULT 0,
  fraud_check_passed boolean NULL DEFAULT true,
  fraud_check_details jsonb NULL DEFAULT '{}'::jsonb,
  payment_metadata jsonb NULL DEFAULT '{}'::jsonb,
  user_agent text NULL,
  ip_address inet NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  subscription_type text NULL,

  -- Primary key
  CONSTRAINT payments_pkey PRIMARY KEY (id),

  -- Unique constraints
  CONSTRAINT payments_transaction_id_key UNIQUE (transaction_id),
  CONSTRAINT payments_payment_reference_key UNIQUE (payment_reference),

  -- Foreign key constraints
  CONSTRAINT payments_payer_id_fkey FOREIGN KEY (payer_id)
    REFERENCES users (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT payments_recipient_id_fkey FOREIGN KEY (recipient_id)
    REFERENCES users (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT payments_facility_id_fkey FOREIGN KEY (facility_id)
    REFERENCES facilities (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT payments_consultation_id_fkey FOREIGN KEY (consultation_id)
    REFERENCES clinical_consultations (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT payments_prescription_id_fkey FOREIGN KEY (prescription_id)
    REFERENCES prescriptions (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT payments_lab_order_id_fkey FOREIGN KEY (lab_order_id)
    REFERENCES lab_orders (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT payments_appointment_id_fkey FOREIGN KEY (appointment_id)
    REFERENCES appointments (id) ON UPDATE CASCADE ON DELETE SET NULL,
  -- Note: payment_provider_id and insurance_claim_id FKs omitted
  -- (mobile_money_providers and insurance_claims tables don't exist yet)

  -- Check constraints
  CONSTRAINT payments_subscription_type_check CHECK (
    (subscription_type IS NULL) OR (
      subscription_type = ANY (ARRAY[
        'free'::text,
        'basic'::text,
        'premium'::text,
        'family'::text,
        'professional'::text,
        'enterprise'::text,
        'student'::text,
        'senior'::text,
        'trial'::text
      ])
    )
  ),
  CONSTRAINT payments_payment_for_check CHECK (
    payment_for = ANY (ARRAY[
      'consultation'::text,
      'prescription'::text,
      'lab_test'::text,
      'imaging'::text,
      'procedure'::text,
      'appointment_booking'::text,
      'insurance_premium'::text,
      'facility_fee'::text,
      'blood_donation_incentive'::text,
      'subscription'::text,
      'late_fee'::text
    ])
  ),
  CONSTRAINT payments_payment_status_check CHECK (
    payment_status = ANY (ARRAY[
      'initiated'::text,
      'pending'::text,
      'processing'::text,
      'completed'::text,
      'failed'::text,
      'cancelled'::text,
      'refunded'::text,
      'disputed'::text,
      'expired'::text
    ])
  ),
  CONSTRAINT payments_payment_method_check CHECK (
    payment_method = ANY (ARRAY[
      'orange_money'::text,
      'mtn_momo'::text,
      'visa'::text,
      'mastercard'::text,
      'bank_transfer'::text,
      'cash'::text,
      'insurance'::text,
      'credit'::text,
      'voucher'::text,
      'free_service'::text
    ])
  )
) TABLESPACE pg_default;

-- =====================================================
-- PART 3: Create indexes for payments table
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_payments_payer_id
ON public.payments USING btree (payer_id)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_recipient_id
ON public.payments USING btree (recipient_id)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_facility_id
ON public.payments USING btree (facility_id)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_consultation_id
ON public.payments USING btree (consultation_id)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_prescription_id
ON public.payments USING btree (prescription_id)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_appointment_id
ON public.payments USING btree (appointment_id)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_payment_status
ON public.payments USING btree (payment_status)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_created_at
ON public.payments USING btree (created_at)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_created_date_simple
ON public.payments USING btree (created_at)
TABLESPACE pg_default
WHERE (created_at IS NOT NULL);

CREATE INDEX IF NOT EXISTS idx_payments_status_method
ON public.payments USING btree (payment_status, payment_method)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_subscription_type
ON public.payments USING btree (subscription_type)
TABLESPACE pg_default
WHERE (subscription_type IS NOT NULL);

CREATE INDEX IF NOT EXISTS idx_payments_user_created
ON public.payments USING btree (payer_id, created_at)
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_payments_user_subscription_lookup
ON public.payments USING btree (
  payer_id,
  subscription_type,
  payment_status,
  completed_at DESC
) TABLESPACE pg_default
WHERE (subscription_type IS NOT NULL);

-- Index for reconciliation queries
CREATE INDEX IF NOT EXISTS idx_payments_reconciliation
ON public.payments USING btree (reconciled, reconciliation_date)
TABLESPACE pg_default;

-- Index for payment reference lookups
CREATE INDEX IF NOT EXISTS idx_payments_payment_reference
ON public.payments USING btree (payment_reference)
TABLESPACE pg_default;

-- Index for transaction ID lookups
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id
ON public.payments USING btree (transaction_id)
TABLESPACE pg_default
WHERE (transaction_id IS NOT NULL);

-- =====================================================
-- PART 4: Add updated_at trigger for payments
-- =====================================================

-- Create or replace the updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to payments table
DROP TRIGGER IF EXISTS update_payments_updated_at ON public.payments;
CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- PART 5: Row Level Security (RLS) for payments
-- =====================================================

-- Enable RLS on payments table
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own payments (as payer)
CREATE POLICY "Users can view their own payments as payer"
ON public.payments
FOR SELECT
USING (auth.uid() = payer_id);

-- Policy: Users can view payments they received (as recipient)
CREATE POLICY "Users can view payments they received"
ON public.payments
FOR SELECT
USING (auth.uid() = recipient_id);

-- Policy: Service role has full access
CREATE POLICY "Service role has full access to payments"
ON public.payments
FOR ALL
USING (auth.jwt()->>'role' = 'service_role');

-- Policy: Authenticated users can create payments (they will be payer)
CREATE POLICY "Users can create their own payments"
ON public.payments
FOR INSERT
WITH CHECK (auth.uid() = payer_id);

-- Policy: Facility admins can view all payments for their facility
CREATE POLICY "Facility admins can view facility payments"
ON public.payments
FOR SELECT
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

-- Policy: System admins can view all payments
CREATE POLICY "System admins can view all payments"
ON public.payments
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    WHERE sap.user_id = auth.uid()
  )
);

-- =====================================================
-- PART 6: Add EHRbase sync trigger for payments
-- =====================================================

-- Create trigger to queue payment records for EHRbase sync
CREATE OR REPLACE FUNCTION queue_payment_for_sync()
RETURNS TRIGGER AS $$
BEGIN
  -- Only sync completed payments
  IF NEW.payment_status = 'completed' THEN
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      patient_id,
      sync_type,
      sync_status,
      data_snapshot,
      created_at
    ) VALUES (
      'payments',
      NEW.id::text,
      (SELECT patient_id FROM patient_profiles WHERE user_id = NEW.payer_id),
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

-- Add trigger for payments sync
DROP TRIGGER IF EXISTS trigger_queue_payment_for_sync ON public.payments;
CREATE TRIGGER trigger_queue_payment_for_sync
  AFTER INSERT OR UPDATE ON public.payments
  FOR EACH ROW
  WHEN (NEW.payment_status = 'completed')
  EXECUTE FUNCTION queue_payment_for_sync();

-- =====================================================
-- PART 7: Helper functions for payments
-- =====================================================

-- Function to generate unique payment reference
CREATE OR REPLACE FUNCTION generate_payment_reference()
RETURNS TEXT AS $$
DECLARE
  ref TEXT;
  exists BOOLEAN;
BEGIN
  LOOP
    -- Generate reference in format: PAY-YYYYMMDD-XXXXXX
    ref := 'PAY-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
           UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));

    -- Check if it exists
    SELECT EXISTS(SELECT 1 FROM payments WHERE payment_reference = ref) INTO exists;

    EXIT WHEN NOT exists;
  END LOOP;

  RETURN ref;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate net amount
CREATE OR REPLACE FUNCTION calculate_payment_net_amount(
  p_gross_amount NUMERIC,
  p_tax_amount NUMERIC DEFAULT 0,
  p_service_fee NUMERIC DEFAULT 0,
  p_processing_fee NUMERIC DEFAULT 0,
  p_discount_amount NUMERIC DEFAULT 0
)
RETURNS NUMERIC AS $$
BEGIN
  RETURN p_gross_amount +
         COALESCE(p_tax_amount, 0) +
         COALESCE(p_service_fee, 0) +
         COALESCE(p_processing_fee, 0) -
         COALESCE(p_discount_amount, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- PART 8: Create view for payment analytics
-- =====================================================

CREATE OR REPLACE VIEW payment_analytics AS
SELECT
  p.id,
  p.payment_reference,
  p.payer_id,
  up_payer.display_name as payer_name,
  p.recipient_id,
  up_recipient.display_name as recipient_name,
  p.facility_id,
  hf.facility_name as facility_name,
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
  -- Calculate payment duration (initiation to completion)
  CASE
    WHEN p.completed_at IS NOT NULL AND p.initiated_at IS NOT NULL
    THEN EXTRACT(EPOCH FROM (p.completed_at - p.initiated_at))
    ELSE NULL
  END as payment_duration_seconds
FROM payments p
LEFT JOIN user_profiles up_payer ON up_payer.user_id = p.payer_id
LEFT JOIN user_profiles up_recipient ON up_recipient.user_id = p.recipient_id
LEFT JOIN facilities hf ON hf.id = p.facility_id;

-- Grant access to authenticated users (with RLS)
GRANT SELECT ON payment_analytics TO authenticated;

-- =====================================================
-- PART 9: Add comments for documentation
-- =====================================================

COMMENT ON TABLE public.payments IS 'Comprehensive payment tracking system for all financial transactions in the MedZen platform';

COMMENT ON COLUMN public.payments.payment_reference IS 'Unique human-readable payment reference (e.g., PAY-20251105-ABC123)';
COMMENT ON COLUMN public.payments.transaction_id IS 'Internal transaction identifier';
COMMENT ON COLUMN public.payments.external_transaction_id IS 'External payment provider transaction ID';
COMMENT ON COLUMN public.payments.payer_id IS 'User who is making the payment';
COMMENT ON COLUMN public.payments.recipient_id IS 'User who is receiving the payment (provider/facility)';
COMMENT ON COLUMN public.payments.payment_for IS 'Type of service being paid for';
COMMENT ON COLUMN public.payments.payment_status IS 'Current status of the payment transaction';
COMMENT ON COLUMN public.payments.net_amount IS 'Final amount to be charged (gross + fees + tax - discount)';
COMMENT ON COLUMN public.payments.expires_at IS 'When the payment authorization expires (default 30 minutes)';
COMMENT ON COLUMN public.payments.reconciled IS 'Whether this payment has been reconciled with bank statements';
COMMENT ON COLUMN public.payments.fraud_check_passed IS 'Whether the payment passed fraud detection checks';

COMMENT ON FUNCTION generate_payment_reference() IS 'Generates a unique payment reference in format PAY-YYYYMMDD-XXXXXX';
COMMENT ON FUNCTION calculate_payment_net_amount IS 'Calculates the final net amount including all fees and discounts';

-- =====================================================
-- Migration complete
-- =====================================================
-- (Migration tracking handled automatically by Supabase CLI)
