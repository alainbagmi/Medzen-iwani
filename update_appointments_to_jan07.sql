-- Update all appointments to 2026-01-07 (today)
UPDATE appointments
SET
  scheduled_start = scheduled_start + INTERVAL '1 day',
  scheduled_end = scheduled_end + INTERVAL '1 day',
  start_date = start_date + INTERVAL '1 day'
WHERE start_date < '2026-01-07';

-- Display updated appointments
SELECT
  id,
  appointment_number,
  scheduled_start,
  scheduled_end,
  start_date,
  status
FROM appointments
ORDER BY scheduled_start DESC
LIMIT 10;
