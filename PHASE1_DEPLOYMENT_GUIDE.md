# Phase 1 Security Enhancements - Deployment Guide

**Created:** December 16, 2025
**Status:** Ready for Deployment
**Estimated Time:** 2-3 hours (including testing)

---

## 🚨 Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] AWS CLI configured with admin access to eu-central-1
- [ ] Supabase CLI installed and linked to project
- [ ] Firebase Admin SDK credentials
- [ ] Backup of current CloudFormation stacks
- [ ] Access to production Supabase database
- [ ] Monitoring dashboard open (CloudWatch)
- [ ] Team notified of deployment window

### Required Access

```bash
# Verify AWS access
aws sts get-caller-identity --region eu-central-1

# Verify Supabase access
npx supabase status

# Check Firebase project
firebase projects:list | grep medzen-bf20e
```

---

## 📦 Phase 1 Components

### Files Created

1. **`aws-deployment/cloudformation/chime-sdk-security-patch.yaml`**
   - AWS WAF with DDoS protection
   - Geographic restriction (EU only)
   - API Gateway throttling configuration
   - Lambda improvements (timeouts, DLQ)
   - CloudWatch alarms and dashboard

2. **`supabase/functions/chime-meeting-token-security-patch.ts`**
   - Appointment-level authorization
   - Timing validation
   - Meeting session validation
   - HMAC signature verification (optional)
   - HIPAA audit logging

3. **`supabase/migrations/20251217000000_add_security_enhancements.sql`**
   - Meeting quotas table (10/day, 100/month limits)
   - Video call audit log (HIPAA-compliant)
   - Security events tracking
   - RLS policies
   - Helper functions for Edge Functions

---

## 🚀 Deployment Steps

### Step 1: Database Migration (15 minutes)

**Priority:** Execute FIRST (Edge Functions depend on these tables)

```bash
# Navigate to project root
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Link to Supabase project (if not already linked)
npx supabase link --project-ref noaeltglphdlkbflipit

# Review migration before applying
cat supabase/migrations/20251217000000_add_security_enhancements.sql

# Apply migration
npx supabase db push

# Verify migration succeeded
npx supabase db remote status
```

**Expected Output:**
```
✅ Applied migrations:
  - 20251217000000_add_security_enhancements

Tables created:
  - meeting_quotas (with 3 RLS policies)
  - video_call_audit_log (with 5 RLS policies)
  - security_events (with 2 RLS policies)
```

**Rollback if needed:**
```sql
-- Connect to Supabase SQL Editor and run:
DROP TABLE IF EXISTS security_events CASCADE;
DROP TABLE IF EXISTS video_call_audit_log CASCADE;
DROP TABLE IF EXISTS meeting_quotas CASCADE;
DROP MATERIALIZED VIEW IF EXISTS quota_usage_summary CASCADE;
DROP FUNCTION IF EXISTS check_meeting_quota CASCADE;
DROP FUNCTION IF EXISTS log_video_call_audit_event CASCADE;
DROP FUNCTION IF EXISTS log_security_event CASCADE;
```

---

### Step 2: Update Edge Function (20 minutes)

**File to modify:** `supabase/functions/chime-meeting-token/index.ts`

#### 2.1: Copy security patch file

```bash
# The security patch file is already created:
# supabase/functions/chime-meeting-token-security-patch.ts

# Move it to the correct location
mv supabase/functions/chime-meeting-token-security-patch.ts \
   supabase/functions/chime-meeting-token/authorization.ts
```

#### 2.2: Update index.ts

Add this code **AFTER Firebase JWT verification and BEFORE calling Chime Lambda:**

