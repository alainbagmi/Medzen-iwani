-- Update all appointments to today's date (2025-12-15)
-- Preserves time components while updating date portions

-- First, let's see what we're updating
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

-- Update scheduled_start to today while preserving time
UPDATE appointments
SET
    scheduled_start = DATE '2025-12-15' + (scheduled_start::time),
    scheduled_end = DATE '2025-12-15' + (scheduled_end::time),
    start_date = DATE '2025-12-15',
    updated_at = NOW()
WHERE DATE(scheduled_start) != DATE '2025-12-15';

-- Verify the updates
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
