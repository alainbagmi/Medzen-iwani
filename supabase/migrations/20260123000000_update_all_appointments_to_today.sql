-- Update all appointment dates to today (2026-01-23)
-- Preserve the original time components but set the date to today

UPDATE appointments
SET
  scheduled_start = (CURRENT_DATE::timestamp + (EXTRACT(HOUR FROM scheduled_start) * INTERVAL '1 hour') + (EXTRACT(MINUTE FROM scheduled_start) * INTERVAL '1 minute')),
  scheduled_end = (CURRENT_DATE::timestamp + INTERVAL '1 hour' + (EXTRACT(HOUR FROM scheduled_end) * INTERVAL '1 hour') + (EXTRACT(MINUTE FROM scheduled_end) * INTERVAL '1 minute')),
  start_date = CURRENT_DATE,
  updated_at = NOW()
WHERE status IN ('scheduled', 'confirmed', 'pending');

-- Also update video_call_sessions to align with appointments
UPDATE video_call_sessions
SET
  call_window_start = (CURRENT_DATE::timestamp + (EXTRACT(HOUR FROM call_window_start) * INTERVAL '1 hour') + (EXTRACT(MINUTE FROM call_window_start) * INTERVAL '1 minute')),
  call_window_end = (CURRENT_DATE::timestamp + INTERVAL '4 hours'),
  updated_at = NOW()
WHERE status IN ('created', 'meeting_ready')
  AND appointment_id IN (
    SELECT id FROM appointments WHERE status IN ('scheduled', 'confirmed', 'pending')
  );
