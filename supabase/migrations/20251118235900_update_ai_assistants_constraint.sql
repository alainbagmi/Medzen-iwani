-- Migration: Update ai_assistants constraint to allow 'health' type
-- Purpose: Allows the MedX Health Assistant to be seeded with assistant_type='health'
-- Fixes: Constraint violation blocking 20251119000000_seed_ai_assistants.sql
-- Date: 2025-11-27

-- Drop the existing constraint if it exists
ALTER TABLE ai_assistants
DROP CONSTRAINT IF EXISTS ai_assistants_assistant_type_check;

-- Recreate the constraint with 'health' added to allowed values
ALTER TABLE ai_assistants
ADD CONSTRAINT ai_assistants_assistant_type_check
CHECK (assistant_type IN ('symptom_checker', 'appointment_booking', 'health_education', 'general', 'health'));

-- Add comment explaining the constraint
COMMENT ON CONSTRAINT ai_assistants_assistant_type_check ON ai_assistants
IS 'Validates assistant_type values. Includes health type for MedX Health Assistant.';
