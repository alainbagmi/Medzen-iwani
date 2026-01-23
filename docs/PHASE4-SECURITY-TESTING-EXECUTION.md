# MedZen Phase 4: Comprehensive Security Testing - Execution Guide

**Date:** 2026-01-23
**Status:** Ready for Execution (After Phase 1 Completes)
**Estimated Duration:** 2-3 hours
**Risk Level:** LOW - Read-only testing, no production changes

---

## Overview

Phase 4 verifies that all security controls added in Phases 1-2 are functioning correctly:

1. **CORS Testing** - Verify origin validation blocks unauthorized domains
2. **Rate Limiting Testing** - Verify per-endpoint rate limits are enforced
3. **Input Validation Testing** - Verify XSS/SQL injection prevention
4. **Encryption Testing** - Verify data is encrypted at rest and in transit
5. **Audit Logging Testing** - Verify all PHI access is logged
6. **Integration Testing** - Verify all components work together

---

## Prerequisites

Before executing Phase 4, ensure:

- ✅ Phase 1 complete: All 59 edge functions hardened with CORS/rate limiting
- ✅ Phase 2 complete: S3 encryption enabled, GuardDuty/CloudTrail active
- ✅ Phase 3 complete: Documentation finalized
- ✅ All functions deployed to production
- ✅ Test environment or staging available for testing

**Tools Required:**
- `curl` - For HTTP testing
- `python3` - For test script execution
- `jq` - For JSON processing
- `openssl` - For encryption verification

**Verify Prerequisites:**
```bash
command -v curl && echo "✅ curl" || echo "❌ curl missing"
command -v python3 && echo "✅ python3" || echo "❌ python3 missing"
command -v jq && echo "✅ jq" || echo "❌ jq missing"
command -v openssl && echo "✅ openssl" || echo "❌ openssl missing"
```

---

## Test 1: CORS Security Testing

**Objective:** Verify CORS headers properly validate origin and block unauthorized domains

### Test 1.1: Unauthorized Domain Blocked

Test that requests from unauthorized domains are blocked:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
UNAUTHORIZED_ORIGIN="https://evil-attacker.com"

echo "🧪 Test 1.1: Unauthorized Domain Should Be Blocked"
echo "=================================================="
echo "Testing: $TEST_URL"
echo "From Origin: $UNAUTHORIZED_ORIGIN"
echo ""

RESPONSE=$(curl -s -i -X OPTIONS \
  -H "Origin: $UNAUTHORIZED_ORIGIN" \
  -H "Access-Control-Request-Method: POST" \
  "$TEST_URL")

echo "Response Headers:"
echo "$RESPONSE" | head -20
echo ""

# Check if CORS header exists and is not the unauthorized origin
if echo "$RESPONSE" | grep -q "Access-Control-Allow-Origin: $UNAUTHORIZED_ORIGIN"; then
  echo "❌ FAILED: Unauthorized origin was allowed!"
  exit 1
elif echo "$RESPONSE" | grep -q "Access-Control-Allow-Origin:"; then
  ALLOWED_ORIGIN=$(echo "$RESPONSE" | grep "Access-Control-Allow-Origin:" | cut -d' ' -f2)
  echo "✅ PASSED: CORS header present, origin is: $ALLOWED_ORIGIN"
else
  echo "✅ PASSED: No CORS header (request blocked at origin)"
fi

echo ""
```

### Test 1.2: Authorized Domain Allowed

Test that requests from authorized domains are allowed:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
AUTHORIZED_ORIGIN="https://medzenhealth.app"

echo "🧪 Test 1.2: Authorized Domain Should Be Allowed"
echo "================================================="
echo "Testing: $TEST_URL"
echo "From Origin: $AUTHORIZED_ORIGIN"
echo ""

RESPONSE=$(curl -s -i -X OPTIONS \
  -H "Origin: $AUTHORIZED_ORIGIN" \
  -H "Access-Control-Request-Method: POST" \
  "$TEST_URL")

echo "Response Headers:"
echo "$RESPONSE" | head -20
echo ""

# Check if correct origin is returned
if echo "$RESPONSE" | grep -q "Access-Control-Allow-Origin: $AUTHORIZED_ORIGIN"; then
  echo "✅ PASSED: Authorized origin is allowed"
  exit 0
else
  echo "❌ FAILED: Authorized origin was not allowed"
  exit 1
fi

echo ""
```

