-- Update all appointment dates to December 20, 2025 (today)
-- This preserves the time portion of each appointment

UPDATE appointments
SET
  scheduled_start = DATE '2025-12-20' + scheduled_start::time,
  scheduled_end = DATE '2025-12-20' + scheduled_end::time,
  start_date = '2025-12-20'::date,
  updated_at = NOW()
WHERE scheduled_start IS NOT NULL;

-- Log the update
DO $$
DECLARE
  updated_count INT;
BEGIN
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RAISE NOTICE 'Updated % appointments to December 20, 2025', updated_count;
END $$;
