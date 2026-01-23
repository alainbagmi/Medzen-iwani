# MedZen Security Remediation - Phase 2 & 4 Execution Roadmap

**Document Date:** 2026-01-23
**Status:** Ready for Execution
**Phase 1 Status:** 42% complete (25/59 functions, agent ac9da87 running)
**Phase 2 & 4 Status:** All preparation complete, ready to execute immediately after Phase 1

---

## Overview

This document provides a unified execution roadmap for **Phase 2 (AWS Infrastructure Verification)** and **Phase 4 (Security Testing)** following Phase 1 completion.

**Timeline:**
- **Phase 1 Completion Expected:** 2-4 hours from 14:00 UTC (agent ac9da87)
- **Phase 2 Execution Window:** 15-30 minutes (requires AWS credentials)
- **Phase 3:** Already 100% complete ✅
- **Phase 4 Execution Window:** 2-3 hours (after Phase 1 confirmation)

---

## PHASE 2: AWS Infrastructure Verification (1 Hour)

**Critical Requirement:** AWS credentials with appropriate IAM permissions

### Prerequisites Checklist

```bash
# ✅ Verify AWS CLI is installed
aws --version

# ✅ Verify AWS credentials are configured
aws sts get-caller-identity
# Expected output should show Account: 558069890522

# ✅ Verify IAM permissions
# Required: kms:*, s3:*, guardduty:*, cloudtrail:*
```

### Execution Sequence

#### Task 2.1: S3 KMS Encryption (5 minutes)

**Script Location:** `aws-deployment/scripts/enable-s3-encryption.sh`

```bash
# STEP 1: Navigate to project root
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# STEP 2: Make script executable
chmod +x aws-deployment/scripts/enable-s3-encryption.sh

# STEP 3: Execute script
./aws-deployment/scripts/enable-s3-encryption.sh

# EXPECTED OUTPUT:
# 🔒 MedZen HIPAA S3 Encryption Setup
# ====================================
#
# 🔑 Creating KMS key for S3 encryption...
# ✅ KMS Key created: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# ✅ KMS Key alias created: alias/medzen-s3-phi
#
# 🔐 Enabling encryption on S3 buckets...
# ✅ medzen-meeting-recordings-558069890522 encrypted
# ✅ medzen-meeting-transcripts-558069890522 encrypted
# ✅ medzen-medical-data-558069890522 encrypted
#
# ====================================
# ✅ S3 Encryption Setup Complete
# KMS Key ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Action Items:**
1. Copy KMS Key ID from output
2. Add to `.env` file: `AWS_S3_KMS_KEY_ID='[copied-key-id]'`
3. Document in secure location

#### Task 2.2: GuardDuty Verification (3 minutes)

**Script Location:** `aws-deployment/scripts/verify-guardduty.sh`

```bash
# STEP 1: Make script executable
chmod +x aws-deployment/scripts/verify-guardduty.sh

# STEP 2: Execute script
./aws-deployment/scripts/verify-guardduty.sh

# EXPECTED OUTPUT:
# 🔍 MedZen GuardDuty Verification
# ==================================
#
# ✅ GuardDuty detector found: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#    Status: ENABLED
#    Finding Publishing: FIFTEEN_MINUTES
#
# ==================================
# ✅ GuardDuty Verification Complete
```

**Action Items:**
1. Note GuardDuty Detector ID (for monitoring)
2. Verify status is ENABLED
3. Document in compliance matrix

#### Task 2.3: CloudTrail Verification (5 minutes)

**Script Location:** `aws-deployment/scripts/verify-cloudtrail.sh`

```bash
# STEP 1: Make script executable
chmod +x aws-deployment/scripts/verify-cloudtrail.sh

# STEP 2: Execute script
./aws-deployment/scripts/verify-cloudtrail.sh