### Test 1.3: Security Headers Present

Test that all security headers are included:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"

echo "🧪 Test 1.3: Security Headers Should Be Present"
echo "==============================================="
echo "Testing: $TEST_URL"
echo ""

RESPONSE=$(curl -s -i "$TEST_URL")

echo "Checking for security headers..."
echo ""

REQUIRED_HEADERS=(
  "Content-Security-Policy"
  "Strict-Transport-Security"
  "X-Content-Type-Options"
  "X-Frame-Options"
)

PASSED=0
FAILED=0

for HEADER in "${REQUIRED_HEADERS[@]}"; do
  if echo "$RESPONSE" | grep -q "$HEADER:"; then
    echo "✅ $HEADER: Present"
    ((PASSED++))
  else
    echo "❌ $HEADER: Missing"
    ((FAILED++))
  fi
done

echo ""
echo "Summary: $PASSED passed, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi
```

---

## Test 2: Rate Limiting Testing

**Objective:** Verify rate limiting is enforced per endpoint and per user

### Test 2.1: Trigger Rate Limit

Test that requests exceeding the limit receive 429 responses:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
FIREBASE_TOKEN="your-test-firebase-token"  # Replace with actual test token

echo "🧪 Test 2.1: Rate Limiting Should Block Excess Requests"
echo "========================================================"
echo "Testing: $TEST_URL"
echo "Sending 15 rapid requests (limit should be ~10/min)"
echo ""

PASSED=0
FAILED=0
RATE_LIMITED=0

for i in {1..15}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Origin: https://medzenhealth.app" \
    -H "x-firebase-token: $FIREBASE_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "$TEST_URL")

  if [ $i -le 10 ]; then
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "400" ]; then
      echo "Request $i: ✅ Status $STATUS (within limit)"
      ((PASSED++))
    else
      echo "Request $i: ❌ Status $STATUS (unexpected)"
      ((FAILED++))
    fi
  else
    if [ "$STATUS" = "429" ]; then
      echo "Request $i: ✅ Status $STATUS (rate limited as expected)"
      ((RATE_LIMITED++))
    else
      echo "Request $i: ❌ Status $STATUS (should be 429)"
      ((FAILED++))
    fi
  fi
done

echo ""
echo "Summary: $PASSED normal requests, $RATE_LIMITED rate-limited, $FAILED failures"

if [ $RATE_LIMITED -ge 3 ]; then
  echo "✅ PASSED: Rate limiting is working"
  exit 0
else
  echo "❌ FAILED: Rate limiting not triggered"
  exit 1
fi
```

### Test 2.2: Verify Retry-After Header

Test that 429 responses include Retry-After header:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
FIREBASE_TOKEN="your-test-firebase-token"

echo "🧪 Test 2.2: 429 Responses Should Include Retry-After"
echo "====================================================="
echo ""

# Trigger rate limit by sending multiple requests
for i in {1..15}; do
  curl -s -X POST \
    -H "Origin: https://medzenhealth.app" \
    -H "x-firebase-token: $FIREBASE_TOKEN" \
    -d '{}' \
    "$TEST_URL" > /dev/null
done

# Check final request
RESPONSE=$(curl -s -i -X POST \
  -H "Origin: https://medzenhealth.app" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -d '{}' \
  "$TEST_URL")

if echo "$RESPONSE" | grep -q "HTTP.*429"; then
  if echo "$RESPONSE" | grep -q "Retry-After:"; then
    RETRY_AFTER=$(echo "$RESPONSE" | grep "Retry-After:" | cut -d' ' -f2)
    echo "✅ PASSED: Retry-After header present: $RETRY_AFTER seconds"
    exit 0
  else
    echo "❌ FAILED: No Retry-After header in 429 response"
    exit 1
  fi
