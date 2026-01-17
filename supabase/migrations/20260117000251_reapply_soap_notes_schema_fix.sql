-- Reapply: Add missing columns to soap_notes table
-- This migration ensures schema columns exist for view creation
-- Must run BEFORE 20260117000300_create_soap_notes_full_view.sql
-- Date: 2026-01-17 00:25 UTC

-- Add missing columns that should have been in the original schema
-- These are needed for Phase 2.2 SOAP Note Normalization

-- COLUMN ADDITIONS (idempotent with IF NOT EXISTS)
ALTER TABLE IF EXISTS public.soap_notes
  ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_real_time_draft BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS encounter_type VARCHAR(50) CHECK (encounter_type IN ('telemedicine_video', 'telemedicine_audio', 'in_person')),
  ADD COLUMN IF NOT EXISTS visit_type VARCHAR(50) CHECK (visit_type IN ('new_patient', 'follow_up', 'urgent')),
  ADD COLUMN IF NOT EXISTS reason_for_visit TEXT,
  ADD COLUMN IF NOT EXISTS consent_obtained BOOLEAN,
  ADD COLUMN IF NOT EXISTS consent_timestamp TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS language_used VARCHAR(10),
  ADD COLUMN IF NOT EXISTS ai_confidence_score DECIMAL(3,2),
  ADD COLUMN IF NOT EXISTS ai_raw_response JSONB,
  ADD COLUMN IF NOT EXISTS provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS patient_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS signed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS signed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS signature_hash VARCHAR(255),
  ADD COLUMN IF NOT EXISTS ehr_sync_status VARCHAR(50) DEFAULT 'pending' CHECK (ehr_sync_status IN ('pending', 'in_progress', 'completed', 'failed')),
  ADD COLUMN IF NOT EXISTS ehr_sync_error TEXT,
  ADD COLUMN IF NOT EXISTS synced_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ehrbase_composition_uid VARCHAR(255);

-- DATA MIGRATION (from old column name if it exists)
UPDATE public.soap_notes
SET ai_raw_response = ai_raw_json
WHERE ai_raw_json IS NOT NULL AND ai_raw_response IS NULL
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='soap_notes' AND column_name='ai_raw_json');

-- STATUS VALUE MIGRATION
UPDATE public.soap_notes
SET status = CASE
  WHEN status = 'draft' THEN 'draft'
  WHEN status = 'submitted' THEN 'signed'
  WHEN status = 'archived' THEN 'completed'
  ELSE status
END
WHERE status NOT IN ('precall_draft', 'draft', 'in_progress', 'completed', 'signed', 'synced');

-- INDEX CREATION
CREATE INDEX IF NOT EXISTS idx_soap_notes_provider_id
  ON public.soap_notes(provider_id);

CREATE INDEX IF NOT EXISTS idx_soap_notes_patient_id
  ON public.soap_notes(patient_id);

CREATE INDEX IF NOT EXISTS idx_soap_notes_version
  ON public.soap_notes(version DESC);

CREATE INDEX IF NOT EXISTS idx_soap_notes_ehr_sync_status
  ON public.soap_notes(ehr_sync_status);

CREATE INDEX IF NOT EXISTS idx_soap_notes_signed_at
  ON public.soap_notes(signed_at DESC);

-- PERMISSIONS
GRANT SELECT ON public.soap_notes TO anon, authenticated;
GRANT ALL ON public.soap_notes TO service_role;
