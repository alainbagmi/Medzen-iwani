-- Migration: Update ai_assistants table with role-specific models
-- Phase 1: Database Configuration Updates
-- Plan ID: crystalline-moseying-bengio
-- Date: 2025-12-11

-- Add model_config column if it doesn't exist
ALTER TABLE ai_assistants
ADD COLUMN IF NOT EXISTS model_config JSONB;

-- Update ai_assistants table with role-specific models
UPDATE ai_assistants
SET model_version = 'eu.amazon.nova-pro-v1:0'
WHERE assistant_type = 'health';  -- Patient

UPDATE ai_assistants
SET model_version = 'eu.anthropic.claude-opus-4-5-20251101-v1:0'
WHERE assistant_type = 'clinical';  -- Medical Provider

UPDATE ai_assistants
SET model_version = 'eu.amazon.nova-micro-v1:0'
WHERE assistant_type = 'operations';  -- Facility Admin

UPDATE ai_assistants
SET model_version = 'eu.amazon.nova-pro-v1:0'
WHERE assistant_type = 'platform';  -- System Admin

-- Add model_config for each assistant
UPDATE ai_assistants
SET model_config = jsonb_build_object(
  'temperature', 0.7,
  'max_tokens', 2048,
  'top_p', 0.9
)
WHERE assistant_type = 'health';

UPDATE ai_assistants
SET model_config = jsonb_build_object(
  'temperature', 0.3,
  'max_tokens', 4096,
  'top_p', 0.95
)
WHERE assistant_type = 'clinical';

UPDATE ai_assistants
SET model_config = jsonb_build_object(
  'temperature', 0.5,
  'max_tokens', 1024,
  'top_p', 0.85
)
WHERE assistant_type = 'operations';

UPDATE ai_assistants
SET model_config = jsonb_build_object(
  'temperature', 0.7,
  'max_tokens', 2048,
  'top_p', 0.9
)
WHERE assistant_type = 'platform';
