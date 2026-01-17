-- Update all appointment dates to today (January 13, 2026)
-- Preserves the time component, only changes the date
-- Migration created: January 13, 2026

BEGIN;

-- Update appointments table
-- Keep the time component, change date to today
UPDATE appointments
SET
  scheduled_start = DATE_TRUNC('day', NOW()::date)::timestamp + (scheduled_start::time),
  scheduled_end = DATE_TRUNC('day', NOW()::date)::timestamp + (scheduled_end::time),
  updated_at = NOW()
WHERE scheduled_start IS NOT NULL
  AND scheduled_end IS NOT NULL;

-- Log the update
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM appointments WHERE DATE(scheduled_start) = DATE(NOW());
  RAISE NOTICE 'Updated % appointments to today''s date', v_count;
END $$;

COMMIT;