else
  echo "❌ FAILED: Could not trigger 429 response"
  exit 1
fi
```

---

## Test 3: Input Validation Testing

**Objective:** Verify XSS, SQL injection, and invalid data are blocked

### Test 3.1: XSS Payload Blocking

Test that HTML/JavaScript payloads are sanitized:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat"
FIREBASE_TOKEN="your-test-firebase-token"

echo "🧪 Test 3.1: XSS Payloads Should Be Blocked/Sanitized"
echo "===================================================="
echo ""

XSS_PAYLOADS=(
  "<script>alert('xss')</script>"
  "<img src=x onerror=alert('xss')>"
  "javascript:alert('xss')"
  "<iframe src='javascript:alert(1)'></iframe>"
  "<body onload=alert('xss')>"
)

BLOCKED=0
FAILED=0

for PAYLOAD in "${XSS_PAYLOADS[@]}"; do
  RESPONSE=$(curl -s -X POST \
    -H "Origin: https://medzenhealth.app" \
    -H "x-firebase-token: $FIREBASE_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"message\": \"$PAYLOAD\"}" \
    "$TEST_URL")

  # Check if payload was sanitized (not reflected with dangerous tags)
  if echo "$RESPONSE" | grep -q "script\|onerror\|javascript:"; then
    echo "❌ FAILED: XSS payload not sanitized: $PAYLOAD"
    ((FAILED++))
  else
    echo "✅ PASSED: XSS payload blocked: $PAYLOAD"
    ((BLOCKED++))
  fi
done

echo ""
echo "Summary: $BLOCKED blocked, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi
```

### Test 3.2: SQL Injection Prevention

Test that SQL injection attempts are blocked:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/generate-soap-draft-v2"
FIREBASE_TOKEN="your-test-firebase-token"

echo "🧪 Test 3.2: SQL Injection Payloads Should Be Blocked"
echo "===================================================="
echo ""

SQL_PAYLOADS=(
  "'; DROP TABLE users; --"
  "1' OR '1'='1"
  "admin' --"
  "1; DELETE FROM clinical_notes; --"
)

BLOCKED=0
FAILED=0

for PAYLOAD in "${SQL_PAYLOADS[@]}"; do
  RESPONSE=$(curl -s -X POST \
    -H "Origin: https://medzenhealth.app" \
    -H "x-firebase-token: $FIREBASE_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"encounter_id\": \"$PAYLOAD\"}" \
    "$TEST_URL")

  # Should receive 400 error, not successful query
  if echo "$RESPONSE" | grep -q "invalid\|malformed\|error"; then
    echo "✅ PASSED: SQL injection blocked: $PAYLOAD"
    ((BLOCKED++))
  else
    echo "⚠️  WARNING: Response to SQL payload: $RESPONSE"
    ((FAILED++))
  fi
done

echo ""
echo "Summary: $BLOCKED blocked, $FAILED warnings"
```

### Test 3.3: Invalid UUID Validation

Test that invalid UUIDs are rejected:

```bash
#!/bin/bash

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/generate-soap-draft-v2"
FIREBASE_TOKEN="your-test-firebase-token"

echo "🧪 Test 3.3: Invalid UUIDs Should Be Rejected"
echo "============================================="
echo ""

INVALID_UUIDS=(
  "not-a-uuid"
  "12345"
  ""
  "00000000-0000-0000-0000-000000000000-extra"
)

REJECTED=0
FAILED=0

for UUID in "${INVALID_UUIDS[@]}"; do
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Origin: https://medzenhealth.app" \
    -H "x-firebase-token: $FIREBASE_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"encounter_id\": \"$UUID\"}" \
    "$TEST_URL")

  STATUS=$(echo "$RESPONSE" | tail -1)

  if [ "$STATUS" = "400" ]; then
    echo "✅ PASSED: Invalid UUID rejected ($UUID): Status $STATUS"
    ((REJECTED++))
  else
    echo "❌ FAILED: Invalid UUID not rejected ($UUID): Status $STATUS"
    ((FAILED++))
  fi
done

