-- Update all appointment dates to today (2026-01-15) while preserving times
UPDATE appointments
SET
  scheduled_start = NOW()::date::timestamp + (scheduled_start::time),
  scheduled_end = NOW()::date::timestamp + (scheduled_end::time),
  actual_start = CASE
    WHEN actual_start IS NOT NULL
    THEN NOW()::date::timestamp + (actual_start::time)
    ELSE NULL
  END,
  actual_end = CASE
    WHEN actual_end IS NOT NULL
    THEN NOW()::date::timestamp + (actual_end::time)
    ELSE NULL
  END,
  start_date = NOW()::date,
  updated_at = NOW()
WHERE scheduled_start IS NOT NULL;
