# MedZen Secure Telemedicine - Security Testing Procedures (Phase 4)

**Document Version:** 1.0
**Last Updated:** 2026-01-23
**Status:** Phase 4 - Verification & Testing
**Risk Level:** HIGH - Critical vulnerabilities being remediated

---

## Executive Summary

This document defines comprehensive security testing procedures for MedZen's Phase 1 security integration (CORS, rate limiting, input validation). All 59 edge functions must pass these tests before production deployment.

**Testing Scope:**
- ✅ CORS origin validation (42 functions)
- ✅ Rate limiting enforcement (59 functions)
- ✅ Input validation (20+ critical functions)
- ✅ Security headers presence (all functions)
- ✅ Encryption verification (S3 + RDS)
- ✅ Audit logging (6-year retention)

**Test Environment:** Staging (eu-west-1)
**Expected Duration:** 2-3 hours
**Success Criteria:** 100% of tests passing, 0 CORS vulnerabilities, 0 unprotected endpoints

---

## SECTION 1: CORS SECURITY TESTING

### Test 1.1: Unauthorized Domain Blocking

**Objective:** Verify that requests from unauthorized origins are blocked.

**Test Cases:**

```bash
# Test: Unauthorized domain (evil-site.com) should be blocked
curl -X POST \
  -H "Origin: https://evil-site.com" \
  -H "Content-Type: application/json" \
  -H "x-firebase-token: $VALID_TOKEN" \
  -d '{"test":"data"}' \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token

# Expected Response: HTTP 200 but NO Access-Control-Allow-Origin header
# OR HTTP 403 if blocked entirely
# Failure: Header shows 'Access-Control-Allow-Origin: *'
```

**Test Script:**

```bash
#!/bin/bash
set -e

ENDPOINTS=(
  "chime-meeting-token"
  "generate-soap-draft-v2"
  "bedrock-ai-chat"
  "create-context-snapshot"
  "update-patient-medical-record"
  "chime-messaging"
  "upload-profile-picture"
  "storage-sign-url"
  "start-medical-transcription"
  "sync-to-ehrbase"
)

EVIL_DOMAINS=(
  "https://evil-site.com"
  "https://attacker.io"
  "https://phishing.org"
  "http://localhost:8000"
  "file:///"
)

PASS=0
FAIL=0

for endpoint in "${ENDPOINTS[@]}"; do
  for domain in "${EVIL_DOMAINS[@]}"; do
    response=$(curl -s -w "\n%{http_code}" \
      -H "Origin: $domain" \
      https://noaeltglphdlkbflipit.supabase.co/functions/v1/$endpoint)

    status_code=$(echo "$response" | tail -1)
    headers=$(echo "$response" | sed '$d')

    # Check: CORS header should NOT match evil domain
    if echo "$headers" | grep -q "Access-Control-Allow-Origin: \*"; then
      echo "❌ FAIL: $endpoint allows wildcard CORS from $domain"
      ((FAIL++))
    elif echo "$headers" | grep -q "Access-Control-Allow-Origin: $domain"; then
      echo "❌ FAIL: $endpoint allows evil domain $domain"
      ((FAIL++))
    else
      echo "✅ PASS: $endpoint blocks unauthorized origin $domain"
      ((PASS++))
    fi
  done
done

echo ""
echo "CORS Test Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

**Expected Results:**
- ✅ All evil domains should be blocked or return no CORS header
- ✅ No wildcard CORS (`*`) in any response
- ✅ Status: 100% PASS rate

### Test 1.2: Authorized Domain Whitelisting

**Objective:** Verify that authorized domains receive correct CORS headers.

**Test Cases:**

```bash
# Test: Authorized domain (medzenhealth.app) should be allowed
curl -X OPTIONS \
  -H "Origin: https://medzenhealth.app" \
  -v \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token

# Expected: HTTP 200
# Header: Access-Control-Allow-Origin: https://medzenhealth.app
# Headers: Content-Security-Policy, Strict-Transport-Security, etc.
```

**Test Script:**

```bash
#!/bin/bash
set -e

ALLOWED_ORIGINS=(
  "https://medzenhealth.app"
  "https://www.medzenhealth.app"
)

ENDPOINTS=(
  "chime-meeting-token"
  "generate-soap-draft-v2"
  "bedrock-ai-chat"
  "create-context-snapshot"
)

