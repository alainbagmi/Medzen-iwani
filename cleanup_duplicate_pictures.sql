-- Cleanup Existing Duplicate Profile Pictures
-- Run this in Supabase Dashboard → SQL Editor AFTER applying fix_auto_delete_trigger.sql
-- This will remove all old profile pictures, keeping only the newest one per user

-- Preview duplicates before deleting (SAFE - just shows what will be deleted)
WITH user_files AS (
    SELECT
        id,
        name,
        created_at,
        updated_at,
        -- Extract user folder from path: pics/{user_id}/file.jpg
        (storage.foldername(name))[2] as user_folder,
        ROW_NUMBER() OVER (
            PARTITION BY (storage.foldername(name))[2]
            ORDER BY created_at DESC
        ) as row_num
    FROM storage.objects
    WHERE bucket_id = 'profile_pictures'
      AND (storage.foldername(name))[1] = 'pics'
      AND array_length(storage.foldername(name), 1) >= 2
)
SELECT
    user_folder,
    COUNT(*) as total_files,
    COUNT(*) FILTER (WHERE row_num = 1) as files_to_keep,
    COUNT(*) FILTER (WHERE row_num > 1) as files_to_delete
FROM user_files
GROUP BY user_folder
HAVING COUNT(*) > 1
ORDER BY total_files DESC;

-- ⚠️ DESTRUCTIVE: Actually delete duplicates (uncomment to run)
-- WITH user_files AS (
--     SELECT
--         id,
--         name,
--         created_at,
--         (storage.foldername(name))[2] as user_folder,
--         ROW_NUMBER() OVER (
--             PARTITION BY (storage.foldername(name))[2]
--             ORDER BY created_at DESC
--         ) as row_num
--     FROM storage.objects
--     WHERE bucket_id = 'profile_pictures'
--       AND (storage.foldername(name))[1] = 'pics'
--       AND array_length(storage.foldername(name), 1) >= 2
-- ),
-- deleted AS (
--     DELETE FROM storage.objects
--     WHERE id IN (
--         SELECT id
--         FROM user_files
--         WHERE row_num > 1  -- Keep only the newest (row_num = 1)
--     )
--     RETURNING id, name
-- )
-- SELECT
--     COUNT(*) as deleted_count,
--     array_agg(name) as deleted_files
-- FROM deleted;

-- After cleanup, verify each user has only 1 picture
SELECT
    (storage.foldername(name))[2] as user_folder,
    COUNT(*) as picture_count,
    array_agg(name ORDER BY created_at DESC) as files
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
  AND array_length(storage.foldername(name), 1) >= 2
GROUP BY (storage.foldername(name))[2]
ORDER BY picture_count DESC, user_folder;
