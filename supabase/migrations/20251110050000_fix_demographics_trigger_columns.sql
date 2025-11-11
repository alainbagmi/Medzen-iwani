-- Fix demographics sync trigger to use only existing columns in users table
-- The original trigger referenced columns that don't exist

CREATE OR REPLACE FUNCTION queue_user_demographics_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  ehr_record RECORD;
  snapshot_data JSONB;
BEGIN
  -- Get the associated EHR record for this user
  SELECT * INTO ehr_record
  FROM electronic_health_records
  WHERE patient_id = NEW.id;

  -- Only queue if EHR exists
  IF ehr_record.ehr_id IS NOT NULL THEN

    -- Build demographics snapshot with ONLY existing columns
    snapshot_data := jsonb_build_object(
      -- Core identity
      'user_id', NEW.id,
      'firebase_uid', NEW.firebase_uid,
      'email', NEW.email,
      'ehr_id', ehr_record.ehr_id,

      -- Personal information (existing columns only)
      'first_name', NEW.first_name,
      'middle_name', NEW.middle_name,
      'last_name', NEW.last_name,
      'full_name', NEW.full_name,
      'date_of_birth', NEW.date_of_birth,
      'gender', NEW.gender,

      -- Contact information (existing columns only)
      'phone_number', NEW.phone_number,
      'secondary_phone', NEW.secondary_phone,
      'country', NEW.country,

      -- Demographics (existing columns only)
      'preferred_language', NEW.preferred_language,
      'timezone', NEW.timezone,

      -- Profile
      'profile_picture_url', NEW.profile_picture_url,
      'avatar_url', NEW.avatar_url,

      -- Metadata
      'created_at', NEW.created_at,
      'updated_at', NEW.updated_at,
      'is_active', NEW.is_active,
      'is_verified', NEW.is_verified
    );

    -- Insert into sync queue
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      operation,
      sync_type,
      sync_status,
      data_snapshot,
      retry_count,
      ehr_id
    )
    VALUES (
      'users',
      NEW.id,
      TG_OP,
      'demographics',
      'pending',
      snapshot_data,
      0,
      ehr_record.ehr_id
    )
    ON CONFLICT (table_name, record_id, ehr_id)
    WHERE sync_status IN ('pending', 'processing')
    DO UPDATE SET
      operation = EXCLUDED.operation,
      sync_status = 'pending',
      data_snapshot = EXCLUDED.data_snapshot,
      updated_at = NOW(),
      retry_count = 0;

    RAISE NOTICE 'Queued demographics sync for user: %, EHR: %', NEW.id, ehr_record.ehr_id;
  ELSE
    RAISE NOTICE 'No EHR found for user: %, skipping demographics sync', NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