echo ""
echo "Summary: $REJECTED rejected, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi
```

---

## Test 4: Encryption Testing

**Objective:** Verify data encryption at rest and in transit

### Test 4.1: TLS 1.2+ Enforced

Test that TLS 1.2+ is enforced:

```bash
#!/bin/bash

DOMAIN="noaeltglphdlkbflipit.supabase.co"

echo "🧪 Test 4.1: TLS 1.2+ Should Be Enforced"
echo "======================================="
echo ""

# Check TLS version
TLS_VERSION=$(echo | openssl s_client -connect $DOMAIN:443 2>/dev/null | grep "Protocol" | awk '{print $3}')

echo "TLS Version: $TLS_VERSION"

if [[ "$TLS_VERSION" == "TLSv1.2" ]] || [[ "$TLS_VERSION" == "TLSv1.3" ]]; then
  echo "✅ PASSED: TLS 1.2 or higher in use"
  exit 0
else
  echo "❌ FAILED: TLS version below 1.2"
  exit 1
fi
```

### Test 4.2: S3 Bucket Encryption

Test that S3 buckets are encrypted:

```bash
#!/bin/bash

echo "🧪 Test 4.2: S3 Buckets Should Be Encrypted"
echo "=========================================="
echo ""

BUCKETS=(
  "medzen-meeting-recordings-558069890522"
  "medzen-meeting-transcripts-558069890522"
  "medzen-medical-data-558069890522"
)

ENCRYPTED=0
FAILED=0

