-- Update all appointments to December 18, 2025 (today)
-- Preserves the time portion of all timestamp fields

-- First, show current appointments
SELECT
  id,
  appointment_number,
  scheduled_start,
  scheduled_end,
  start_date,
  actual_start,
  actual_end,
  status,
  consultation_mode
FROM appointments
ORDER BY scheduled_start DESC
LIMIT 10;

-- Update all appointment dates to today (2025-12-18)
-- Preserves time components for timestamp fields
UPDATE appointments
SET
  -- Main scheduling dates with time preservation
  scheduled_start = '2025-12-18'::date + (scheduled_start::time),
  scheduled_end = '2025-12-18'::date + (scheduled_end::time),
  start_date = '2025-12-18'::date,

  -- Actual appointment times (if they exist)
  actual_start = CASE
    WHEN actual_start IS NOT NULL
    THEN '2025-12-18'::date + (actual_start::time)
    ELSE NULL
  END,
  actual_end = CASE
    WHEN actual_end IS NOT NULL
    THEN '2025-12-18'::date + (actual_end::time)
    ELSE NULL
  END,

  -- Video call join times (if they exist)
  provider_joined_at = CASE
    WHEN provider_joined_at IS NOT NULL
    THEN '2025-12-18'::date + (provider_joined_at::time)
    ELSE NULL
  END,
  patient_joined_at = CASE
    WHEN patient_joined_at IS NOT NULL
    THEN '2025-12-18'::date + (patient_joined_at::time)
    ELSE NULL
  END,

  -- Session creation time (if exists)
  session_created_at = CASE
    WHEN session_created_at IS NOT NULL
    THEN '2025-12-18'::date + (session_created_at::time)
    ELSE NULL
  END,

  -- Update the updated_at timestamp
  updated_at = NOW()

WHERE DATE(scheduled_start) != '2025-12-18'::date;

-- Verify the updates
SELECT
  id,
  appointment_number,
  scheduled_start,
  scheduled_end,
  start_date,
  actual_start,
  actual_end,
  status,
  consultation_mode,
  video_enabled,
  provider_joined_at,
  patient_joined_at
FROM appointments
ORDER BY scheduled_start
LIMIT 20;

-- Summary of appointments by status
SELECT
  status,
  COUNT(*) as count,
  MIN(scheduled_start) as earliest_appointment,
  MAX(scheduled_start) as latest_appointment,
  COUNT(CASE WHEN video_enabled = true THEN 1 END) as video_enabled_count
FROM appointments
WHERE DATE(scheduled_start) = '2025-12-18'::date
GROUP BY status
ORDER BY status;

-- Summary by consultation mode
SELECT
  consultation_mode,
  COUNT(*) as count,
  MIN(scheduled_start::time) as earliest_time,
  MAX(scheduled_start::time) as latest_time
FROM appointments
WHERE DATE(scheduled_start) = '2025-12-18'::date
GROUP BY consultation_mode
ORDER BY consultation_mode;
