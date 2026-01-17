-- Update all appointment dates to today (2026-01-17)
-- Preserve the time portion but change the date to today
UPDATE appointments
SET
  scheduled_start = CURRENT_DATE::TIMESTAMPTZ + (scheduled_start::TIME)::INTERVAL,
  scheduled_end = CURRENT_DATE::TIMESTAMPTZ + (scheduled_end::TIME)::INTERVAL,
  updated_at = NOW()
WHERE scheduled_start IS NOT NULL AND scheduled_end IS NOT NULL;
