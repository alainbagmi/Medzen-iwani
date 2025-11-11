-- Ensure each user can only have one profile picture
-- When a new picture is uploaded, automatically delete the old one

-- Create function to delete old profile pictures
CREATE OR REPLACE FUNCTION storage.delete_old_profile_pictures()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process if this is a profile_pictures upload
    IF NEW.bucket_id = 'profile_pictures' AND NEW.owner IS NOT NULL THEN
        -- Delete all previous profile pictures owned by this user
        -- Keep only the newest one (which is the current NEW record)
        DELETE FROM storage.objects
        WHERE bucket_id = 'profile_pictures'
          AND owner = NEW.owner
          AND id != NEW.id
          AND (storage.foldername(name))[1] = 'pics';

        -- Log the cleanup (optional, for debugging)
        RAISE NOTICE 'Cleaned up old profile pictures for user: %', NEW.owner;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires after a new profile picture is inserted
DROP TRIGGER IF EXISTS enforce_one_profile_picture_per_user ON storage.objects;

CREATE TRIGGER enforce_one_profile_picture_per_user
    AFTER INSERT ON storage.objects
    FOR EACH ROW
    EXECUTE FUNCTION storage.delete_old_profile_pictures();

-- Add comment explaining the trigger
COMMENT ON FUNCTION storage.delete_old_profile_pictures() IS
'Automatically deletes old profile pictures when a user uploads a new one. Ensures each user has only one profile picture.';

COMMENT ON TRIGGER enforce_one_profile_picture_per_user ON storage.objects IS
'Enforces one profile picture per user by deleting old uploads when a new one is added';
