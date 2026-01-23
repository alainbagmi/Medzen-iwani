# Phase 1 Deployment Checklist (TODAY - HIPAA Emergency Response)

**Status:** 🚨 IN PROGRESS
**Target Completion:** TODAY (12 hours)
**Team:** 1-2 engineers
**Priority:** 🔴 CRITICAL

---

## Pre-Deployment (30 minutes)

- [ ] Review this entire checklist with team
- [ ] Confirm AWS account access (`558069890522`)
- [ ] Confirm Supabase project access (`noaeltglphdlkbflipit`)
- [ ] Backup current database schema
- [ ] Notify stakeholders of maintenance (if needed)

**Estimated Time:** 30 min

---

## Step 1: Apply Database Migrations (30 minutes)

**Files to deploy:**
```
supabase/migrations/20260123120100_add_rate_limiting.sql
supabase/migrations/20260123120200_add_phi_access_audit.sql
supabase/migrations/20260123120300_add_session_tracking.sql
supabase/migrations/20260123120400_add_mfa_tracking.sql
```

**Commands:**
```bash
# Navigate to project directory
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Push migrations to Supabase
npx supabase db push

# Verify migrations applied
npx supabase migration list
```

**Verification:**
```sql
-- Check rate_limit_tracking table exists
SELECT tablename FROM pg_tables WHERE tablename = 'rate_limit_tracking';

-- Check phi_access_audit_log table exists
SELECT tablename FROM pg_tables WHERE tablename = 'phi_access_audit_log';

-- Check active_sessions_enhanced table exists
SELECT tablename FROM pg_tables WHERE tablename = 'active_sessions_enhanced';

-- Check mfa_enforcement_policy has data
SELECT * FROM mfa_enforcement_policy;
```

**Expected Results:**
- ✅ All 4 tables created
- ✅ Triggers activated for PHI audit logging
- ✅ MFA enforcement policies initialized
- ✅ Cron jobs scheduled for cleanup

**Estimated Time:** 30 min
**Status:** [ ]

---

## Step 2: Deploy AWS S3 Encryption (45 minutes)

**File:** `aws-deployment/scripts/enable-s3-encryption.sh`

**Prerequisites:**
- AWS CLI installed and configured
- Appropriate IAM permissions for KMS and S3

**Commands:**
```bash
# Navigate to project directory
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Make script executable
chmod +x aws-deployment/scripts/enable-s3-encryption.sh

# Run encryption setup
./aws-deployment/scripts/enable-s3-encryption.sh

# Verify encryption on buckets
aws s3api get-bucket-encryption \
  --bucket medzen-meeting-recordings-558069890522 \
  --region eu-central-1
```

**Expected Output:**
```json
{
  "ServerSideEncryptionConfiguration": {
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "aws:kms",
          "KMSMasterKeyID": "arn:aws:kms:eu-central-1:558069890522:key/..."
        },
        "BucketKeyEnabled": true
      }
    ]
  }
}
```

**Document:**
- Store KMS Key ID: `_________________________________`
- Store in environment: `export AWS_S3_KMS_KEY_ID='...'`

**Estimated Time:** 45 min
**Status:** [ ]

---

## Step 3: Enable AWS Security Monitoring (15 minutes)

### Enable GuardDuty

```bash
# Create GuardDuty detector
aws guardduty create-detector \
  --region eu-central-1 \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES

# Capture detector ID
DETECTOR_ID=$(aws guardduty list-detectors \
  --region eu-central-1 \
  --query 'DetectorIds[0]' \
  --output text)

echo "GuardDuty Detector ID: $DETECTOR_ID"
```

**Verification:**
```bash
aws guardduty get-detector \
  --detector-id $DETECTOR_ID \
  --region eu-central-1 \
  --query 'Status' \
  --output text
# Expected: ENABLED
```

### Enable CloudTrail

```bash
# Create S3 bucket for CloudTrail logs (if not exists)
aws s3api create-bucket \
  --bucket medzen-cloudtrail-logs-558069890522 \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1 \
  2>/dev/null || true

# Create trail
aws cloudtrail create-trail \
  --name medzen-audit-trail \
  --s3-bucket-name medzen-cloudtrail-logs-558069890522 \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --region eu-central-1

# Start logging
aws cloudtrail start-logging \
  --trail-name medzen-audit-trail \
  --region eu-central-1
```

**Verification:**
```bash
aws cloudtrail get-trail-status \
  --trail-name medzen-audit-trail \
  --region eu-central-1
# Expected: IsLogging: true
```

**Estimated Time:** 15 min
**Status:** [ ]

---

## Step 4: Update CORS Configuration (30 minutes)

**Files Modified:**
- `supabase/functions/_shared/cors.ts` ✅ (already updated)

**New Shared Modules:**
- `supabase/functions/_shared/rate-limiter.ts` ✅ (already created)
- `supabase/functions/_shared/input-validator.ts` ✅ (already created)

**Deployment:**
```bash
# Deploy shared modules
npx supabase functions deploy --all
```

