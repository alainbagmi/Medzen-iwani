-- Update all scheduled appointments to December 13, 2025
-- Preserves the time portion of scheduled_start, scheduled_end, and actual_start

UPDATE appointments
SET
  scheduled_start = '2025-12-13'::date + (scheduled_start::time),
  scheduled_end = '2025-12-13'::date + (scheduled_end::time),
  start_date = '2025-12-13'::date,
  actual_start = CASE
    WHEN actual_start IS NOT NULL
    THEN '2025-12-13'::date + (actual_start::time)
    ELSE NULL
  END,
  updated_at = NOW()
WHERE status = 'scheduled';

-- Verify the update
SELECT
  id,
  appointment_number,
  scheduled_start,
  actual_start,
  status
FROM appointments
WHERE status = 'scheduled'
ORDER BY scheduled_start
LIMIT 10;