```typescript
// Import authorization function
import { authorizeVideoCallAccess } from './authorization.ts';

// ... existing Firebase JWT verification code ...

// CRITICAL SECURITY CHECK - Validate authorization
console.log('[SECURITY] Starting authorization checks...');
const authResult = await authorizeVideoCallAccess(
  supabase,
  appointmentId,
  sessionId,
  supabaseUserId,
  firebaseUid
);

if (!authResult.authorized) {
  console.error('[SECURITY] ❌ Authorization failed:', authResult.error);

  // Log security event
  await supabase.rpc('log_security_event', {
    p_event_type: 'unauthorized_access_attempt',
    p_severity: 'high',
    p_user_id: supabaseUserId,
    p_error_message: authResult.error,
    p_request_path: '/chime-meeting-token',
    p_request_method: 'POST'
  });

  return new Response(
    JSON.stringify({
      error: authResult.error,
      code: 'UNAUTHORIZED'
    }),
    {
      status: authResult.statusCode || 403,
      headers: { 'Content-Type': 'application/json' }
    }
  );
}

console.log('[SECURITY] ✅ Authorization successful');

// ... continue with existing Chime Lambda call ...

// After successful token generation, log success
await supabase.rpc('log_video_call_audit_event', {
  p_user_id: supabaseUserId,
  p_appointment_id: appointmentId,
  p_meeting_id: sessionId,
  p_action: 'join_success',
  p_firebase_uid: firebaseUid,
  p_supabase_uid: supabaseUserId
});
```

#### 2.3: Deploy Edge Function

```bash
# Deploy updated function
npx supabase functions deploy chime-meeting-token

# Verify deployment
npx supabase functions list

# Check logs for any errors
npx supabase functions logs chime-meeting-token --tail
```

---

### Step 3: AWS CloudFormation Update (30 minutes)

**File to deploy:** `aws-deployment/cloudformation/chime-sdk-security-patch.yaml`

#### 3.1: Merge security patch into main template

```bash
cd aws-deployment/cloudformation

# Backup existing template
cp chime-sdk-multi-region.yaml chime-sdk-multi-region.yaml.backup-$(date +%Y%m%d)

# Review the security patch
cat chime-sdk-security-patch.yaml

# Important: Manually merge the resources from security-patch.yaml
# into chime-sdk-multi-region.yaml

# The key sections to add/update:
# 1. Add ChimeWAF resource
# 2. Add ChimeWAFAssociation
# 3. Add FailedMeetingsQueue
# 4. Update MeetingManagerFunction properties
# 5. Update ChimeApiGateway CORS configuration
# 6. Add CloudWatch alarms
# 7. Add security dashboard
```

#### 3.2: Validate template

```bash
# Validate CloudFormation syntax
aws cloudformation validate-template \
  --template-body file://chime-sdk-multi-region.yaml \
  --region eu-central-1
```

#### 3.3: Deploy to eu-central-1

**⚠️ WARNING:** This will update production infrastructure. Have rollback plan ready.

```bash
# Create change set first (preview changes)
aws cloudformation create-change-set \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --template-body file://chime-sdk-multi-region.yaml \
  --change-set-name security-enhancements-phase1 \
  --capabilities CAPABILITY_IAM \
  --region eu-central-1 \
  --parameters \
    ParameterKey=SupabaseUrl,UsePreviousValue=true \
    ParameterKey=SupabaseServiceKey,UsePreviousValue=true

# Review change set
aws cloudformation describe-change-set \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --change-set-name security-enhancements-phase1 \
  --region eu-central-1

# If changes look good, execute
aws cloudformation execute-change-set \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --change-set-name security-enhancements-phase1 \
  --region eu-central-1

# Monitor deployment (takes 5-10 minutes)
aws cloudformation describe-stack-events \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1 \
  --max-items 50
```

#### 3.4: Verify WAF deployment

```bash
# List WAF Web ACLs
aws wafv2 list-web-acls \
  --scope REGIONAL \
  --region eu-central-1

# Verify WAF association with API Gateway
aws wafv2 list-resources-for-web-acl \
  --web-acl-arn $(aws wafv2 list-web-acls --scope REGIONAL --region eu-central-1 --query 'WebACLs[0].ARN' --output text) \
  --region eu-central-1
```

---

### Step 4: Testing & Validation (45 minutes)

#### 4.1: Test Rate Limiting (WAF)

```bash
# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ChimeApiEndpoint`].OutputValue' \
  --output text)

echo "Testing rate limiting on: $API_ENDPOINT"

# Test: Send 101 requests (should get 429 after 100)
for i in {1..101}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST $API_ENDPOINT/meetings)
  echo "Request $i: HTTP $STATUS"
  if [ "$STATUS" == "429" ]; then
    echo "✅ Rate limiting working! Blocked at request $i"
    break
  fi
  sleep 0.1
done
```

#### 4.2: Test Geographic Restriction

```bash
# NOTE: Geographic restriction has been DISABLED for global access
# All regions worldwide can now access the API
# This test is no longer applicable