**Testing CORS Policy:**
```bash
# Test 1: Unauthorized origin (should fail)
curl -i \
  -H "Origin: https://evil-site.com" \
  -H "Content-Type: application/json" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -X OPTIONS

# Expected: No "Access-Control-Allow-Origin" header or different origin

# Test 2: Authorized origin (should succeed)
curl -i \
  -H "Origin: https://medzenhealth.app" \
  -H "Content-Type: application/json" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -X OPTIONS

# Expected: Access-Control-Allow-Origin: https://medzenhealth.app
```

**Estimated Time:** 30 min
**Status:** [ ]

---

## Step 5: Test Rate Limiting (15 minutes)

**Test Script:**
```bash
#!/bin/bash
# Test rate limiting with 15 requests (limit is 10/min)

ENDPOINT="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
TOKEN="<YOUR_FIREBASE_TOKEN>"  # Get from authenticated user

echo "Testing rate limiting..."
for i in {1..15}; do
  echo "Request $i..."
  curl -s -X POST "$ENDPOINT" \
    -H "Authorization: Bearer $TOKEN" \
    -H "x-firebase-token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"create","appointmentId":"12345678-1234-1234-1234-123456789012"}' \
    | jq '.status, .error' 2>/dev/null || echo "Request $i: Error/Rate limited"
  sleep 1
done
```

**Expected Results:**
- Requests 1-10: 200 OK
- Requests 11-15: 429 Rate Limit Exceeded

**Estimated Time:** 15 min
**Status:** [ ]

---

## Step 6: Verify PHI Audit Logging (10 minutes)

**Test Script:**
```sql
-- 1. Create test clinical note
INSERT INTO clinical_notes (
  appointment_id,
  patient_id,
  provider_id,
  subjective,
  objective,
  assessment,
  plan,
  created_at
) VALUES (
  '12345678-1234-1234-1234-123456789012',
  '87654321-4321-4321-4321-210987654321',
  'current_user_id',
  'Test subjective',
  'Test objective',
  'Test assessment',
  'Test plan',
  NOW()
);

-- 2. Verify audit log entry
SELECT * FROM phi_access_audit_log
WHERE table_name = 'clinical_notes'
  AND created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 1;

-- 3. Verify monthly summary view
SELECT * FROM monthly_phi_access_summary LIMIT 5;
```

**Expected Results:**
- ✅ Audit log entry created for clinical_notes insert
- ✅ Access type marked as 'write'
- ✅ Patient ID captured
- ✅ Timestamp recorded

**Estimated Time:** 10 min
**Status:** [ ]

---

## Step 7: Execute AWS BAA (30 minutes)

**Manual Steps in AWS Console:**

1. **Login to AWS Console**
   - URL: https://console.aws.amazon.com
   - Account: `558069890522`
   - Login with admin credentials

2. **Navigate to Account Settings**
   - Click on account name (top right)
   - Select "Account"
   - Scroll to "HIPAA Eligibility"

3. **Review and Accept BAA**
   - Read AWS Business Associate Addendum
   - Click "I acknowledge and agree"
   - Sign digitally (if prompted)

4. **Download Signed BAA**
   - Navigate to Account → Agreements
   - Find "AWS Business Associate Addendum"
   - Download PDF

5. **Store in Project**
   ```bash
   mkdir -p docs/compliance
   cp ~/Downloads/AWS-BAA-*.pdf \
      /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/docs/compliance/AWS-BAA-Signed-2026-01-23.pdf
   ```

6. **Verify HIPAA-Eligible Services**
   - S3 ✅
   - Chime SDK ✅
   - Transcribe Medical ✅
   - Bedrock ✅
   - KMS ✅
   - CloudTrail ✅
   - GuardDuty ✅

**Documentation:**
- BAA PDF stored: `docs/compliance/AWS-BAA-Signed-2026-01-23.pdf`
- Execution date: `_____________`
- Signed by: `_____________`

**Estimated Time:** 30 min
**Status:** [ ]

---

## Step 8: Create Compliance Documentation (30 minutes)

**Files Already Created:** ✅
- `docs/compliance/AWS-BAA-TRACKING.md`
- `aws-deployment/scripts/enable-s3-encryption.sh`
- `supabase/functions/_shared/cors.ts`
- `supabase/functions/_shared/rate-limiter.ts`
- `supabase/functions/_shared/input-validator.ts`

**Final Documentation Steps:**

1. Update BAA tracking document
```bash
# Edit docs/compliance/AWS-BAA-TRACKING.md
# Add execution date to "AWS Account" row
# Mark status as "🟢 Signed" instead of "Ready"
```

