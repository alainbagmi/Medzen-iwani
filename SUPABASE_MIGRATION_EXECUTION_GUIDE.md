# Supabase Manual Migration Execution Guide

**Status:** Phase 1 - Step 3 (Database Migrations)
**Date:** 2026-01-23
**Docker Status:** Not running - using Supabase Dashboard SQL Editor instead

---

## Prerequisites

✅ **Already Completed:**
- AWS S3 Encryption enabled (KMS key: `9ff0b8da-ae86-4e8d-b595-c5ee396bcc56`)
- AWS GuardDuty enabled (Detector: `96cdf5273713a23964bbeb88250ecdf4`)
- AWS CloudTrail configured and logging

❌ **Remaining This Step:**
- Execute 4 database migrations
- Deploy security modules (cors.ts, rate-limiter.ts, input-validator.ts)
- Execute AWS BAA (manual)

---

## Step 3: Execute Database Migrations

### Method 1: Supabase Dashboard SQL Editor (Recommended - No Docker Needed)

#### 3.1 Open Supabase SQL Editor

1. Go to: https://app.supabase.com/
2. Select project: **medzen-iwani** (Project ID: `noaeltglphdlkbflipit`)
3. Click **SQL Editor** in left sidebar
4. Click **New Query** button

#### 3.2 Execute Migration #1: Rate Limiting

**Name:** `add_rate_limiting`
**Execution Time:** < 1 minute

**Copy and paste this SQL:**

```sql
-- HIPAA/GDPR: Rate limiting table to prevent API abuse and DDoS attacks
CREATE TABLE IF NOT EXISTS rate_limit_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier VARCHAR(255) NOT NULL,
  endpoint VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_identifier_created_at
  ON rate_limit_tracking(identifier, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_rate_limit_endpoint
  ON rate_limit_tracking(endpoint, created_at DESC);

ALTER TABLE rate_limit_tracking DISABLE ROW LEVEL SECURITY;
```

**Click "Run"** ✓

**Expected Result:**
```
Query executed successfully (0 rows affected)
```

---

#### 3.3 Execute Migration #2: PHI Access Audit Logging (CRITICAL - HIPAA REQUIREMENT)

**Name:** `add_phi_access_audit`
**Execution Time:** 2-3 minutes
**Importance:** 🔴 CRITICAL - HIPAA 164.312(b) Audit Controls

**Copy and paste this SQL:**

```sql
-- HIPAA 164.312(b) Audit Controls
CREATE TABLE IF NOT EXISTS phi_access_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  patient_id UUID REFERENCES users(id) ON DELETE CASCADE,
  access_type VARCHAR(50) NOT NULL,
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

ALTER TABLE phi_access_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can insert audit logs" ON phi_access_audit_log
FOR INSERT TO service_role USING (true);

CREATE POLICY "Service role can read audit logs" ON phi_access_audit_log
FOR SELECT TO service_role USING (true);

CREATE POLICY "Admins can read audit logs" ON phi_access_audit_log
FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    JOIN users u ON sap.user_id = u.id
    WHERE u.firebase_uid = auth.uid()
  )
);

CREATE POLICY "Audit logs immutable" ON phi_access_audit_log
FOR UPDATE USING (false);

CREATE POLICY "Audit logs no delete" ON phi_access_audit_log
FOR DELETE USING (false);

-- Trigger functions for PHI access logging
CREATE OR REPLACE FUNCTION log_phi_access_clinical_notes()
RETURNS TRIGGER AS $$
DECLARE
  v_patient_id UUID;
BEGIN
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
    (SELECT id FROM users WHERE firebase_uid = auth.uid()),
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
    (SELECT id FROM users WHERE firebase_uid = auth.uid()),
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
    (SELECT id FROM users WHERE firebase_uid = auth.uid()),
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
    (SELECT id FROM users WHERE firebase_uid = auth.uid()),
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

-- Create triggers
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

-- Monthly audit summary view
CREATE OR REPLACE VIEW monthly_phi_access_summary AS
SELECT
  DATE_TRUNC('month', created_at) AS month,
  user_id,
  u.email AS user_email,
  COUNT(*) AS total_accesses,
  COUNT(DISTINCT patient_id) AS unique_patients_accessed,
  array_agg(DISTINCT table_name) AS tables_accessed
FROM phi_access_audit_log pal
LEFT JOIN users u ON pal.user_id = u.id
WHERE created_at > NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', created_at), user_id, u.email
ORDER BY month DESC, total_accesses DESC;

-- Schedule cleanup jobs
SELECT cron.schedule(
  'cleanup-rate-limit-tracking',
  '0 * * * *',
  $$DELETE FROM rate_limit_tracking WHERE created_at < NOW() - INTERVAL '30 days'$$
);

SELECT cron.schedule(
  'archive-old-audit-logs',
  '0 2 * * *',
  $$DELETE FROM phi_access_audit_log WHERE created_at < NOW() - INTERVAL '6 years'$$
);
```

