-- Backfill file columns in chime_messages table from metadata JSON
-- Date: 2026-01-06
--
-- Purpose: Populate root-level file columns (file_url, file_name, file_type, file_size)
--          from metadata JSON for existing messages that have file attachments
--
-- Background:
-- - ChimeMeetingEnhanced widget was previously saving file data only to metadata JSON
-- - Now widget saves to both metadata AND root-level columns for better querying
-- - This migration backfills existing messages for consistency

-- ============================================================================
-- 1. Backfill file columns from metadata
-- ============================================================================

UPDATE chime_messages
SET
  file_url = (metadata::jsonb->>'fileUrl'),
  file_name = (metadata::jsonb->>'fileName'),
  file_type = (metadata::jsonb->>'fileType'),
  file_size = CASE
    WHEN metadata::jsonb->>'fileSize' ~ '^\d+$'
    THEN (metadata::jsonb->>'fileSize')::integer
    ELSE NULL
  END
WHERE
  -- Only update messages that have file data in metadata
  metadata::jsonb->>'fileUrl' IS NOT NULL
  AND metadata::jsonb->>'fileUrl' != ''
  -- And don't have file_url already populated
  AND (file_url IS NULL OR file_url = '');

-- ============================================================================
-- 2. Verification
-- ============================================================================

DO $$
DECLARE
  backfilled_count integer;
  total_file_messages integer;
  rec RECORD;
BEGIN
  -- Count messages with file data in metadata
  SELECT COUNT(*) INTO total_file_messages
  FROM chime_messages
  WHERE metadata::jsonb->>'fileUrl' IS NOT NULL
    AND metadata::jsonb->>'fileUrl' != '';

  -- Count messages now with file_url populated
  SELECT COUNT(*) INTO backfilled_count
  FROM chime_messages
  WHERE file_url IS NOT NULL AND file_url != '';

  RAISE NOTICE '✅ Backfill complete!';
  RAISE NOTICE '  - Total messages with file attachments: %', total_file_messages;
  RAISE NOTICE '  - Messages with file_url populated: %', backfilled_count;
  RAISE NOTICE '';
  RAISE NOTICE '📎 File types in messages:';

  -- Show breakdown by message type
  FOR rec IN (
    SELECT
      message_type,
      COUNT(*) as count,
      SUM(file_size) as total_size
    FROM chime_messages
    WHERE file_url IS NOT NULL AND file_url != ''
    GROUP BY message_type
    ORDER BY count DESC
  ) LOOP
    RAISE NOTICE '  - %: % messages (% bytes total)',
      rec.message_type, rec.count, COALESCE(rec.total_size, 0);
  END LOOP;
END $$;

-- ============================================================================
-- 3. Verify sample messages
-- ============================================================================

-- Show sample file messages (for manual verification)
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '📋 Sample file messages (first 3):';
END $$;

SELECT
  id,
  message_type,
  file_name,
  file_type,
  file_size,
  LEFT(file_url, 60) || '...' as file_url_preview,
  created_at
FROM chime_messages
WHERE file_url IS NOT NULL AND file_url != ''
ORDER BY created_at DESC
LIMIT 3;