# To verify global access works:
curl -X POST $API_ENDPOINT/meetings \
  -H "Content-Type: application/json" \
  -d '{"action": "create"}' \
  -v

# Expected response from any region:
# HTTP/1.1 401 or 403 (unauthorized, but not geo-blocked)
# Geographic blocking should NOT occur
```

#### 4.3: Test Meeting Authorization

**Prerequisites:**
- 2 test users (1 provider, 1 patient)
- 1 test appointment
- Valid Firebase JWT tokens

```bash
# Create test script
cat > test-authorization.sh << 'EOF'
#!/bin/bash

# Test 1: Authorized provider
echo "Test 1: Authorized Provider Access"
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "Authorization: Bearer PROVIDER_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointmentId": "VALID_APPOINTMENT_ID",
    "sessionId": "VALID_SESSION_ID"
  }'

# Test 2: Unauthorized user (not in appointment)
echo "\nTest 2: Unauthorized User Access"
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "Authorization: Bearer OTHER_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointmentId": "VALID_APPOINTMENT_ID",
    "sessionId": "VALID_SESSION_ID"
  }'
# Expected: 403 Forbidden

# Test 3: Expired appointment
echo "\nTest 3: Expired Appointment"
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "Authorization: Bearer PROVIDER_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointmentId": "EXPIRED_APPOINTMENT_ID",
    "sessionId": "VALID_SESSION_ID"
  }'
# Expected: 410 Gone or 403 Forbidden

# Test 4: Cancelled appointment
echo "\nTest 4: Cancelled Appointment"
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "Authorization: Bearer PROVIDER_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointmentId": "CANCELLED_APPOINTMENT_ID",
    "sessionId": "VALID_SESSION_ID"
  }'
# Expected: 410 Gone
EOF

chmod +x test-authorization.sh
# ./test-authorization.sh
```

#### 4.4: Test Meeting Quotas

```bash
# Connect to Supabase and test quota function
npx supabase db remote exec --sql "
-- Test quota check for test user
SELECT check_meeting_quota('TEST_USER_UUID');

-- Simulate 10 meeting creations
DO \$\$
BEGIN
  FOR i IN 1..10 LOOP
    INSERT INTO video_call_sessions (appointment_id, chime_meeting_id)
    VALUES ('test-appt-' || i, 'test-meeting-' || i);
  END LOOP;
END \$\$;

-- Try to create 11th meeting (should fail with quota error)
SELECT check_meeting_quota('TEST_USER_UUID');
"
```

#### 4.5: Verify Audit Logging

```bash
# Check audit logs are being created
npx supabase db remote exec --sql "
SELECT
  action,
  COUNT(*) as event_count,
  MAX(created_at) as latest_event
FROM video_call_audit_log
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY action
ORDER BY event_count DESC;
"
```

#### 4.6: Test Lambda DLQ

```bash
# Trigger Lambda error (send invalid request)
curl -X POST $API_ENDPOINT/meetings \
  -H "Content-Type: application/json" \
  -d '{"action": "invalid_action"}'

# Check DLQ for messages
aws sqs get-queue-attributes \
  --queue-url $(aws sqs list-queues --region eu-central-1 --query 'QueueUrls[?contains(@, `failed-meetings`)]' --output text) \
  --attribute-names ApproximateNumberOfMessages \
  --region eu-central-1
```

---

### Step 5: Monitoring Setup (15 minutes)

#### 5.1: Access Security Dashboard

```bash
# Get dashboard URL
DASHBOARD_URL=$(aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`SecurityDashboardUrl`].OutputValue' \
  --output text)

echo "Security Dashboard: $DASHBOARD_URL"
open "$DASHBOARD_URL"  # macOS
# or
xdg-open "$DASHBOARD_URL"  # Linux
```

#### 5.2: Configure CloudWatch Alarms

All alarms are automatically created by CloudFormation:

- **WAFBlockedRequestsAlarm** - Alerts when >10 requests blocked in 5 min
- **LambdaErrorAlarm** - Alerts when >5 Lambda errors in 1 min
- **DLQMessagesAlarm** - Alerts on any DLQ message

**Verify alarms:**
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix medzen \
  --region eu-central-1 \
  --query 'MetricAlarms[].AlarmName' \
  --output table
```