2. Create risk acceptance log
```bash
cat > /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/docs/compliance/RISK-ACCEPTANCE-LOG.md <<'EOF'
# Risk Acceptance Log

**Date:** 2026-01-23
**Authority:** [CTO Name]

## Accepted Risks

### Firebase BAA Pending (30 days)
- **Risk:** Firebase BAA not signed
- **Mitigation:** User will execute separately within 30 days
- **Impact:** Medium - Firebase services cannot legally process PHI
- **Acceptance:** Yes
- **Deadline:** 2026-02-23

### Supabase BAA Pending (30 days)
- **Risk:** Supabase Enterprise + BAA not signed
- **Mitigation:** User will execute separately within 30 days
- **Impact:** High - Supabase is primary database
- **Acceptance:** Yes
- **Deadline:** 2026-02-23

### Penetration Testing Deferred
- **Risk:** No professional pentest conducted
- **Mitigation:** Using free OWASP ZAP scanning
- **Impact:** Medium - Potential unknown vulnerabilities
- **Acceptance:** Yes
- **Revisit:** 2026-02-23

---
**Approval Signature:** _______________
**Date:** _______________
EOF
```

**Estimated Time:** 30 min
**Status:** [ ]

---

## Post-Deployment Verification (30 minutes)

### Checklist

```bash
# 1. Verify database migrations
psql -h 127.0.0.1 -U postgres -d postgres -c \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('rate_limit_tracking', 'phi_access_audit_log', 'active_sessions_enhanced', 'mfa_enrollment')"
# Expected: 4

# 2. Verify S3 encryption (spot check)
aws s3api get-bucket-encryption \
  --bucket medzen-meeting-recordings-558069890522 \
  --region eu-central-1 \
  --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' \
  --output text
# Expected: aws:kms

# 3. Verify GuardDuty status
aws guardduty list-detectors --region eu-central-1 --query 'DetectorIds[0]' --output text
# Expected: [detector-id]

# 4. Verify CloudTrail status
aws cloudtrail get-trail-status --trail-name medzen-audit-trail --region eu-central-1 --query 'IsLogging' --output text
# Expected: true

# 5. Verify CORS headers deployed
curl -i https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "Origin: https://medzenhealth.app" \
  -X OPTIONS | grep -i "access-control"
# Expected: Access-Control-Allow-Origin header present

# 6. Verify AWS BAA document exists
ls -la /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/docs/compliance/AWS-BAA-Signed-*.pdf
# Expected: File exists
```

**Estimated Time:** 30 min
**Status:** [ ]

---

## Risk Assessment & Sign-Off

### Go/No-Go Decision

**Critical Issues Found?**
- [ ] YES → STOP and troubleshoot
- [ ] NO → Continue

**All verifications passed?**
- [ ] YES → Proceed to sign-off
- [ ] NO → Fix and re-verify

### Sign-Off

I certify that Phase 1 HIPAA Emergency Response has been completed:

**AWS Infrastructure Compliance:**
- ✅ AWS BAA executed
- ✅ CORS security headers deployed
- ✅ Rate limiting implemented
- ✅ PHI audit logging active
- ✅ S3 encryption enabled (KMS)
- ✅ GuardDuty monitoring enabled
- ✅ CloudTrail logging enabled
- ⏸️ Firebase/Supabase BAAs (user handling separately)

**Signed by (Engineer):** _______________
**Name:** _______________
**Date/Time:** _______________

**Approved by (CTO):** _______________
**Name:** _______________
**Date/Time:** _______________

---

## Rollback Plan (If Needed)

**If critical issue found:**

1. **Disable rate limiting** (revert cors.ts to simple CORS)
```bash
git checkout HEAD^ supabase/functions/_shared/cors.ts
npx supabase functions deploy --all
```

2. **Drop new tables**
```bash
npx supabase db push --reset-migrations
# or manually drop:
# DROP TABLE IF EXISTS rate_limit_tracking CASCADE;
# DROP TABLE IF EXISTS phi_access_audit_log CASCADE;
```

3. **Disable AWS monitoring**
```bash
aws guardduty delete-detector --detector-id $DETECTOR_ID --region eu-central-1
aws cloudtrail delete-trail --name medzen-audit-trail --region eu-central-1
```

4. **Revert S3 encryption** (keep, as it's non-destructive)

---

## Estimated Timeline

| Step | Task | Duration | Cumulative |
|------|------|----------|-----------|
| Pre | Review & Backup | 30 min | 30 min |
| 1 | Database Migrations | 30 min | 60 min |
| 2 | S3 Encryption | 45 min | 105 min |
| 3 | AWS Monitoring | 15 min | 120 min |
| 4 | CORS Update | 30 min | 150 min |
| 5 | Rate Limiting Test | 15 min | 165 min |
| 6 | Audit Logging Test | 10 min | 175 min |
| 7 | AWS BAA | 30 min | 205 min |
| 8 | Documentation | 30 min | 235 min |
| 9 | Verification | 30 min | 265 min |
| 10 | Sign-Off | 15 min | 280 min |

**Total: ~4.5-5.5 hours** (with breaks and troubleshooting)

---

## Support & Escalation

**Issues During Deployment?**

1. Check `/var/log/` for error messages
2. Review Supabase logs: `npx supabase functions logs <name> --tail`
3. Contact: [CTO] at [email]
4. Escalate if: Any P0 security issues or data loss

---

**Document Control:**
**Version:** 1.0
**Date:** 2026-01-23
**Status:** IN PROGRESS
**Next Step:** Begin Step 1
