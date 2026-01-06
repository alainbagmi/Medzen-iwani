-- Migration: Fix patient assistant type from 'general' to 'health'
-- Description: Updates the MedX Health Assistant to use the correct assistant_type
-- Date: 2025-12-17
-- Reason: Edge function expects 'health' but database has 'general'

-- Update the existing assistant to use 'health' type
UPDATE ai_assistants
SET
    assistant_type = 'health',
    updated_at = NOW()
WHERE id = 'f11201de-09d6-4876-ac62-fd8eb2e44692'
  AND assistant_name = 'MedX Health Assistant'
  AND assistant_type = 'general';

-- Verify the update
DO $$
DECLARE
    v_assistant_type TEXT;
BEGIN
    SELECT assistant_type INTO v_assistant_type
    FROM ai_assistants
    WHERE id = 'f11201de-09d6-4876-ac62-fd8eb2e44692';

    IF v_assistant_type = 'health' THEN
        RAISE NOTICE 'SUCCESS: MedX Health Assistant updated to type "health"';
    ELSE
        RAISE WARNING 'FAILED: MedX Health Assistant has type "%". Expected "health"', v_assistant_type;
    END IF;
END $$;