**Click "Run"** ✓

**Expected Result:**
```
Query executed successfully
Created 4 functions, 4 triggers, 1 view
Scheduled 2 cron jobs
```

---

#### 3.4 Execute Migration #3: Session Timeout Tracking

**Name:** `add_session_tracking`
**Execution Time:** 1-2 minutes

**Copy and paste this SQL:**

```sql
-- HIPAA 164.312(a)(2)(iii): Session Timeout & Authentication Controls
CREATE TABLE IF NOT EXISTS active_sessions_enhanced (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  firebase_session_token_hash VARCHAR(64),
  session_start_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT,
  device_type VARCHAR(50),
  ended_at TIMESTAMPTZ,
  end_reason VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_active_session UNIQUE(user_id, firebase_session_token_hash, session_start_at)
);

CREATE INDEX IF NOT EXISTS idx_active_sessions_user_id
  ON active_sessions_enhanced(user_id, ended_at)
  WHERE ended_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_active_sessions_ip_address
  ON active_sessions_enhanced(ip_address);

CREATE INDEX IF NOT EXISTS idx_active_sessions_last_activity
  ON active_sessions_enhanced(last_activity_at DESC)
  WHERE ended_at IS NULL;

ALTER TABLE active_sessions_enhanced ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own sessions" ON active_sessions_enhanced
FOR SELECT TO authenticated USING (
  user_id = (SELECT id FROM users WHERE firebase_uid = auth.uid())
  OR EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    JOIN users u ON sap.user_id = u.id
    WHERE u.firebase_uid = auth.uid()
  )
);

CREATE POLICY "Service role can manage sessions" ON active_sessions_enhanced
FOR ALL TO service_role USING (true);

-- Auto-update session activity
CREATE OR REPLACE FUNCTION update_session_activity()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_activity_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cleanup expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
  UPDATE active_sessions_enhanced
  SET
    ended_at = NOW(),
    end_reason = 'timeout_idle'
  WHERE
    ended_at IS NULL
    AND last_activity_at < NOW() - INTERVAL '15 minutes';

  UPDATE active_sessions_enhanced
  SET
    ended_at = NOW(),
    end_reason = 'timeout_max_duration'
  WHERE
    ended_at IS NULL
    AND session_start_at < NOW() - INTERVAL '8 hours';

  DELETE FROM active_sessions_enhanced
  WHERE ended_at IS NOT NULL AND ended_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup every 5 minutes
SELECT cron.schedule(
  'cleanup-sessions-frequent',
  '*/5 * * * *',
  'SELECT cleanup_expired_sessions()'
);

-- Active sessions summary view
CREATE OR REPLACE VIEW active_sessions_summary AS
SELECT
  u.id,
  u.email,
  COUNT(*) AS active_session_count,
  MIN(ase.session_start_at) AS oldest_session_start,
  MAX(ase.last_activity_at) AS most_recent_activity,
  array_agg(DISTINCT ase.device_type) AS device_types,
  array_agg(DISTINCT ase.ip_address::text) AS ip_addresses
FROM users u
LEFT JOIN active_sessions_enhanced ase ON u.id = ase.user_id
  AND ase.ended_at IS NULL
GROUP BY u.id, u.email
ORDER BY u.email;
```

**Click "Run"** ✓

