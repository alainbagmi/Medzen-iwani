-- Update all appointments to today's date (2025-12-24)
-- Preserves the time portion of scheduled_start and scheduled_end

-- Update start_date to today
UPDATE appointments
SET start_date = '2025-12-24'::date
WHERE start_date IS NOT NULL AND start_date != '2025-12-24';

-- Update scheduled_start to today, keeping original time
UPDATE appointments
SET scheduled_start = '2025-12-24'::date + scheduled_start::time
WHERE scheduled_start IS NOT NULL;

-- Update scheduled_end to today, keeping original time
UPDATE appointments
SET scheduled_end = '2025-12-24'::date + scheduled_end::time
WHERE scheduled_end IS NOT NULL;

-- Update actual_start to today if it exists, keeping original time
UPDATE appointments
SET actual_start = '2025-12-24'::date + actual_start::time
WHERE actual_start IS NOT NULL;

-- Update actual_end to today if it exists, keeping original time
UPDATE appointments
SET actual_end = '2025-12-24'::date + actual_end::time
WHERE actual_end IS NOT NULL;
