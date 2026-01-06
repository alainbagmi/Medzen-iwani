-- Migration: Add model_config to health assistant
-- Description: Add model configuration for patient health assistant
-- Date: 2025-12-17

-- Add model_config for health assistant (patient)
UPDATE ai_assistants
SET model_config = jsonb_build_object(
  'temperature', 0.7,
  'max_tokens', 2048,
  'top_p', 0.9
),
updated_at = NOW()
WHERE assistant_type = 'health';

-- Verify the update
DO $$
DECLARE
    v_config JSONB;
BEGIN
    SELECT model_config INTO v_config
    FROM ai_assistants
    WHERE assistant_type = 'health';

    IF v_config IS NOT NULL THEN
        RAISE NOTICE 'SUCCESS: Health assistant now has model_config: %', v_config;
    ELSE
        RAISE WARNING 'FAILED: Health assistant still missing model_config';
    END IF;
END $$;
