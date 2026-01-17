-- Add device tracking columns to users table
-- These columns are required for FCM token registration and device management

-- Add device_type column to track device OS (Android, iOS, web)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS device_type VARCHAR(50);

-- Add active_device_id column to track the currently active device
ALTER TABLE users
ADD COLUMN IF NOT EXISTS active_device_id VARCHAR(255);

-- Add comment explaining the columns
COMMENT ON COLUMN users.device_type IS 'Device OS type: Android, iOS, or web';
COMMENT ON COLUMN users.active_device_id IS 'Unique identifier of the users active device for FCM token management';