REQUIRED_HEADERS=(
  "Access-Control-Allow-Origin"
  "Content-Security-Policy"
  "Strict-Transport-Security"
  "X-Content-Type-Options"
  "X-Frame-Options"
)

PASS=0
FAIL=0

for endpoint in "${ENDPOINTS[@]}"; do
  for origin in "${ALLOWED_ORIGINS[@]}"; do
    response=$(curl -s -w "\n%{http_code}" -i \
      -X OPTIONS \
      -H "Origin: $origin" \
      https://noaeltglphdlkbflipit.supabase.co/functions/v1/$endpoint)

    status_code=$(echo "$response" | tail -1)
    headers=$(echo "$response" | sed '$d')

    if [ "$status_code" != "200" ]; then
      echo "❌ FAIL: $endpoint OPTIONS returns $status_code for $origin"
      ((FAIL++))
      continue
    fi

    # Check all required headers present
    for header in "${REQUIRED_HEADERS[@]}"; do
      if echo "$headers" | grep -q "^$header:"; then
        echo "✅ PASS: $endpoint has $header"
        ((PASS++))
      else
        echo "❌ FAIL: $endpoint missing $header"
        ((FAIL++))
      fi
    done

    # Verify origin matches
    if echo "$headers" | grep -q "Access-Control-Allow-Origin: $origin"; then
      echo "✅ PASS: $endpoint allows $origin"
      ((PASS++))
    else
      echo "❌ FAIL: $endpoint doesn't allow $origin"
      ((FAIL++))
    fi
  done
done

echo ""
echo "Whitelist Test Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

**Expected Results:**
- ✅ All authorized origins receive CORS headers
- ✅ All security headers present in every response
- ✅ HTTP 200 response for OPTIONS requests
- ✅ Status: 100% PASS rate

---

## SECTION 2: RATE LIMITING TESTING

### Test 2.1: Per-Endpoint Rate Limit Enforcement

**Objective:** Verify rate limiting prevents abuse of endpoints.

**Endpoints & Limits:**

```yaml
chime-meeting-token: 10 requests/minute per user
generate-soap-draft-v2: 20 requests/minute per user
bedrock-ai-chat: 30 requests/minute per user
upload-profile-picture: 5 requests/minute per user
start-medical-transcription: 5 requests/minute per user
sync-to-ehrbase: 10 requests/minute per user
storage-sign-url: 20 requests/minute per user
default: 100 requests/minute per user
```

**Test Script:**

```bash
#!/bin/bash
set -e

# Test: Trigger rate limit
ENDPOINT="chime-meeting-token"
MAX_REQUESTS=10
TOKEN="$VALID_FIREBASE_TOKEN"
PASS=0
FAIL=0

echo "Testing $ENDPOINT rate limit (max: $MAX_REQUESTS/min)..."

for i in {1..15}; do
  response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "x-firebase-token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"test":"data"}' \
    https://noaeltglphdlkbflipit.supabase.co/functions/v1/$ENDPOINT)

  status_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  if [ $i -le $MAX_REQUESTS ]; then
    # Should succeed (200 or 400 for invalid input, NOT 429)
    if [[ "$status_code" != "429" ]]; then
      echo "✅ PASS: Request $i returned HTTP $status_code (allowed)"
      ((PASS++))
    else
      echo "❌ FAIL: Request $i hit rate limit too early (status 429)"
      ((FAIL++))
    fi
  else
    # Should be rate limited (429)
    if [ "$status_code" = "429" ]; then
      echo "✅ PASS: Request $i returned HTTP 429 (rate limited as expected)"
      ((PASS++))

      # Check Retry-After header
      if echo "$body" | grep -q '"retry_after"'; then
        echo "  ✅ Includes Retry-After header"
        ((PASS++))
      fi
    else
      echo "❌ FAIL: Request $i should return 429 but got $status_code"
      ((FAIL++))
    fi
  fi

  sleep 0.1  # Small delay between requests
done

echo ""
echo "Rate Limit Test Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

**Expected Results:**
- ✅ First 10 requests to chime-meeting-token: HTTP 200/400 (success or invalid input)
- ✅ Requests 11-15: HTTP 429 (Too Many Requests)
- ✅ Response includes `Retry-After` header
- ✅ Status: 100% PASS rate for all endpoints

### Test 2.2: Per-User Rate Limit Isolation

**Objective:** Verify that different users have separate rate limit counters.

**Test Script:**

```bash
#!/bin/bash
set -e

# Simulate 2 different users
USER1_TOKEN="$TOKEN_USER_1"
USER2_TOKEN="$TOKEN_USER_2"
ENDPOINT="chime-meeting-token"

PASS=0
FAIL=0

echo "Testing per-user rate limit isolation..."

# User 1: Send 10 requests
for i in {1..10}; do
  response=$(curl -s -w "%{http_code}" \
    -H "x-firebase-token: $USER1_TOKEN" \
    https://noaeltglphdlkbflipit.supabase.co/functions/v1/$ENDPOINT)
  [ "$response" != "429" ] && ((PASS++)) || ((FAIL++))
done

# User 2: Should still be able to send requests (different rate limit counter)
for i in {1..10}; do
  response=$(curl -s -w "%{http_code}" \
    -H "x-firebase-token: $USER2_TOKEN" \
    https://noaeltglphdlkbflipit.supabase.co/functions/v1/$ENDPOINT)

  if [ "$response" != "429" ]; then
    echo "✅ PASS: User 2 request $i succeeded (not rate limited by User 1)"
    ((PASS++))
  else
    echo "❌ FAIL: User 2 request $i rate limited even though different user"
    ((FAIL++))
  fi
done

echo ""
echo "Per-User Rate Limit Results: $PASS passed, $FAIL failed"
```

**Expected Results:**
- ✅ User 1 successfully makes 10 requests
- ✅ User 2 successfully makes 10 requests in parallel
- ✅ Users have separate rate limit counters
- ✅ No cross-user rate limiting

---

## SECTION 3: INPUT VALIDATION TESTING

### Test 3.1: XSS Prevention

**Objective:** Verify input sanitization prevents Cross-Site Scripting attacks.

**Test Cases:**

```javascript
// XSS Payloads to test
const xssPayloads = [
  "<script>alert('XSS')</script>",
  "javascript:alert('XSS')",
  "<img src=x onerror='alert(1)'>",
  "<svg onload=alert('XSS')>",
  "on error='javascript:alert(1)'",
  "<iframe src='javascript:alert(1)'></iframe>",
];

// Test endpoint: bedrock-ai-chat
for (const payload of xssPayloads) {
  const response = await fetch(
    'https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat',
    {
      method: 'POST',
      headers: {
        'x-firebase-token': validToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: payload,
        conversationId: 'test-123',
      }),
    }
  );

  const data = await response.json();

  // Payload should NOT appear in response with HTML entities intact
  if (data.message && !data.message.includes('<script>')) {
    console.log('✅ PASS: XSS payload sanitized');
  } else {
    console.log('❌ FAIL: XSS payload not sanitized');
  }
}
```

**Expected Results:**
- ✅ All XSS payloads are sanitized
- ✅ No `<script>`, `javascript:`, `onerror`, etc. in processed output
- ✅ HTML entities properly escaped
- ✅ Legitimate content preserved

### Test 3.2: SQL Injection Prevention

**Objective:** Verify parameterized queries prevent SQL injection.

**Test Cases:**

```javascript
const sqlPayloads = [
  "'; DROP TABLE users; --",
  "1 OR 1=1",
  "1; DELETE FROM appointments; --",
  "' UNION SELECT * FROM passwords --",
];

for (const payload of sqlPayloads) {
  const response = await fetch(
    'https://noaeltglphdlkbflipit.supabase.co/functions/v1/create-context-snapshot',
    {
      method: 'POST',
      headers: {
        'x-firebase-token': validToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        encounter_id: payload,
        appointment_id: '550e8400-e29b-41d4-a716-446655440000',
      }),
    }
  );

  // Should return 400 (invalid UUID format), not execute SQL
  if (response.status === 400) {
    console.log('✅ PASS: SQL injection prevented (invalid UUID rejected)');
  } else if (response.status === 500) {
    console.log('❌ FAIL: SQL error (possible injection vulnerability)');
  }
}
```

**Expected Results:**
- ✅ All SQL payloads rejected with 400 (validation error)
- ✅ No 500 errors (no SQL execution)
- ✅ No data exfiltration
- ✅ Database integrity maintained

### Test 3.3: UUID Format Validation

**Objective:** Verify UUIDs are validated before use.

**Test Cases:**

```javascript
const invalidUUIDs = [
  'not-a-uuid',
  '123',
  'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',  // Wrong characters
  '550e8400-e29b-41d4-a716',  // Incomplete
  '',  // Empty
];

for (const uuid of invalidUUIDs) {
  const response = await fetch(
    'https://noaeltglphdlkbflipit.supabase.co/functions/v1/generate-soap-draft-v2',
    {
      method: 'POST',
      headers: {
        'x-firebase-token': validToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        encounter_id: uuid,
        appointment_id: 'valid-uuid-here',
      }),
    }
  );

  if (response.status === 400) {
    const data = await response.json();
    if (data.error.includes('Invalid') || data.error.includes('UUID')) {
      console.log(`✅ PASS: Invalid UUID "${uuid}" properly rejected`);
    }
  } else {
    console.log(`❌ FAIL: Invalid UUID "${uuid}" not rejected (status ${response.status})`);
  }
}
```

**Expected Results:**
- ✅ All invalid UUIDs rejected with HTTP 400
- ✅ Error message indicates UUID validation failure
- ✅ Valid UUIDs (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`) accepted

