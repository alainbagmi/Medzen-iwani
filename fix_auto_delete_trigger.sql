-- Fix Auto-Delete Trigger for Profile Pictures
-- Run this in Supabase Dashboard → SQL Editor
-- This bypasses API permission restrictions

-- Step 1: Update the trigger function to use path-based user identification
CREATE OR REPLACE FUNCTION storage.delete_old_profile_pictures()
RETURNS TRIGGER AS $$
DECLARE
    v_user_folder TEXT;
    v_path_parts TEXT[];
    v_deleted_count INTEGER;
BEGIN
    -- Only process profile_pictures uploads
    IF NEW.bucket_id = 'profile_pictures' THEN
        -- Extract path parts from NEW.name
        -- Example path: "pics/abc123/avatar.jpg" → ['pics', 'abc123', 'avatar.jpg']
        v_path_parts := storage.foldername(NEW.name);

        -- Ensure path follows expected structure: pics/{user_id}/...
        IF array_length(v_path_parts, 1) >= 2 AND v_path_parts[1] = 'pics' THEN
            -- Get the user folder (second part of path)
            v_user_folder := v_path_parts[2];

            -- Delete all previous profile pictures in this user's folder
            -- Keep only the newest one (current NEW record)
            WITH deleted AS (
                DELETE FROM storage.objects
                WHERE bucket_id = 'profile_pictures'
                  AND id != NEW.id  -- Don't delete the file we just uploaded
                  AND name LIKE 'pics/' || v_user_folder || '/%'
                RETURNING id
            )
            SELECT count(*) INTO v_deleted_count FROM deleted;

            -- Log the cleanup (helps with debugging)
            IF v_deleted_count > 0 THEN
                RAISE NOTICE 'Auto-deleted % old profile picture(s) for user folder: %',
                    v_deleted_count, v_user_folder;
            END IF;
        ELSE
            -- Log unexpected path structure
            RAISE WARNING 'Profile picture path does not match expected structure: %', NEW.name;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Ensure trigger exists and is enabled
DROP TRIGGER IF EXISTS enforce_one_profile_picture_per_user ON storage.objects;

CREATE TRIGGER enforce_one_profile_picture_per_user
    AFTER INSERT ON storage.objects
    FOR EACH ROW
    EXECUTE FUNCTION storage.delete_old_profile_pictures();

-- Step 3: Verify trigger is active
SELECT
    tgname as trigger_name,
    tgenabled as enabled,
    CASE tgenabled
        WHEN 'O' THEN 'ENABLED ✅'
        WHEN 'D' THEN 'DISABLED ❌'
    END as status
FROM pg_trigger
WHERE tgname = 'enforce_one_profile_picture_per_user';
