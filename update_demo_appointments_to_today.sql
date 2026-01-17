-- Update demo appointments to today's date (2026-01-08)
-- This updates appointments with "Demo" in patient or provider names
-- Preserves time components while updating date portions

-- First, let's see what we're updating (check appointment_overview view)
SELECT
    ao.id,
    ao.appointment_number,
    ao.patient_fullname,
    ao.provider_fullname,
    ao.scheduled_start,
    ao.scheduled_end,
    ao.appointment_start_date,
    ao.status
FROM appointment_overview ao
WHERE
    LOWER(ao.patient_fullname) LIKE '%demo%'
    OR LOWER(ao.provider_fullname) LIKE '%demo%'
ORDER BY ao.scheduled_start DESC
LIMIT 20;

-- Count how many we're updating
SELECT COUNT(*) as demo_appointments_count
FROM appointment_overview ao
WHERE
    LOWER(ao.patient_fullname) LIKE '%demo%'
    OR LOWER(ao.provider_fullname) LIKE '%demo%';

-- Update the appointments table (appointment_overview is just a view)
-- Update scheduled_start, scheduled_end, and start_date to today while preserving time
UPDATE appointments
SET
    scheduled_start = DATE '2026-01-08' + (scheduled_start::time),
    scheduled_end = DATE '2026-01-08' + (scheduled_end::time),
    start_date = DATE '2026-01-08',
    updated_at = NOW()
WHERE id IN (
    SELECT ao.id
    FROM appointment_overview ao
    WHERE
        LOWER(ao.patient_fullname) LIKE '%demo%'
        OR LOWER(ao.provider_fullname) LIKE '%demo%'
);

-- Verify the updates
SELECT
    ao.id,
    ao.appointment_number,
    ao.patient_fullname,
    ao.provider_fullname,
    ao.scheduled_start,
    ao.scheduled_end,
    ao.appointment_start_date,
    ao.status
FROM appointment_overview ao
WHERE
    LOWER(ao.patient_fullname) LIKE '%demo%'
    OR LOWER(ao.provider_fullname) LIKE '%demo%'
ORDER BY ao.scheduled_start;

-- Success message
SELECT 'Demo appointments updated to 2026-01-08!' as result;
