-- Migration: Add receiver_id and receiver_name to chime_messages
-- Purpose: Track message recipients to match appointment participants
-- Date: 2026-01-06

-- Add receiver columns
ALTER TABLE chime_messages
ADD COLUMN IF NOT EXISTS receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS receiver_name TEXT,
ADD COLUMN IF NOT EXISTS receiver_avatar TEXT;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_chime_messages_receiver_id ON chime_messages(receiver_id);

-- Update existing messages to populate receiver_id from appointment participants
-- For each message, set receiver_id to the OTHER participant (not the sender)
UPDATE chime_messages cm
SET
  receiver_id = CASE
    -- If sender is provider, receiver is patient
    WHEN cm.sender_id = (
      SELECT mpp.user_id
      FROM appointments a
      JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
      WHERE a.id = cm.appointment_id
    ) THEN (
      SELECT patient_id
      FROM appointments
      WHERE id = cm.appointment_id
    )
    -- If sender is patient, receiver is provider
    ELSE (
      SELECT mpp.user_id
      FROM appointments a
      JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
      WHERE a.id = cm.appointment_id
    )
  END,
  receiver_name = CASE
    -- If sender is provider, receiver name is patient name
    WHEN cm.sender_id = (
      SELECT mpp.user_id
      FROM appointments a
      JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
      WHERE a.id = cm.appointment_id
    ) THEN (
      SELECT u.first_name || ' ' || u.last_name
      FROM appointments a
      JOIN users u ON u.id = a.patient_id
      WHERE a.id = cm.appointment_id
    )
    -- If sender is patient, receiver name is provider name
    ELSE (
      SELECT u.first_name || ' ' || u.last_name
      FROM appointments a
      JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
      JOIN users u ON u.id = mpp.user_id
      WHERE a.id = cm.appointment_id
    )
  END,
  receiver_avatar = CASE
    -- If sender is provider, receiver avatar is patient photo
    WHEN cm.sender_id = (
      SELECT mpp.user_id
      FROM appointments a
      JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
      WHERE a.id = cm.appointment_id
    ) THEN (
      SELECT u.profile_picture_url
      FROM appointments a
      JOIN users u ON u.id = a.patient_id
      WHERE a.id = cm.appointment_id
    )
    -- If sender is patient, receiver avatar is provider photo
    ELSE (
      SELECT u.profile_picture_url
      FROM appointments a
      JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
      JOIN users u ON u.id = mpp.user_id
      WHERE a.id = cm.appointment_id
    )
  END
WHERE receiver_id IS NULL;

-- Add comment
COMMENT ON COLUMN chime_messages.receiver_id IS 'User ID of the message recipient (the other participant in the appointment)';
COMMENT ON COLUMN chime_messages.receiver_name IS 'Full name of the message recipient';
COMMENT ON COLUMN chime_messages.receiver_avatar IS 'Avatar URL of the message recipient';