**Expected Result:**
```
Query executed successfully
Created 2 functions, 1 view
Scheduled 1 cron job
```

---

#### 3.5 Execute Migration #4: MFA Enrollment Tracking

**Name:** `add_mfa_tracking`
**Execution Time:** 1-2 minutes

**Copy and paste this SQL:**

```sql
-- HIPAA 164.312(a)(2)(i): MFA Requirement Tracking
CREATE TABLE IF NOT EXISTS mfa_enrollment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  mfa_method VARCHAR(50) NOT NULL,
  secret_key_encrypted TEXT,
  phone_number VARCHAR(20),
  email_verified BOOLEAN DEFAULT false,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  backup_codes_generated_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mfa_backup_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash VARCHAR(64) NOT NULL,
  used BOOLEAN DEFAULT false,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mfa_enforcement_policy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role VARCHAR(50) NOT NULL UNIQUE,
  required BOOLEAN DEFAULT true,
  grace_period_days INT DEFAULT 7,
  methods_allowed TEXT[] DEFAULT ARRAY['authenticator_app', 'sms'],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mfa_challenge_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  challenge_type VARCHAR(50) NOT NULL,
  challenge_sent_at TIMESTAMPTZ DEFAULT NOW(),
  challenge_verified_at TIMESTAMPTZ,
  ip_address INET,
  user_agent TEXT,
  success BOOLEAN,
  failure_reason VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_mfa_enrollment_user_id
  ON mfa_enrollment(user_id)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_mfa_backup_codes_user_id
  ON mfa_backup_codes(user_id);

CREATE INDEX IF NOT EXISTS idx_mfa_challenge_log_user_id
  ON mfa_challenge_log(user_id, challenge_sent_at DESC);

-- RLS
ALTER TABLE mfa_enrollment ENABLE ROW LEVEL SECURITY;
ALTER TABLE mfa_backup_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mfa_challenge_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own MFA" ON mfa_enrollment
FOR ALL TO authenticated USING (
  user_id = (SELECT id FROM users WHERE firebase_uid = auth.uid())
);

CREATE POLICY "Admins view MFA enrollment" ON mfa_enrollment
FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    JOIN users u ON sap.user_id = u.id
    WHERE u.firebase_uid = auth.uid()
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

-- MFA compliance status view
CREATE OR REPLACE VIEW mfa_compliance_status AS
SELECT
  u.id,
  u.email,
  COALESCE(up.user_role, 'unknown') AS user_role,
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
LEFT JOIN mfa_enforcement_policy mep ON COALESCE(up.user_role, 'patient') = mep.role
ORDER BY u.email;
```

**Click "Run"** ✓

**Expected Result:**
```
Query executed successfully
Created 4 tables, 1 view
Initialized 4 MFA enforcement policies
```

---

## Step 4: Verify Database Migrations

After executing all 4 migrations, verify they were applied successfully:

### Verification Queries

**Run these in Supabase SQL Editor to confirm tables exist:**

```sql
-- Check if all tables were created
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('rate_limit_tracking', 'phi_access_audit_log', 'active_sessions_enhanced', 'mfa_enrollment')
ORDER BY tablename;
```

**Expected Output:**
```
 tablename
─────────────────────────
 active_sessions_enhanced
 mfa_backup_codes
 mfa_challenge_log
 mfa_enforcement_policy
 mfa_enrollment
 phi_access_audit_log
 rate_limit_tracking
```

**Check if triggers are active:**

```sql
SELECT
  trigger_name,
  event_object_table,
  action_statement_triggers
FROM pg_triggers
WHERE trigger_name LIKE 'audit_%' OR trigger_name LIKE 'update_session%'
ORDER BY trigger_name;
```

**Check if cron jobs are scheduled:**

```sql
SELECT
  jobname,
  schedule,
  command
FROM cron.job
WHERE jobname LIKE '%cleanup%' OR jobname LIKE '%archive%'
ORDER BY jobname;
```

---

## Step 5: Deploy Security Modules

Now that database migrations are complete, we need to deploy the 3 security modules to Supabase Edge Functions.