# EXPECTED OUTPUT:
# 🔍 MedZen CloudTrail Verification
# ==================================
#
# ✅ CloudTrail trail found: medzen-audit-trail
# ✅ Multi-region trail enabled
# ✅ Log file validation enabled
# ✅ CloudTrail logging is ACTIVE
#
# 📋 Recent CloudTrail Events (last 10):
# [table of recent events]
#
# ==================================
# ✅ CloudTrail Verification Complete
```

**Action Items:**
1. Verify trail status is ACTIVE
2. Confirm log delivery to S3
3. Document in security checklist

### Phase 2 Success Criteria

```
✅ PASS if ALL conditions met:
  ✅ KMS key created with alias/medzen-s3-phi
  ✅ All 3 S3 buckets encrypted with KMS
  ✅ Unencrypted upload policy enforced
  ✅ GuardDuty detector ENABLED
  ✅ CloudTrail trail ENABLED and logging ACTIVE
  ✅ Multi-region trail configuration verified
  ✅ Log file validation ENABLED
```

### Phase 2 Troubleshooting

| Issue | Solution |
|-------|----------|
| **"Failed to create KMS key"** | Verify IAM permissions include `kms:CreateKey`. Attach policy: `arn:aws:iam::aws:policy/KMSFullAccess` |
| **"Bucket does not exist"** | S3 buckets must be created first. Run: `aws s3 mb s3://medzen-meeting-recordings-558069890522 --region eu-central-1` |
| **"GuardDuty detector not found"** | Script auto-creates detector. Re-run script if still fails. |
| **"CloudTrail S3 bucket error"** | Ensure `medzen-cloudtrail-logs` bucket exists and CloudTrail has S3 write permissions |
| **AWS credentials not found** | Run: `aws configure` or set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` environment variables |

---

## PHASE 4: Comprehensive Security Testing (2-3 Hours)

**Prerequisite:** Phase 1 must be 100% complete (all 59 functions hardened)

### Pre-Testing Verification

```bash
# VERIFY ALL FUNCTIONS DEPLOYED
# Check that all 59 functions have been hardened

npx supabase functions list

# Should show 59 total functions (or closest count)
```

### Testing Sequence

#### Test 1: CORS Security (30 minutes)

**Test File:** `docs/PHASE4-SECURITY-TESTING-EXECUTION.md` (Test 1 section)

**Test 1.1: Unauthorized Domain Blocking**
```bash
# TEST: Unauthorized domain should be BLOCKED
curl -i \
  -H "Origin: https://evil-site.com" \
  -H "x-firebase-token: [valid-token]" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token

# EXPECTED RESULT:
# ❌ No Access-Control-Allow-Origin header
# OR ❌ Error response (401/403)
```

**Test 1.2: Authorized Domain Allowed**
```bash
# TEST: Authorized domain should be ALLOWED
curl -i \
  -H "Origin: https://medzenhealth.app" \
  -H "x-firebase-token: [valid-token]" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token

# EXPECTED RESULT:
# ✅ Access-Control-Allow-Origin: https://medzenhealth.app
# ✅ Security headers present
```

**Test 1.3: Security Headers**
```bash
# TEST: All responses include security headers
curl -i \
  -H "Origin: https://medzenhealth.app" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token

# EXPECTED HEADERS:
# ✅ Content-Security-Policy (CSP)
# ✅ Strict-Transport-Security (HSTS)
# ✅ X-Frame-Options: DENY
# ✅ X-Content-Type-Options: nosniff
```

**Success:** All 59 functions pass CORS tests

#### Test 2: Rate Limiting (30 minutes)

**Test 2.1: Rate Limit Enforcement**
```bash
#!/bin/bash
# TEST: Exceed rate limit, should get 429

TOKEN="[valid-firebase-token]"
ENDPOINT="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"

# Function-specific limit: 10 req/min
# Try 15 rapid requests

for i in {1..15}; do
  curl -X POST "$ENDPOINT" \
    -H "x-firebase-token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}' \
    -w "Request %d: %{http_code}\n" &
done

wait

# EXPECTED RESULT:
# ✅ Requests 1-10: 200 OK
# ✅ Requests 11-15: 429 Too Many Requests
```

**Test 2.2: Retry-After Header**
```bash
# TEST: Verify Retry-After header is present after rate limit
curl -i -X POST "$ENDPOINT" [trigger 11th request after limit] \
  -H "x-firebase-token: $TOKEN"

# EXPECTED HEADER:
# ✅ Retry-After: [seconds]
```

**Success:** All functions enforce per-endpoint rate limits

#### Test 3: Input Validation (30 minutes)

**Test 3.1: XSS Prevention**
```bash
# TEST: XSS payload should be blocked/sanitized
TOKEN="[valid-token]"