---

## SECTION 4: ENCRYPTION VERIFICATION

### Test 4.1: S3 Bucket Encryption

**Objective:** Verify all S3 buckets have KMS encryption enabled.

**Test Script:**

```bash
#!/bin/bash
set -e

BUCKETS=(
  "medzen-meeting-recordings-558069890522"
  "medzen-meeting-transcripts-558069890522"
  "medzen-medical-data-558069890522"
)

PASS=0
FAIL=0

for bucket in "${BUCKETS[@]}"; do
  echo "Checking encryption for $bucket..."

  encryption=$(aws s3api get-bucket-encryption \
    --bucket $bucket \
    --region eu-central-1 2>/dev/null || echo "")

  if echo "$encryption" | grep -q "aws:kms\|AES256"; then
    echo "✅ PASS: $bucket has encryption enabled"
    ((PASS++))
  else
    echo "❌ FAIL: $bucket has no encryption"
    ((FAIL++))
  fi

  # Verify no unencrypted uploads allowed
  acl=$(aws s3api get-bucket-acl --bucket $bucket --region eu-central-1)
  if echo "$acl" | grep -q "PublicRead\|PublicWrite"; then
    echo "❌ FAIL: $bucket has public ACL"
    ((FAIL++))
  else
    echo "✅ PASS: $bucket has restricted ACL"
    ((PASS++))
  fi
done

echo ""
echo "S3 Encryption Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

**Expected Results:**
- ✅ All 3 buckets have encryption enabled (KMS or AES256)
- ✅ No public ACLs
- ✅ Versioning enabled
- ✅ Block Public Access enabled

### Test 4.2: RDS Encryption

**Objective:** Verify RDS database has encryption enabled.

**Test Script:**

```bash
#!/bin/bash