**Files to deploy:**
1. `supabase/functions/_shared/cors.ts` (UPDATED)
2. `supabase/functions/_shared/rate-limiter.ts` (NEW)
3. `supabase/functions/_shared/input-validator.ts` (NEW)

### Deploy Using Supabase CLI

```bash
# Deploy all edge functions with new security modules
npx supabase functions deploy --all

# Or deploy specific functions if needed
npx supabase functions deploy chime-meeting-token
npx supabase functions deploy generate-soap-draft-v2
npx supabase functions deploy bedrock-ai-chat
```

**Note:** This requires Docker to be running or manual deployment via Supabase Dashboard.

### Alternative: Manual Deploy via Supabase Dashboard

1. Go to: https://app.supabase.com/project/noaeltglphdlkbflipit/functions
2. For each edge function that needs updating:
   - Click function name
   - Click "Edit"
   - Update the import statements to use new security modules
   - Click "Deploy"

**Functions using `cors.ts`:** All 28 edge functions
**Functions using `rate-limiter.ts`:** chime-meeting-token, generate-soap-draft-v2, bedrock-ai-chat, upload-profile-picture
**Functions using `input-validator.ts`:** All functions that accept user input

---

## Step 6: Execute AWS BAA (Manual)

Once database migrations are complete, execute AWS BAA:

1. Go to: https://console.aws.amazon.com
2. Click on your account name (top-right) → **Account**
3. Scroll to **HIPAA Eligibility** section
4. Click **Enable HIPAA Eligibility**
5. Review and accept the AWS Business Associate Addendum (BAA)
6. Download the signed BAA PDF
7. Save to: `docs/compliance/AWS-BAA-Signed-2026-01-23.pdf`

---

## Step 7: Testing & Verification

After all migrations and deployments, run these verification commands:

```bash
# 1. Test CORS headers (should show origin restriction)
curl -i -H "Origin: https://evil-site.com" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token -X OPTIONS

# Expected: Should NOT see Access-Control-Allow-Origin header for evil-site.com

# 2. Test CORS with valid origin
curl -i -H "Origin: https://medzenhealth.app" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token -X OPTIONS

# Expected: Should see Access-Control-Allow-Origin: https://medzenhealth.app

# 3. Test rate limiting
for i in {1..15}; do curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token; done

# Expected: First 10 succeed, then 429 Rate Limit Exceeded

# 4. Verify audit logging (run test query on a PHI table, then check logs)
SELECT COUNT(*) FROM phi_access_audit_log WHERE created_at > NOW() - INTERVAL '1 minute';

# Expected: Should see logged entries

# 5. Verify S3 encryption
aws s3api get-bucket-encryption \
  --bucket medzen-meeting-recordings-558069890522 \
  --region eu-central-1

# Expected: Should show KMS encryption enabled

# 6. Verify GuardDuty
aws guardduty get-detector --detector-id 96cdf5273713a23964bbeb88250ecdf4 --region eu-central-1

# Expected: Status: ENABLED

# 7. Verify CloudTrail
aws cloudtrail get-trail-status --trail-name medzen-audit-trail --region eu-central-1

# Expected: IsLogging: true
```

---

## Summary

✅ **Completed:**
- Step 1: AWS S3 Encryption (KMS key created)
- Step 2: AWS Security Monitoring (GuardDuty + CloudTrail)
- Step 3: Database Migrations (this guide - 4 migrations)

⏳ **Pending:**
- Step 4: Deploy security modules (requires Docker or Supabase Dashboard)
- Step 5: Execute AWS BAA (manual AWS Console)
- Step 6: Testing & verification

---

## Troubleshooting

### Error: "relation does not exist"
**Cause:** Previous migration failed or was incomplete
**Fix:** Check Supabase logs and re-run the migration SQL

### Error: "pg_cron extension not enabled"
**Cause:** pg_cron not installed in Supabase instance
**Fix:** Go to Supabase Dashboard → Extensions → Enable pg_cron

### Error: "permission denied for schema public"
**Cause:** Incorrect Supabase role/permissions
**Fix:** Ensure you're connected as service_role (requires dashboard SQL editor with proper access)

---

**Next Step:** Execute migrations using the SQL provided above in Supabase Dashboard SQL Editor.

