-- Update all appointments to December 16, 2025 (today)
-- Preserves the time portion of scheduled_start, scheduled_end, and actual_start

-- First, let's see what appointments exist
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

-- Update all appointments to today while preserving time components
UPDATE appointments
SET
  scheduled_start = '2025-12-16'::date + (scheduled_start::time),
  scheduled_end = '2025-12-16'::date + (scheduled_end::time),
  start_date = '2025-12-16'::date,
  actual_start = CASE
    WHEN actual_start IS NOT NULL
    THEN '2025-12-16'::date + (actual_start::time)
    ELSE NULL
  END,
  updated_at = NOW()
WHERE DATE(scheduled_start) != '2025-12-16'::date;

-- Verify the updates
SELECT
  id,
  appointment_number,
  scheduled_start,
  scheduled_end,
  start_date,
  status,
  consultation_mode,
  video_enabled
FROM appointments
ORDER BY scheduled_start
LIMIT 20;

-- Summary of updated appointments
SELECT
  status,
  COUNT(*) as count,
  MIN(scheduled_start) as earliest_appointment,
  MAX(scheduled_start) as latest_appointment
FROM appointments
WHERE DATE(scheduled_start) = '2025-12-16'::date
GROUP BY status
ORDER BY status;