DB_IDENTIFIER="medzen-db"
REGION="eu-west-1"

echo "Checking RDS encryption..."

# Check encryption status
db_info=$(aws rds describe-db-instances \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $REGION)

if echo "$db_info" | grep -q '"StorageEncrypted": true'; then
  echo "✅ PASS: RDS has encryption enabled"
else
  echo "❌ FAIL: RDS encryption not enabled"
fi

# Check KMS key
kms_key=$(echo "$db_info" | grep -o '"KmsKeyId": "[^"]*"' || echo "")
if [ -n "$kms_key" ]; then
  echo "✅ PASS: RDS uses KMS key: $kms_key"
else
  echo "❌ FAIL: RDS not using KMS key"
fi

# Check Multi-AZ
if echo "$db_info" | grep -q '"MultiAZ": true'; then
  echo "✅ PASS: RDS Multi-AZ enabled"
else
  echo "⚠️  WARNING: RDS Multi-AZ not enabled"
fi
```

**Expected Results:**
- ✅ RDS encryption enabled with KMS
- ✅ Multi-AZ enabled for high availability
- ✅ Automated backups enabled (7-day retention)

---

## SECTION 5: AUDIT LOGGING VERIFICATION

### Test 5.1: PHI Access Logging

**Objective:** Verify all PHI access is logged with user identity.

**Test Script:**

```sql
-- Query: Check recent PHI access logs
SELECT
  id,
  user_id,
  action,
  resource_type,
  resource_id,
  ip_address,
  timestamp,
  details