curl -X POST \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "x-firebase-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"<script>alert(\"xss\")</script>"}'

# EXPECTED RESULT:
# ✅ Payload rejected or sanitized
# ✅ No script execution
```

**Test 3.2: SQL Injection Prevention**
```bash
# TEST: SQL injection attempt should be blocked
curl -X POST \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "x-firebase-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"1\" OR \"1\"=\"1"}'

# EXPECTED RESULT:
# ✅ Rejected with error or safely parameterized
```

**Test 3.3: UUID Validation**
```bash
# TEST: Invalid UUID should be rejected
curl -X POST \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "x-firebase-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"appointment_id":"not-a-uuid"}'

# EXPECTED RESULT:
# ✅ 400 Bad Request
# ✅ Error message: "Invalid appointmentId format"
```

**Success:** All critical functions validate input

#### Test 4: Encryption (30 minutes)

**Test 4.1: TLS 1.2+ Enforcement**
```bash
# TEST: Verify TLS 1.2 minimum
openssl s_client -connect noaeltglphdlkbflipit.supabase.co:443 -tls1_2

# EXPECTED RESULT:
# ✅ Connection successful
# ✅ Protocol: TLSv1.2 or TLSv1.3
```

**Test 4.2: S3 Encryption Verification**
```bash
# TEST: Verify S3 buckets are encrypted with KMS
aws s3api get-bucket-encryption \
  --bucket medzen-meeting-recordings-558069890522 \
  --region eu-central-1

# EXPECTED OUTPUT:
# {
#   "ServerSideEncryptionConfiguration": {
#     "Rules": [{
#       "ApplyServerSideEncryptionByDefault": {
#         "SSEAlgorithm": "aws:kms",
#         "KMSMasterKeyID": "arn:aws:kms:eu-central-1:558069890522:key/..."
#       }
#     }]
#   }
# }
```

**Success:** All data in transit encrypted (TLS) and at rest encrypted (KMS)

#### Test 5: Audit Logging (30 minutes)

**Test 5.1: API Logging**
```bash
# TEST: Verify API calls are logged

# Make API request
curl -X POST \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "x-firebase-token: $TOKEN"

# Check CloudTrail logs
aws cloudtrail lookup-events \
  --region eu-central-1 \
  --max-results 5

# EXPECTED RESULT:
# ✅ API calls appear in logs within 5 minutes
# ✅ User identity captured
# ✅ Timestamp recorded
```

**Test 5.2: 6-Year Retention Verification**
```bash
# TEST: Verify log retention policy
aws s3api get-bucket-lifecycle-configuration \
  --bucket medzen-cloudtrail-logs \
  --region eu-central-1

# EXPECTED: Retention >= 2190 days (6 years)
```

**Success:** All audit logs preserved for compliance

#### Test 6: Integration (30 minutes)

**Complete End-to-End Request Flow**
```bash
# FULL INTEGRATION TEST

TOKEN="[valid-firebase-token]"
ENDPOINT="https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat"

# 1. Verify CORS
curl -i -H "Origin: https://medzenhealth.app" "$ENDPOINT"
# ✅ CORS headers present

# 2. Verify authentication
curl -i -X POST "$ENDPOINT" -H "Content-Type: application/json" -d '{}'
# ✅ 401 Unauthorized (missing token)

# 3. Verify rate limiting
for i in {1..12}; do
  curl -s -X POST "$ENDPOINT" \
    -H "x-firebase-token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"message":"test"}' &
done
wait
# ✅ First 10 succeed, 11-12 get 429

# 4. Verify security headers
curl -i -X POST "$ENDPOINT" \
  -H "x-firebase-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
# ✅ All security headers present

# 5. Verify input validation
curl -i -X POST "$ENDPOINT" \
  -H "x-firebase-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"<script>alert(1)</script>"}'
# ✅ Payload sanitized or rejected
```

**Success:** All 6 security layers working together

### Phase 4 Success Criteria

```
✅ PHASE 4 PASS if ALL conditions met:

CORS Security:
  ✅ Unauthorized domains blocked (0% wildcard)
  ✅ Authorized domains allowed
  ✅ Security headers on all responses

