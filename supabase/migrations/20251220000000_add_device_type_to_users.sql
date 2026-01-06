-- Migration: Add device_type column to users table for FCM token tracking
-- Date: 2025-12-20
-- Description: Adds device_type column to track the platform (iOS, Android, Web) for push notifications

-- Add device_type column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'device_type'
    ) THEN
        ALTER TABLE users ADD COLUMN device_type TEXT;

        -- Add a check constraint to ensure valid device types
        ALTER TABLE users ADD CONSTRAINT users_device_type_check
            CHECK (device_type IS NULL OR device_type IN ('ios', 'android', 'web', 'iOS', 'Android', 'Web'));

        -- Add an index for efficient querying by device type (useful for targeted notifications)
        CREATE INDEX IF NOT EXISTS idx_users_device_type ON users(device_type) WHERE device_type IS NOT NULL;

        -- Add comment for documentation
        COMMENT ON COLUMN users.device_type IS 'Device platform type for FCM push notifications: ios, android, or web';
    END IF;
END $$;

-- Create a view for push notification targets (users with valid FCM tokens)
CREATE OR REPLACE VIEW push_notification_targets AS
SELECT
    id,
    firebase_uid,
    email,
    first_name,
    last_name,
    fcm_token,
    device_type,
    updated_at
FROM users
WHERE fcm_token IS NOT NULL
  AND fcm_token != ''
  AND LENGTH(fcm_token) >= 100
  AND is_active = true;

COMMENT ON VIEW push_notification_targets IS 'View of users with valid FCM tokens for push notifications';

-- Grant permissions
GRANT SELECT ON push_notification_targets TO authenticated;
GRANT SELECT ON push_notification_targets TO service_role;
