-- Migration: AI Chat Production Ready
-- Date: 2025-12-18
-- Purpose: Add 4 role-based AI assistants with different models, language support with 12 African languages

-- ============================================================================
-- PHASE 1: Update ai_assistants table constraints
-- ============================================================================

-- Drop existing constraint and add expanded one with new assistant types
ALTER TABLE ai_assistants
DROP CONSTRAINT IF EXISTS ai_assistants_assistant_type_check;

ALTER TABLE ai_assistants
ADD CONSTRAINT ai_assistants_assistant_type_check
CHECK (assistant_type IN (
  'symptom_checker',
  'appointment_booking',
  'health_education',
  'general',
  'health',      -- For patients (Nova Pro)
  'clinical',    -- For medical providers (Claude 3 Sonnet)
  'operations',  -- For facility admins (Nova Lite)
  'platform'     -- For system admins (Nova Lite)
));

-- Add is_active column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'ai_assistants' AND column_name = 'is_active'
  ) THEN
    ALTER TABLE ai_assistants ADD COLUMN is_active BOOLEAN DEFAULT true;
  END IF;
END $$;

-- Add model_config column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'ai_assistants' AND column_name = 'model_config'
  ) THEN
    ALTER TABLE ai_assistants ADD COLUMN model_config JSONB DEFAULT '{"temperature": 0.7, "top_p": 0.9, "max_tokens": 2048}'::jsonb;
  END IF;
END $$;

-- ============================================================================
-- PHASE 2: Add preferred_language to ai_conversations
-- ============================================================================

-- Add preferred_language column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'ai_conversations' AND column_name = 'preferred_language'
  ) THEN
    ALTER TABLE ai_conversations ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'auto';
  END IF;
END $$;

-- Drop and recreate language constraint with all 12 African languages
ALTER TABLE ai_conversations
DROP CONSTRAINT IF EXISTS valid_language_preference;

ALTER TABLE ai_conversations
ADD CONSTRAINT valid_language_preference
CHECK (preferred_language IN (
  'auto',  -- Auto-detect language
  'en',    -- English
  'fr',    -- French
  'ar',    -- Arabic
  'sw',    -- Swahili (Kenya, Tanzania)
  'ha',    -- Hausa (Nigeria, Niger)
  'yo',    -- Yoruba (Nigeria)
  'ff',    -- Fulfulde/Fula (West Africa)
  'pcm',   -- Nigerian Pidgin
  'rw',    -- Kinyarwanda (Rwanda)
  'am',    -- Amharic (Ethiopia)
  'af',    -- Afrikaans (South Africa)
  'sg'     -- Sango (Central African Republic)
));

-- ============================================================================
-- PHASE 3: AI Assistants seeding moved to separate migration
-- See: 20251218160000_fix_ai_assistants_upsert.sql
-- ============================================================================

-- ============================================================================
-- PHASE 4: Create index for efficient assistant lookup
-- ============================================================================

-- Index for looking up active assistants by type
CREATE INDEX IF NOT EXISTS idx_ai_assistants_type_active
ON ai_assistants(assistant_type, is_active)
WHERE is_active = true;

-- Index for conversation language preferences
CREATE INDEX IF NOT EXISTS idx_ai_conversations_language
ON ai_conversations(preferred_language)
WHERE preferred_language != 'auto';

-- ============================================================================
-- PHASE 5: Verify migration success
-- ============================================================================

-- This will show all 4 assistants after migration
DO $$
DECLARE
  assistant_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO assistant_count
  FROM ai_assistants
  WHERE assistant_type IN ('health', 'clinical', 'operations', 'platform')
    AND is_active = true;

  IF assistant_count < 4 THEN
    RAISE WARNING 'Expected 4 assistants, found %', assistant_count;
  ELSE
    RAISE NOTICE 'Migration successful: % role-based assistants configured', assistant_count;
  END IF;
END $$;
