-- Update all appointments to today (2026-01-18), preserving time of day
UPDATE appointments
SET 
  scheduled_start = (date_trunc('day', now())::date || ' ' || to_char(scheduled_start, 'HH24:MI:SS'))::timestamp with time zone + interval '0 hours',
  scheduled_end = (date_trunc('day', now())::date || ' ' || to_char(scheduled_end, 'HH24:MI:SS'))::timestamp with time zone + interval '0 hours',
  start_date = date_trunc('day', now())::date,
  updated_at = now()
WHERE scheduled_start::date != date_trunc('day', now())::date;