FROM activity_logs
WHERE
  resource_type IN ('patient_profiles', 'clinical_notes', 'video_call_sessions')
  AND timestamp > NOW() - INTERVAL '1 hour'
ORDER BY timestamp DESC
LIMIT 20;

-- Verify each log entry has:
-- ✅ user_id (Firebase UID)
-- ✅ action (read/write/delete)
-- ✅ timestamp (UTC)
-- ✅ ip_address (client IP)
-- ✅ resource_id (UUID of accessed resource)
```

**Expected Results:**
- ✅ All PHI accesses logged
- ✅ User identity recorded
- ✅ Timestamp in UTC
- ✅ IP addresses captured
- ✅ 6-year retention policy enforced

### Test 5.2: CloudTrail Logging

**Objective:** Verify AWS API calls are logged via CloudTrail.

**Test Script:**

```bash
#!/bin/bash

TRAIL_NAME="medzen-audit-trail"
REGION="eu-central-1"

echo "Checking CloudTrail status..."

# Check if trail is logging
trail_status=$(aws cloudtrail get-trail-status \
  --name $TRAIL_NAME \
  --region $REGION)

if echo "$trail_status" | grep -q '"IsLogging": true'; then
  echo "✅ PASS: CloudTrail is actively logging"
else
  echo "❌ FAIL: CloudTrail is not logging"
fi

# Check recent events
recent_events=$(aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=$TRAIL_NAME \
  --max-results 10)

if [ -n "$recent_events" ]; then
  echo "✅ PASS: CloudTrail has recent events"
else
  echo "⚠️  WARNING: No recent CloudTrail events found"
fi
```

**Expected Results:**
- ✅ CloudTrail actively logging
- ✅ All API calls recorded
- ✅ S3 bucket receiving logs
- ✅ Log file validation enabled

---

## SECTION 6: SUMMARY & SIGN-OFF

### Test Execution Checklist

```markdown
## CORS Security Tests
- [ ] Test 1.1: Unauthorized domain blocking
- [ ] Test 1.2: Authorized domain whitelisting
- [ ] Result: 100% PASS rate

## Rate Limiting Tests
- [ ] Test 2.1: Per-endpoint rate limit enforcement
- [ ] Test 2.2: Per-user rate limit isolation
- [ ] Result: 100% PASS rate

## Input Validation Tests
- [ ] Test 3.1: XSS prevention
- [ ] Test 3.2: SQL injection prevention
- [ ] Test 3.3: UUID format validation
- [ ] Result: 100% PASS rate

## Encryption Tests
- [ ] Test 4.1: S3 bucket encryption
- [ ] Test 4.2: RDS encryption
- [ ] Result: All buckets encrypted, KMS keys verified

## Audit Logging Tests
- [ ] Test 5.1: PHI access logging
- [ ] Test 5.2: CloudTrail logging
- [ ] Result: All access logged and retained

## Security Sign-Off
- [ ] All 59 edge functions tested
- [ ] 0% wildcard CORS (down from 71%)
- [ ] 100% rate limiting enforcement
- [ ] 100% input validation on critical functions
- [ ] All encryption verified
- [ ] Audit logging operational
- [ ] **APPROVED FOR PRODUCTION DEPLOYMENT**
```

### Success Metrics

| Metric | Target | Status |
|--------|--------|--------|
| Wildcard CORS functions | 0% (down from 71%) | ⏳ In Progress |
| Rate limiting coverage | 100% of 59 functions | ⏳ In Progress |
| Input validation coverage | 100% of 20+ critical functions | ⏳ In Progress |
| Security headers present | 100% of responses | ⏳ In Progress |
| CORS test pass rate | 100% | ⏳ Pending |
| Rate limiting test pass rate | 100% | ⏳ Pending |
| Input validation test pass rate | 100% | ⏳ Pending |
| Encryption verification | All buckets + RDS | ⏳ Pending AWS Creds |
| Audit logging verification | PHI + CloudTrail | ⏳ Pending |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-23 | Claude Code | Initial comprehensive testing procedures |

**Approval Required:** Security Team Lead, CTO

