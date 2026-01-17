-- Update all scheduled appointments to today (2026-01-17)
UPDATE appointments
SET
  scheduled_start = (DATE_TRUNC('day', NOW())::date || ' ' ||
                    LPAD(EXTRACT(HOUR FROM scheduled_start)::text, 2, '0') || ':' ||
                    LPAD(EXTRACT(MINUTE FROM scheduled_start)::text, 2, '0') || ':00+00:00')::TIMESTAMPTZ,
  scheduled_end = (DATE_TRUNC('day', NOW())::date || ' ' ||
                  LPAD(EXTRACT(HOUR FROM scheduled_end)::text, 2, '0') || ':' ||
                  LPAD(EXTRACT(MINUTE FROM scheduled_end)::text, 2, '0') || ':00+00:00')::TIMESTAMPTZ,
  start_date = CURRENT_DATE,
  updated_at = NOW()
WHERE status = 'scheduled'
  OR status IS NULL;

-- Log the update count
DO $$
BEGIN
  RAISE NOTICE 'Updated appointments to date: %', CURRENT_DATE;
END $$;
