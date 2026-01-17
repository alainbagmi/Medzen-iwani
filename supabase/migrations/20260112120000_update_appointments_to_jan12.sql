-- Update all appointments to today (January 12, 2026)
-- This updates scheduled_start, scheduled_end, and start_date while preserving time components

UPDATE appointments
SET
    -- Update scheduled_start: keep the time, change the date to 2026-01-12
    scheduled_start = '2026-01-12'::date + scheduled_start::time,

    -- Update scheduled_end: keep the time, change the date to 2026-01-12
    scheduled_end = '2026-01-12'::date + scheduled_end::time,

    -- Update start_date to 2026-01-12
    start_date = '2026-01-12',

    -- Update the updated_at timestamp
    updated_at = NOW()
WHERE scheduled_start IS NOT NULL;

-- Log the update
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count FROM appointments;
    RAISE NOTICE 'Updated % appointments to January 12, 2026', updated_count;
END $$;
