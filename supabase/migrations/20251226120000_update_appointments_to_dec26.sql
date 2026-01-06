-- Update all appointments to today (December 26, 2025)
-- This updates scheduled_start, scheduled_end, and start_date while preserving time components

UPDATE appointments
SET
    -- Update scheduled_start: keep the time, change the date to 2025-12-26
    scheduled_start = '2025-12-26'::date + scheduled_start::time,

    -- Update scheduled_end: keep the time, change the date to 2025-12-26
    scheduled_end = '2025-12-26'::date + scheduled_end::time,

    -- Update start_date to 2025-12-26
    start_date = '2025-12-26',

    -- Update the updated_at timestamp
    updated_at = NOW()
WHERE scheduled_start IS NOT NULL;

-- Log the update
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count FROM appointments;
    RAISE NOTICE 'Updated % appointments to December 26, 2025', updated_count;
END $$;
