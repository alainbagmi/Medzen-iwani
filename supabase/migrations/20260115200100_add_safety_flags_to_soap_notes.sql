-- Migration: Add safety_flags column to soap_notes table
-- Description: Adds the safety_flags column that was expected by generate-soap-from-transcript function

-- =====================================================
-- Add missing safety_flags column
-- =====================================================
ALTER TABLE soap_notes 
ADD COLUMN IF NOT EXISTS safety_flags JSONB;

-- Add comment for documentation
COMMENT ON COLUMN soap_notes.safety_flags IS 'Safety flags, red flags, allergies, contraindications from SOAP note';
