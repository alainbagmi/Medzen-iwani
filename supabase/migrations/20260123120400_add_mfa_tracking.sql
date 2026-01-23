-- HIPAA 164.312(a)(2)(i): MFA Requirement Tracking
-- Track MFA enrollment and enforcement for providers and admins
CREATE TABLE IF NOT EXISTS mfa_enrollment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  mfa_method VARCHAR(50) NOT NULL, -- 'authenticator_app', 'sms', 'email'
  secret_key_encrypted TEXT, -- Store encrypted secret
  phone_number VARCHAR(20),
  email_verified BOOLEAN DEFAULT false,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  backup_codes_generated_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backup codes for account recovery
CREATE TABLE IF NOT EXISTS mfa_backup_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash VARCHAR(64) NOT NULL,
  used BOOLEAN DEFAULT false,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MFA enforcement policy by role
CREATE TABLE IF NOT EXISTS mfa_enforcement_policy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role VARCHAR(50) NOT NULL UNIQUE, -- 'medical_provider', 'facility_admin', 'system_admin'
  required BOOLEAN DEFAULT true,
  grace_period_days INT DEFAULT 7, -- Days to enforce MFA after update
  methods_allowed TEXT[] DEFAULT ARRAY['authenticator_app', 'sms'], -- Allowed MFA methods
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Track MFA failures/challenges
CREATE TABLE IF NOT EXISTS mfa_challenge_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  challenge_type VARCHAR(50) NOT NULL, -- 'totp', 'sms', 'email'
  challenge_sent_at TIMESTAMPTZ DEFAULT NOW(),
  challenge_verified_at TIMESTAMPTZ,
  ip_address INET,
  user_agent TEXT,
  success BOOLEAN,
  failure_reason VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_mfa_enrollment_user_id
  ON mfa_enrollment(user_id)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_mfa_backup_codes_user_id
  ON mfa_backup_codes(user_id);

CREATE INDEX IF NOT EXISTS idx_mfa_challenge_log_user_id
  ON mfa_challenge_log(user_id, challenge_sent_at DESC);

-- RLS policies
ALTER TABLE mfa_enrollment ENABLE ROW LEVEL SECURITY;
ALTER TABLE mfa_backup_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mfa_challenge_log ENABLE ROW LEVEL SECURITY;

-- Users can manage their own MFA
CREATE POLICY "Users manage own MFA" ON mfa_enrollment
FOR ALL TO authenticated USING (
  user_id = (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- Admins can view all MFA enrollment
CREATE POLICY "Admins view MFA enrollment" ON mfa_enrollment
FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    JOIN users u ON sap.user_id = u.id
    WHERE u.firebase_uid = auth.uid()::text
  )
);

-- Initialize MFA enforcement policies
INSERT INTO mfa_enforcement_policy (role, required, grace_period_days, methods_allowed)
VALUES
  ('medical_provider', true, 7, ARRAY['authenticator_app', 'sms']),
  ('facility_admin', true, 7, ARRAY['authenticator_app', 'sms']),
  ('system_admin', true, 0, ARRAY['authenticator_app']),
  ('patient', false, NULL, ARRAY['sms', 'email'])
ON CONFLICT (role) DO NOTHING;

-- View for MFA compliance status
CREATE OR REPLACE VIEW mfa_compliance_status AS
SELECT
  u.id,
  u.email,
  COALESCE(up.role, 'unknown') AS user_role,
  CASE
    WHEN mep.required IS NULL THEN 'no_policy'
    WHEN me.is_active = true THEN 'compliant'
    WHEN (NOW() - u.created_at) > (mep.grace_period_days || ' days')::INTERVAL THEN 'non_compliant'
    ELSE 'grace_period'
  END AS mfa_status,
  me.enrolled_at,
  me.last_used_at,
  mep.grace_period_days,
  CASE
    WHEN mep.grace_period_days IS NOT NULL
    THEN u.created_at + (mep.grace_period_days || ' days')::INTERVAL
    ELSE NULL
  END AS mfa_required_by
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN mfa_enrollment me ON u.id = me.user_id AND me.is_active = true
LEFT JOIN mfa_enforcement_policy mep ON COALESCE(up.role, 'patient') = mep.role
ORDER BY u.email;