Rate Limiting:
  ✅ Per-function limits enforced
  ✅ 429 responses after threshold
  ✅ Retry-After headers present

Input Validation:
  ✅ XSS payloads blocked
  ✅ SQL injection attempts blocked
  ✅ Invalid UUIDs rejected

Encryption:
  ✅ TLS 1.2+ enforced on all endpoints
  ✅ S3 buckets encrypted with KMS AES-256

Audit Logging:
  ✅ API calls logged and queryable
  ✅ 6-year retention policy verified

Integration:
  ✅ Complete workflow passes all security checks
```

### Phase 4 Test Results Recording

After executing tests, document results:

```markdown
# PHASE 4 TEST RESULTS - [DATE]

## Test Execution Summary
- **Start Time:** [time]
- **End Time:** [time]
- **Total Tests:** 30+
- **Pass Rate:** [percentage]
- **Failed Tests:** [count] (if any)

## Test Results by Category

### CORS Security
- ✅ Test 1.1: Unauthorized blocking - PASS
- ✅ Test 1.2: Authorized allowing - PASS
- ✅ Test 1.3: Security headers - PASS

### Rate Limiting
- ✅ Test 2.1: Enforcement - PASS
- ✅ Test 2.2: Retry-After headers - PASS

### Input Validation
- ✅ Test 3.1: XSS prevention - PASS
- ✅ Test 3.2: SQL injection prevention - PASS
- ✅ Test 3.3: UUID validation - PASS

### Encryption
- ✅ Test 4.1: TLS 1.2+ - PASS
- ✅ Test 4.2: S3 encryption - PASS

### Audit Logging
- ✅ Test 5.1: API logging - PASS
- ✅ Test 5.2: Retention policy - PASS

### Integration
- ✅ Test 6.1: End-to-end flow - PASS

## Approval Signature
- **Tested By:** [name]
- **Date:** [date]
- **Status:** ✅ APPROVED FOR PRODUCTION
```

---

## Post-Phase-4: Production Deployment Checklist

```
BEFORE GOING TO PRODUCTION:

Phase 1: Edge Function Security
  ✅ All 59 functions hardened
  ✅ Zero wildcard CORS policies
  ✅ 100% rate limiting coverage
  ✅ All critical functions validate input
  ✅ All responses include security headers

Phase 2: AWS Infrastructure
  ✅ S3 encryption enabled (KMS AES-256)
  ✅ GuardDuty detector active and monitoring
  ✅ CloudTrail logging enabled and validated
  ✅ Multi-region trail configured
  ✅ Log file validation enabled

Phase 3: Documentation
  ✅ Deployment guide complete (80+ pages)
  ✅ Architecture diagrams created
  ✅ Security testing procedures documented
  ✅ Incident response playbook finalized
  ✅ HIPAA/GDPR compliance matrices completed

Phase 4: Security Testing
  ✅ CORS security tests: 100% PASS
  ✅ Rate limiting tests: 100% PASS
  ✅ Input validation tests: 100% PASS
  ✅ Encryption tests: 100% PASS
  ✅ Audit logging tests: 100% PASS
  ✅ Integration tests: 100% PASS

Final Verification:
  ✅ No P0 (critical) vulnerabilities
  ✅ No P1 (high) unresolved vulnerabilities
  ✅ HIPAA technical safeguards verified
  ✅ GDPR Article 32 compliance verified
  ✅ Zero-trust architecture implemented
  ✅ Monitoring and alerting operational
```

---

## Rollback Plan

If Phase 2 or Phase 4 reveals critical issues:

1. **Immediate:** Disable affected functions in production
2. **Investigate:** Review logs and identify root cause
3. **Fix:** Apply security patch to function code
4. **Verify:** Re-deploy and re-test
5. **Monitor:** Watch metrics for 24 hours
6. **Document:** Record incident and resolution

---

## Contact & Escalation

**During Execution:**
- Primary: [Team Contact]
- Backup: [Backup Contact]
- Security: [Security Team]
- AWS Support: Open ticket for infrastructure issues

**For Blocking Issues:**
- Escalate to: CTO
- Document in: Incident Response Playbook
- Notify: Legal/Compliance (if relevant)

---

**Document Version:** 1.0
**Created:** 2026-01-23
**Status:** Ready for Execution
**Last Updated:** 2026-01-23

