-- Comprehensive appointment date update - January 13, 2026
-- Updates ALL date fields in appointments table to today
-- Includes: scheduled_start, scheduled_end, actual_start, actual_end, start_date

BEGIN;

-- Update all appointment dates to today (January 13, 2026)
UPDATE appointments
SET
  scheduled_start = COALESCE(
    DATE_TRUNC('day', NOW()::date)::timestamp + (scheduled_start::time),
    NOW()
  ),
  scheduled_end = COALESCE(
    DATE_TRUNC('day', NOW()::date)::timestamp + (scheduled_end::time),
    NOW()
  ),
  actual_start = CASE
    WHEN actual_start IS NOT NULL
    THEN DATE_TRUNC('day', NOW()::date)::timestamp + (actual_start::time)
    ELSE NULL
  END,
  actual_end = CASE
    WHEN actual_end IS NOT NULL
    THEN DATE_TRUNC('day', NOW()::date)::timestamp + (actual_end::time)
    ELSE NULL
  END,
  start_date = NOW()::date,
  start_time = NOW()::time,
  updated_at = NOW();

-- Verify update
DO $$
DECLARE
  v_count INTEGER;
  v_with_actual INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM appointments WHERE DATE(scheduled_start) = DATE(NOW());
  SELECT COUNT(*) INTO v_with_actual FROM appointments WHERE actual_start IS NOT NULL AND DATE(actual_start) = DATE(NOW());

  RAISE NOTICE 'Updated % total appointments to today''s date', v_count;
  RAISE NOTICE 'Appointments with actual_start updated: %', v_with_actual;
END $$;

COMMIT;
