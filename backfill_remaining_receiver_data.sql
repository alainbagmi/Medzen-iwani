-- Backfill remaining chime_messages with receiver data
-- This completes the backfill for messages that were missed

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
WHERE receiver_id IS NULL AND appointment_id IS NOT NULL;

-- Show results
SELECT
  COUNT(*) FILTER (WHERE receiver_id IS NOT NULL) as with_receiver,
  COUNT(*) FILTER (WHERE receiver_id IS NULL) as without_receiver,
  COUNT(*) as total
FROM chime_messages;