#### 5.3: Set up SNS notifications (optional)

```bash
# Create SNS topic for alerts
aws sns create-topic \
  --name medzen-security-alerts \
  --region eu-central-1

# Subscribe email to topic
aws sns subscribe \
  --topic-arn $(aws sns list-topics --region eu-central-1 --query 'Topics[?contains(TopicArn, `security-alerts`)].TopicArn' --output text) \
  --protocol email \
  --notification-endpoint security@medzenhealth.app \
  --region eu-central-1

# Update alarms to send to SNS (via CloudFormation or CLI)
```

---

## 🎯 Post-Deployment Verification

### Success Criteria

- [ ] Database migration applied successfully
- [ ] Edge Function deployed without errors
- [ ] CloudFormation stack updated (Status: UPDATE_COMPLETE)
- [ ] WAF associated with API Gateway
- [ ] Rate limiting blocks after 100 requests
- [ ] Geographic restriction blocks non-EU IPs
- [ ] Meeting authorization prevents unauthorized access
- [ ] Meeting quotas enforce 10/day limit
- [ ] Audit logs are being created
- [ ] CloudWatch dashboard shows metrics
- [ ] All alarms are in OK state
- [ ] No errors in Lambda logs
- [ ] No errors in Edge Function logs

### Key Metrics to Monitor (First 24 Hours)

```bash
# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=medzen-chime-waf-eu-central-1 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region eu-central-1

# Check Lambda error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=medzen-meeting-manager \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region eu-central-1

# Check quota usage
npx supabase db remote exec --sql "
SELECT * FROM quota_usage_summary
WHERE daily_usage_percent > 50
ORDER BY daily_usage_percent DESC
LIMIT 10;
"
```

---

## 🚨 Rollback Procedures

### If Edge Function fails:

```bash
# Revert to previous version
npx supabase functions deploy chime-meeting-token --revert

# Or disable authorization temporarily (NOT RECOMMENDED)
# Comment out authorization check in index.ts and redeploy
```

### If CloudFormation fails:

```bash
# Cancel update and rollback
aws cloudformation cancel-update-stack \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1

# Wait for rollback to complete
aws cloudformation wait stack-rollback-complete \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1
```

### If Database migration fails:

```bash
# Run rollback script (see Step 1 above)
# Manually execute DROP statements in Supabase SQL Editor
```

---

## 💰 Cost Impact

**New monthly costs:**
- AWS WAF: $5-10/month (+ $0.60 per 1M requests)
- CloudWatch Logs (increased): +$1-2/month
- SQS DLQ: +$0.50/month
- CloudWatch Alarms (3 new): +$0.30/month

**Total increase:** ~$7-13/month (+2-5%)

**Monitor costs:**
```bash
# Get current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics UnblendedCost \
  --region us-east-1
```

---

## 📞 Support & Troubleshooting

### Common Issues

**Issue:** WAF blocking legitimate requests
**Solution:** Check WAF logs, adjust rate limits if needed
```bash
aws wafv2 get-sampled-requests \
  --web-acl-arn $(aws wafv2 list-web-acls --scope REGIONAL --region eu-central-1 --query 'WebACLs[0].ARN' --output text) \
  --rule-metric-name ChimeRateLimit \
  --scope REGIONAL \
  --time-window StartTime=$(date -u -d '1 hour ago' +%s),EndTime=$(date -u +%s) \
  --max-items 100 \
  --region eu-central-1
```

**Issue:** Meeting quotas too restrictive
**Solution:** Adjust limits for specific users
```sql
UPDATE meeting_quotas
SET daily_quota_limit = 20,
    monthly_quota_limit = 200
WHERE user_id = 'USER_UUID';
```

**Issue:** Authorization blocking valid users
**Solution:** Check audit logs for details
```sql
SELECT * FROM video_call_audit_log
WHERE action = 'join_attempt_unauthorized'
AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;
```

---

## ✅ Deployment Complete

Once all verification steps pass:

1. Update status tracking (mark Phase 1 complete)
2. Schedule Phase 2 deployment (Week 2)
3. Document any issues encountered
4. Share security metrics with team

**Next Phase:** Infrastructure Hardening (X-Ray, Circuit Breaker, Lambda Layers)