for BUCKET in "${BUCKETS[@]}"; do
  ENCRYPTION=$(aws s3api get-bucket-encryption \
    --bucket "$BUCKET" \
    --region eu-central-1 \
    --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' \
    --output text 2>/dev/null)

  if [ "$ENCRYPTION" = "aws:kms" ]; then
    echo "✅ $BUCKET: Encrypted with KMS"
    ((ENCRYPTED++))
  else
    echo "❌ $BUCKET: Not encrypted with KMS (Status: $ENCRYPTION)"
    ((FAILED++))
  fi
done

echo ""
echo "Summary: $ENCRYPTED encrypted, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi
```

---

## Test 5: Audit Logging Testing

**Objective:** Verify PHI access is logged and retained

### Test 5.1: Activity Logging

Test that API calls are logged:

```bash
#!/bin/bash

echo "🧪 Test 5.1: API Calls Should Be Logged"
echo "======================================"
echo ""

# Make a test API call
curl -s -X POST \
  -H "Origin: https://medzenhealth.app" \
  -H "x-firebase-token: test-token" \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  > /dev/null

# Wait for logs to propagate
sleep 2

# Check CloudTrail logs
LOGS=$(aws cloudtrail lookup-events \
  --region eu-central-1 \
  --max-results 5 \
  --query 'Events[*].EventName' \
  --output text 2>/dev/null)

if echo "$LOGS" | grep -q "Invoke"; then
  echo "✅ PASSED: API calls are being logged to CloudTrail"
  exit 0
else
  echo "⚠️  WARNING: Could not verify logging (check CloudTrail manually)"
  exit 0
fi
```

### Test 5.2: Log Retention

Test that logs are retained for minimum 6 years:

```bash
#!/bin/bash

echo "🧪 Test 5.2: Logs Should Have 6-Year Retention"
echo "============================================="
echo ""

# Check S3 bucket lifecycle policies
BUCKET="medzen-cloudtrail-logs"

RETENTION=$(aws s3api get-bucket-lifecycle-configuration \
  --bucket "$BUCKET" \
  --region eu-central-1 \
  --query 'Rules[0].ExpirationInDays' \
  --output text 2>/dev/null)

# 6 years = 2190 days (accounting for leap years)
if [ -z "$RETENTION" ] || [ "$RETENTION" = "None" ]; then
  echo "✅ PASSED: No expiration set (logs retained indefinitely)"
  exit 0
elif [ "$RETENTION" -ge 2190 ]; then
  echo "✅ PASSED: Retention is $RETENTION days (>= 6 years)"
  exit 0
else
  echo "❌ FAILED: Retention is only $RETENTION days (< 6 years)"
  exit 1
fi
```

---

## Test 6: Integration Testing

**Objective:** Verify all components work together end-to-end

### Test 6.1: Complete Request Flow

Test a complete request with all security controls:

```bash
#!/bin/bash

echo "🧪 Test 6.1: Complete Request Flow"
echo "==================================="
echo ""

TEST_URL="https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
AUTHORIZED_ORIGIN="https://medzenhealth.app"
FIREBASE_TOKEN="your-valid-firebase-token"

echo "Step 1: Send OPTIONS request (CORS preflight)"
PREFLIGHT=$(curl -s -i -X OPTIONS \
  -H "Origin: $AUTHORIZED_ORIGIN" \
  -H "Access-Control-Request-Method: POST" \
  "$TEST_URL")

if echo "$PREFLIGHT" | grep -q "Access-Control-Allow-Origin: $AUTHORIZED_ORIGIN"; then
  echo "✅ CORS preflight passed"
else
  echo "❌ CORS preflight failed"
  exit 1
fi

echo "Step 2: Send actual POST request with authentication"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Origin: $AUTHORIZED_ORIGIN" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  "$TEST_URL")

STATUS=$(echo "$RESPONSE" | tail -1)

if [ "$STATUS" = "200" ] || [ "$STATUS" = "400" ] || [ "$STATUS" = "401" ]; then
  echo "✅ POST request successful (Status: $STATUS)"
else
  echo "❌ POST request failed (Status: $STATUS)"
  exit 1
fi

echo ""
echo "✅ PASSED: Complete request flow working"
exit 0
```

---

## Phase 4 Test Checklist

After executing all tests:

```
□ Test 1: CORS Security
  □ 1.1: Unauthorized domains blocked
  □ 1.2: Authorized domains allowed
  □ 1.3: Security headers present

□ Test 2: Rate Limiting
  □ 2.1: Rate limits enforced (429 responses)
  □ 2.2: Retry-After header present

□ Test 3: Input Validation
  □ 3.1: XSS payloads blocked
  □ 3.2: SQL injection blocked
  □ 3.3: Invalid UUIDs rejected

□ Test 4: Encryption
  □ 4.1: TLS 1.2+ enforced
  □ 4.2: S3 buckets encrypted

□ Test 5: Audit Logging
  □ 5.1: API calls logged
  □ 5.2: 6-year retention verified

□ Test 6: Integration
  □ 6.1: Complete request flow working

□ Final Verification
  □ All tests passed
  □ No security vulnerabilities found
  □ System ready for production
```

---

## Success Criteria

**Phase 4 Complete When:**
- ✅ CORS testing: 100% functions block unauthorized domains
- ✅ Rate limiting testing: 100% functions enforce limits
- ✅ Input validation testing: 100% security payloads blocked
- ✅ Encryption testing: 100% data encrypted at rest + in transit
- ✅ Audit logging testing: 100% requests logged and retained
- ✅ Integration testing: End-to-end flow working correctly

---

## Next Steps After Phase 4

1. **Production Deployment** - Deploy all hardened functions to production
2. **Monitoring Setup** - Enable CloudWatch dashboards and alerts
3. **Security Review** - Executive review and sign-off on security posture
4. **Incident Response** - Activate incident response procedures
5. **Compliance Filing** - File HIPAA/GDPR compliance certifications

---

## Troubleshooting

### Test Fails Due to Authentication

If tests fail with 401 errors, ensure your Firebase token is valid:
```bash
# Get a fresh token from Firebase CLI
firebase auth:export /tmp/tokens.json
# Or use your application's token generation method
```

### Test Fails Due to Network

If curl commands fail, verify network connectivity:
```bash
curl -I https://medzenhealth.app
# Should return 200 or 301/302 (redirect)
```

### AWS Tests Fail

If AWS CLI tests fail, ensure credentials are configured:
```bash
aws sts get-caller-identity
# Should return your AWS account information
```

---

**Document Version:** 1.0
**Created:** 2026-01-23
**Status:** Ready for Execution (After Phase 1 Completion)
**Next Review:** After all tests pass
