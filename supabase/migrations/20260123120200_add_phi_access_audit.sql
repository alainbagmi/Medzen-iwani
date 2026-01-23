-- HIPAA 164.312(b) Audit Controls
-- PHI access audit log for compliance tracking
CREATE TABLE IF NOT EXISTS phi_access_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  patient_id UUID REFERENCES users(id) ON DELETE CASCADE,
  access_type VARCHAR(50) NOT NULL, -- 'read', 'write', 'export', 'delete'
  table_name VARCHAR(100) NOT NULL,
  record_id UUID,
  field_names TEXT[],
  reason VARCHAR(200),
  ip_address INET,
  user_agent TEXT,
  session_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_phi_audit_user_id ON phi_access_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_phi_audit_patient_id ON phi_access_audit_log(patient_id);
CREATE INDEX IF NOT EXISTS idx_phi_audit_created_at ON phi_access_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_phi_audit_table_name ON phi_access_audit_log(table_name);

-- RLS: Only system admins can read audit logs
ALTER TABLE phi_access_audit_log ENABLE ROW LEVEL SECURITY;

-- Service role can insert (audit logging)
CREATE POLICY "Service role can insert audit logs" ON phi_access_audit_log
FOR INSERT TO service_role WITH CHECK (true);

-- Service role can read all (for administrative purposes)
CREATE POLICY "Service role can read audit logs" ON phi_access_audit_log
FOR SELECT TO service_role USING (true);

-- Admins can read audit logs for their organization
CREATE POLICY "Admins can read audit logs" ON phi_access_audit_log
FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    JOIN users u ON sap.user_id = u.id
    WHERE u.firebase_uid = auth.uid()::text
  )
);

-- Prevent direct updates/deletes (audit trail immutability)
CREATE POLICY "Audit logs immutable" ON phi_access_audit_log
FOR UPDATE USING (false);

CREATE POLICY "Audit logs no delete" ON phi_access_audit_log
FOR DELETE USING (false);

-- Trigger function to log PHI access to clinical_notes
CREATE OR REPLACE FUNCTION log_phi_access_clinical_notes()
RETURNS TRIGGER AS $$
DECLARE
  v_patient_id UUID;
BEGIN
  -- Get patient_id from clinical_notes
  SELECT patient_id INTO v_patient_id FROM clinical_notes WHERE id = NEW.id;

  INSERT INTO phi_access_audit_log (
    user_id,
    patient_id,
    access_type,
    table_name,
    record_id,
    ip_address,
    user_agent,
    created_at
  ) VALUES (
    (SELECT id FROM users WHERE firebase_uid = auth.uid()::text),
    v_patient_id,
    CASE TG_OP
      WHEN 'INSERT' THEN 'write'
      WHEN 'UPDATE' THEN 'write'
      WHEN 'DELETE' THEN 'delete'
      ELSE 'read'
    END,
    'clinical_notes',
    NEW.id,
    inet_client_addr(),
    current_setting('request.headers', true)::json->>'user-agent',
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function to log PHI access to patient_profiles
CREATE OR REPLACE FUNCTION log_phi_access_patient_profiles()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO phi_access_audit_log (
    user_id,
    patient_id,
    access_type,
    table_name,
    record_id,
    ip_address,
    user_agent,
    created_at
  ) VALUES (
    (SELECT id FROM users WHERE firebase_uid = auth.uid()::text),
    NEW.user_id,
    CASE TG_OP
      WHEN 'INSERT' THEN 'write'
      WHEN 'UPDATE' THEN 'write'
      WHEN 'DELETE' THEN 'delete'
      ELSE 'read'
    END,
    'patient_profiles',
    NEW.id,
    inet_client_addr(),
    current_setting('request.headers', true)::json->>'user-agent',
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function to log PHI access to appointments
CREATE OR REPLACE FUNCTION log_phi_access_appointments()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO phi_access_audit_log (
    user_id,
    patient_id,
    access_type,
    table_name,
    record_id,
    ip_address,
    user_agent,
    created_at
  ) VALUES (
    (SELECT id FROM users WHERE firebase_uid = auth.uid()::text),
    NEW.patient_id,
    CASE TG_OP
      WHEN 'INSERT' THEN 'write'
      WHEN 'UPDATE' THEN 'write'
      WHEN 'DELETE' THEN 'delete'
      ELSE 'read'
    END,
    'appointments',
    NEW.id,
    inet_client_addr(),
    current_setting('request.headers', true)::json->>'user-agent',
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function to log PHI access to video_call_sessions
CREATE OR REPLACE FUNCTION log_phi_access_video_calls()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO phi_access_audit_log (
    user_id,
    patient_id,
    access_type,
    table_name,
    record_id,
    ip_address,
    user_agent,
    created_at
  ) VALUES (
    (SELECT id FROM users WHERE firebase_uid = auth.uid()::text),
    NEW.patient_id,
    CASE TG_OP
      WHEN 'INSERT' THEN 'write'
      WHEN 'UPDATE' THEN 'write'
      WHEN 'DELETE' THEN 'delete'
      ELSE 'read'
    END,
    'video_call_sessions',
    NEW.id,
    inet_client_addr(),
    current_setting('request.headers', true)::json->>'user-agent',
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers only if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'audit_clinical_notes'
  ) THEN
    CREATE TRIGGER audit_clinical_notes
    AFTER INSERT OR UPDATE OR DELETE ON clinical_notes
    FOR EACH ROW EXECUTE FUNCTION log_phi_access_clinical_notes();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'audit_patient_profiles'
  ) THEN
    CREATE TRIGGER audit_patient_profiles
    AFTER INSERT OR UPDATE OR DELETE ON patient_profiles
    FOR EACH ROW EXECUTE FUNCTION log_phi_access_patient_profiles();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'audit_appointments'
  ) THEN
    CREATE TRIGGER audit_appointments
    AFTER INSERT OR UPDATE OR DELETE ON appointments
    FOR EACH ROW EXECUTE FUNCTION log_phi_access_appointments();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'audit_video_calls'
  ) THEN
    CREATE TRIGGER audit_video_calls
    AFTER INSERT OR UPDATE OR DELETE ON video_call_sessions
    FOR EACH ROW EXECUTE FUNCTION log_phi_access_video_calls();
  END IF;
END
$$;

-- Monthly audit log summary (for compliance reviews)
CREATE OR REPLACE VIEW monthly_phi_access_summary AS
SELECT
  DATE_TRUNC('month', pal.created_at) AS month,
  user_id,
  u.email AS user_email,
  COUNT(*) AS total_accesses,
  COUNT(DISTINCT patient_id) AS unique_patients_accessed,
  array_agg(DISTINCT table_name) AS tables_accessed
FROM phi_access_audit_log pal
LEFT JOIN users u ON pal.user_id = u.id
WHERE pal.created_at > NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', pal.created_at), user_id, u.email
ORDER BY month DESC, total_accesses DESC;

-- Cleanup old rate limit data (>30 days) - runs hourly
SELECT cron.schedule(
  'cleanup-rate-limit-tracking',
  '0 * * * *',
  $$DELETE FROM rate_limit_tracking WHERE created_at < NOW() - INTERVAL '30 days'$$
);

-- Archive old audit logs (>6 years) - runs daily
-- Note: In production, these would be exported to S3 Glacier for long-term storage
SELECT cron.schedule(
  'archive-old-audit-logs',
  '0 2 * * *',
  $$DELETE FROM phi_access_audit_log WHERE created_at < NOW() - INTERVAL '6 years'$$
);
