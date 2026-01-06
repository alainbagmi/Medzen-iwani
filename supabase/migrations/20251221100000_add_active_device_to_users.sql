-- Migration: Add active device tracking to users for single-device enforcement
-- Created: 2025-12-21
-- Purpose: Track current active device ID and session token for force logout

-- Add columns to track active device
ALTER TABLE users ADD COLUMN IF NOT EXISTS active_device_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS active_session_token TEXT;

-- Create index for device lookups
CREATE INDEX IF NOT EXISTS idx_users_active_device ON users(active_device_id) WHERE active_device_id IS NOT NULL;

-- Function to send force logout notification via pg_notify
-- This will be picked up by a listener (Edge Function or realtime subscription)
CREATE OR REPLACE FUNCTION notify_force_logout()
RETURNS TRIGGER AS $$
DECLARE
  old_fcm_token TEXT;
  old_device_type TEXT;
BEGIN
  -- Only proceed if fcm_token or active_device_id changed
  IF OLD.active_device_id IS NOT NULL
     AND NEW.active_device_id IS NOT NULL
     AND OLD.active_device_id != NEW.active_device_id
     AND OLD.fcm_token IS NOT NULL THEN

    -- Notify via pg_notify channel (can be picked up by realtime or edge function)
    PERFORM pg_notify('force_logout', json_build_object(
      'user_id', NEW.id,
      'old_device_id', OLD.active_device_id,
      'new_device_id', NEW.active_device_id,
      'old_fcm_token', OLD.fcm_token,
      'old_device_type', OLD.device_type,
      'timestamp', NOW()
    )::text);

    RAISE NOTICE 'Force logout notification sent for user %', NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_notify_force_logout ON users;
CREATE TRIGGER trigger_notify_force_logout
  AFTER UPDATE OF active_device_id ON users
  FOR EACH ROW
  WHEN (OLD.active_device_id IS DISTINCT FROM NEW.active_device_id)
  EXECUTE FUNCTION notify_force_logout();

-- Comment for documentation
COMMENT ON COLUMN users.active_device_id IS 'Unique device identifier for single-device login enforcement';
COMMENT ON COLUMN users.active_session_token IS 'Current active session token, invalidates other sessions';
