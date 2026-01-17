# AI Chat Security and Authorization Testing Guide

**Phase 8 of 9-Phase AI Chat Testing Plan**
**Date:** December 18, 2025
**Status:** ✅ Backend Verified - Ready for Security Testing

---

## Overview

This guide provides comprehensive security and authorization testing procedures for the MedZen AI chat system. Security testing validates that:

1. **Data Isolation**: Users can only access their own conversations
2. **Authentication**: All API calls require valid authentication
3. **Authorization**: Role-based access controls work correctly
4. **Input Validation**: System prevents injection attacks
5. **Rate Limiting**: System prevents abuse
6. **Token Security**: Firebase tokens validated properly
7. **API Security**: Edge Functions and Lambda protected
8. **Privacy**: No data leakage between users

---

## Prerequisites

**Backend Verification (Phase 1):**
- ✅ Supabase Edge Function: `bedrock-ai-chat` deployed
- ✅ AWS Lambda: `medzen-ai-chat-handler` active
- ✅ Database: RLS policies enabled on all tables
- ✅ Firebase Authentication: Token validation working

**Test Requirements:**
- Multiple test user accounts (different roles)
- Browser DevTools (for network inspection)
- Database access (for RLS verification)
- Firebase console access (for token management)
- Postman or curl (for API testing)

**Security Testing Tools:**
- Browser DevTools (Network, Console, Application tabs)
- PostgreSQL client (psql or pgAdmin)
- Firebase Admin SDK (for token validation)
- Supabase Dashboard (for RLS policy inspection)

---

## Test Suite 1: Row Level Security (RLS) Policy Validation

### Test 1.1: User Can Only Access Own Conversations

**Objective:** Verify users cannot query other users' conversations

**Test Steps:**

1. **Setup:**
   - Login as User A
   - Create conversation and note conversation ID
   - Logout

2. **Test:**
   - Login as User B
   - Attempt to access User A's conversation via direct query

3. **Database Test:**
```sql
-- As User B (set your session)
SET request.jwt.claims.sub = 'user-b-firebase-uid';

-- Try to access User A's conversation
SELECT * FROM ai_conversations WHERE id = 'user-a-conversation-id';
```

**Expected Results:**
- ✅ Query returns 0 rows (not User A's conversation)
- ✅ No error thrown (RLS silently filters)
- ✅ User B cannot see User A's data

**Database Verification:**
```sql
-- Verify RLS policy exists
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'ai_conversations'
  AND policyname LIKE '%select%';
```

**Expected Policy:**
```sql
-- Should return policy similar to:
-- policyname: ai_conversations_select_policy
-- qual: (patient_id = auth.uid())
-- cmd: SELECT
```

### Test 1.2: User Cannot Insert Messages to Other Conversations

**Test Steps:**

1. Login as User A, create conversation, note ID
2. Login as User B
3. Attempt to insert message into User A's conversation:

```sql
-- As User B
SET request.jwt.claims.sub = 'user-b-firebase-uid';

INSERT INTO ai_messages (
  id,
  conversation_id,
  role,
  content,
  language_code
) VALUES (
  gen_random_uuid(),
  'user-a-conversation-id',
  'user',
  'Unauthorized message',
  'en'
);
```

**Expected Results:**
- ✅ INSERT fails or is silently ignored
- ✅ No new message appears in User A's conversation
- ✅ Error message indicates permission denied

### Test 1.3: Service Role Bypasses RLS (For Edge Functions)

**Objective:** Verify Edge Functions can access all data via service role

**Test Steps:**

1. Call Edge Function with service role credentials
2. Verify Edge Function can access any conversation

**Test Command:**
```bash
# Test Edge Function with service role
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [FIREBASE_ID_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "any-conversation-id",
    "userId": "any-user-id",
    "message": "Test message",
    "conversationHistory": [],
    "preferredLanguage": "en"
  }'
```

**Expected Results:**
- ✅ Edge Function successfully processes request
- ✅ Service role (used internally by Edge Function) bypasses RLS
- ✅ But user-facing API still enforces authentication

### Test 1.4: RLS on ai_messages Table

**Test Steps:**

```sql
-- As User B, try to read User A's messages
SET request.jwt.claims.sub = 'user-b-firebase-uid';

SELECT * FROM ai_messages
WHERE conversation_id = 'user-a-conversation-id';
```

**Expected Results:**
- ✅ Query returns 0 rows
- ✅ User B cannot see User A's messages
- ✅ RLS policy filters based on conversation ownership

### Test 1.5: Cross-User Conversation Update Prevention

**Test Steps:**

```sql
-- As User B, try to update User A's conversation
SET request.jwt.claims.sub = 'user-b-firebase-uid';

UPDATE ai_conversations
SET conversation_title = 'Hacked!'
WHERE id = 'user-a-conversation-id';
```

**Expected Results:**
- ✅ UPDATE affects 0 rows
- ✅ User A's conversation title unchanged
- ✅ No permission error (RLS silently filters)

---

## Test Suite 2: Authentication Edge Cases

### Test 2.1: Unauthenticated API Request

**Objective:** Verify API rejects requests without authentication

**Test Steps:**

```bash
# Call Edge Function without Authorization header
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "test-id",
    "userId": "test-user",
    "message": "Unauthorized test",
    "conversationHistory": []
  }'
```

**Expected Results:**
- ✅ Response: 401 Unauthorized or 403 Forbidden
- ✅ Error message: "Missing or invalid authorization token"
- ✅ No conversation created
- ✅ No message stored in database

### Test 2.2: Expired Firebase Token

**Test Steps:**

1. Generate Firebase ID token
2. Wait for token to expire (1 hour default)
3. Attempt API call with expired token

```bash
# Use expired token
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [EXPIRED_FIREBASE_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"test","userId":"user","message":"test","conversationHistory":[]}'
```

**Expected Results:**
- ✅ Response: 401 Unauthorized
- ✅ Error: "Token expired" or "Invalid token"
- ✅ No data modification

### Test 2.3: Malformed Firebase Token

**Test Steps:**

```bash
# Use random string as token
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer invalid-token-12345" \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"test","userId":"user","message":"test","conversationHistory":[]}'
```

**Expected Results:**
- ✅ Response: 401 Unauthorized
- ✅ Error: "Invalid token format"
- ✅ Request rejected immediately

### Test 2.4: Token from Different Firebase Project

**Test Steps:**

1. Create token from different Firebase project
2. Attempt to use with MedZen API

**Expected Results:**
- ✅ Response: 401 Unauthorized
- ✅ Error: "Token from wrong project"
- ✅ Firebase Admin SDK validates project ID

### Test 2.5: Revoked User Token

**Test Steps:**

1. Login as user, get valid token
2. In Firebase Console, revoke user's tokens
3. Attempt API call with revoked token

**Expected Results:**
- ✅ Response: 401 Unauthorized
- ✅ Error: "Token revoked"
- ✅ User must re-authenticate

---

## Test Suite 3: Authorization Bypass Attempts

### Test 3.1: User ID Manipulation in Request Body

**Objective:** Verify server validates userId matches token

**Test Steps:**

1. Login as User A, get Firebase token
2. Send request with User B's ID in body

```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [USER_A_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "new-conversation-id",
    "userId": "user-b-id",
    "message": "Trying to impersonate User B",
    "conversationHistory": []
  }'
```

**Expected Results:**
- ✅ Server detects mismatch between token and userId
- ✅ Request rejected with 403 Forbidden
- ✅ Error: "User ID mismatch" or similar
- ✅ No conversation created for User B

**Code Verification (in Edge Function):**
```typescript
// Should have validation like:
if (requestBody.userId !== decodedToken.uid) {
  return new Response(
    JSON.stringify({ error: 'User ID mismatch' }),
    { status: 403 }
  );
}
```

### Test 3.2: Conversation ID Hijacking

**Test Steps:**

1. User A creates conversation (note ID)
2. User B attempts to send message to User A's conversation

```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [USER_B_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "user-a-conversation-id",
    "userId": "user-b-id",
    "message": "Unauthorized access attempt",
    "conversationHistory": []
  }'
```

**Expected Results:**
- ✅ Server validates conversation belongs to requesting user
- ✅ Request rejected with 403 Forbidden
- ✅ Error: "Conversation not found" or "Access denied"
- ✅ User A's conversation unchanged

### Test 3.3: Assistant ID Manipulation

**Test Steps:**

Attempt to specify wrong assistant type for user role:

```bash
# Provider user trying to use Health Assistant (patient assistant)
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [PROVIDER_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "new-conversation",
    "userId": "provider-user-id",
    "assistantId": "f11201de-09d6-4876-ac62-fd8eb2e44692",
    "message": "Test",
    "conversationHistory": []
  }'
```

**Expected Results:**
- ✅ Server ignores provided assistantId
- ✅ Automatically detects user role (provider)
- ✅ Assigns correct Clinical Assistant
- ✅ User cannot manually select wrong assistant

---

## Test Suite 4: SQL Injection Prevention

### Test 4.1: SQL Injection in Message Content

**Test Steps:**

Send message with SQL injection payload:

**Test Messages:**
```
1. "'; DROP TABLE ai_messages; --"
2. "1' OR '1'='1"
3. "admin'--"
4. "' UNION SELECT * FROM users --"
5. "'; DELETE FROM ai_conversations WHERE '1'='1"
```

**Test Execution:**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [VALID_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "test-id",
    "userId": "valid-user-id",
    "message": "'\'' OR '\''1'\''='\''1",
    "conversationHistory": []
  }'
```

**Expected Results:**
- ✅ Message treated as literal text (not SQL)
- ✅ AI responds to message content (not SQL execution)
- ✅ No database tables affected
- ✅ Message stored verbatim in ai_messages table
- ✅ Supabase client library uses parameterized queries

**Database Verification:**
```sql
-- Verify all tables still exist
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- Verify message stored as text
SELECT content FROM ai_messages ORDER BY created_at DESC LIMIT 1;
-- Should show: '; DROP TABLE ai_messages; -- (as literal text)
```

### Test 4.2: SQL Injection in Conversation ID

**Test Steps:**

```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [VALID_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "test'\'' OR '\''1'\''='\''1",
    "userId": "valid-user-id",
    "message": "Test message",
    "conversationHistory": []
  }'
```

**Expected Results:**
- ✅ Invalid UUID format rejected
- ✅ Error: "Invalid conversation ID format"
- ✅ No SQL execution
- ✅ Request fails safely

---

## Test Suite 5: XSS (Cross-Site Scripting) Prevention

### Test 5.1: XSS in Message Content

**Objective:** Verify AI responses don't execute JavaScript

**Test Messages:**
```javascript
1. "<script>alert('XSS')</script>"
2. "<img src=x onerror=alert('XSS')>"
3. "<svg/onload=alert('XSS')>"
4. "javascript:alert('XSS')"
5. "<iframe src='javascript:alert(\"XSS\")'></iframe>"
```

**Test Steps:**

1. Send message with XSS payload
2. Observe AI response
3. Inspect message display in UI

**Expected Results:**
- ✅ Message displayed as plain text (HTML escaped)
- ✅ No JavaScript execution in browser
- ✅ DevTools Console shows no XSS warnings
- ✅ HTML tags visible as text: `&lt;script&gt;alert('XSS')&lt;/script&gt;`

**UI Code Verification:**
```dart
// In Flutter, Text widgets automatically escape HTML
Text(message.content)  // Safe - no HTML rendering

// If using HTML rendering (avoid!), must sanitize:
// DO NOT USE: HtmlWidget(message.content) without sanitization
```

### Test 5.2: XSS in Conversation Title

**Test Steps:**

1. Create conversation with title: `<script>alert('XSS')</script>`
2. View conversation in history list
3. Inspect page source

**Expected Results:**
- ✅ Title displayed as text, not executed
- ✅ HTML tags escaped in DOM
- ✅ No script execution

---

## Test Suite 6: Rate Limiting and Abuse Prevention

### Test 6.1: Message Rate Limiting

**Objective:** Prevent spam and abuse

**Test Steps:**

1. Send 20 messages rapidly (within 10 seconds)
2. Observe rate limiting behavior

**Test Script:**
```bash
#!/bin/bash
TOKEN="[VALID_FIREBASE_TOKEN]"
for i in {1..20}; do
  curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"conversationId\":\"test\",\"userId\":\"user\",\"message\":\"Message $i\",\"conversationHistory\":[]}" &
done
wait
```

**Expected Results:**
- ✅ First 10 messages succeed
- ✅ Subsequent messages return 429 Too Many Requests
- ✅ Error: "Rate limit exceeded. Try again in X seconds."
- ✅ Rate limit resets after cooldown period

**Rate Limit Configuration (Check):**
```typescript
// Expected in Edge Function or API Gateway
const RATE_LIMIT = {
  maxRequests: 10,
  windowSeconds: 60,
  message: 'Rate limit exceeded'
};
```

### Test 6.2: Conversation Creation Rate Limiting

**Test Steps:**

1. Attempt to create 20 conversations rapidly

**Expected Results:**
- ✅ Rate limit applied (max 5 conversations per minute)
- ✅ Error after threshold exceeded
- ✅ Prevents conversation spam

### Test 6.3: Token Cost Abuse Prevention

**Test Steps:**

1. Send extremely long message (10,000 characters)
2. Observe handling

**Expected Results:**
- ✅ Message rejected if exceeds max length (2000 chars)
- ✅ Error: "Message too long"
- ✅ Prevents excessive token usage
- ✅ No AI call made for oversized message

---

## Test Suite 7: API Security Audit

### Test 7.1: HTTPS Enforcement

**Test Steps:**

```bash
# Attempt HTTP (non-encrypted) request
curl -X POST http://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"test","userId":"user","message":"test","conversationHistory":[]}'
```

**Expected Results:**
- ✅ Request redirected to HTTPS (301/302)
- ✅ Or request blocked with error
- ✅ No data transmitted over unencrypted connection

### Test 7.2: CORS Policy Validation

**Test Steps:**

1. Open browser DevTools → Network tab
2. Send message from AI chat
3. Inspect OPTIONS preflight request

**Expected Results:**
- ✅ CORS headers present:
  - `Access-Control-Allow-Origin: [your-app-domain]` (NOT `*`)
  - `Access-Control-Allow-Methods: POST`
  - `Access-Control-Allow-Headers: Authorization, Content-Type`
- ✅ Requests from other domains blocked
- ✅ Only authorized origins allowed

### Test 7.3: Request Header Validation

**Test Steps:**

Send request with missing Content-Type:

```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [TOKEN]" \
  -d '{"conversationId":"test","userId":"user","message":"test","conversationHistory":[]}'
```

**Expected Results:**
- ✅ Request accepted (server handles missing Content-Type)
- ✅ Or error: "Content-Type must be application/json"

### Test 7.4: Request Size Limiting

**Test Steps:**

Send extremely large payload (1MB+):

```bash
# Generate large payload
python3 -c "import json; print(json.dumps({'message': 'A' * 1000000}))" > large_payload.json

curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [TOKEN]" \
  -H "Content-Type: application/json" \
  -d @large_payload.json
```

**Expected Results:**
- ✅ Request rejected with 413 Payload Too Large
- ✅ Or 400 Bad Request
- ✅ Server doesn't process oversized payloads

---

## Test Suite 8: Token Security

### Test 8.1: Token Exposure in Logs

**Objective:** Verify tokens not logged

**Test Steps:**

1. Send message
2. Check Edge Function logs
3. Check Lambda CloudWatch logs

**Verification Commands:**
```bash
# Check Supabase logs
npx supabase functions logs bedrock-ai-chat --tail | grep "Bearer"

# Check AWS Lambda logs
aws logs tail /aws/lambda/medzen-ai-chat-handler --follow | grep "Bearer"
```

**Expected Results:**
- ✅ Authorization tokens NOT visible in logs
- ✅ Only sanitized logs (e.g., "User authenticated")
- ✅ No sensitive data in error messages

### Test 8.2: Token in URL Parameters (Anti-Pattern)

**Test Steps:**

Attempt to pass token via URL query parameter:

```bash
curl "https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat?token=[TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"test","userId":"user","message":"test","conversationHistory":[]}'
```

**Expected Results:**
- ✅ Request rejected (token must be in header)
- ✅ URL-based tokens not accepted
- ✅ Prevents token exposure in logs/history

### Test 8.3: Token Replay Attack Prevention

**Test Steps:**

1. Capture valid token from network request
2. Use same token from different IP/device
3. After extended time period

**Expected Results:**
- ✅ Token works across devices (Firebase tokens are portable)
- ✅ But subject to expiration (1 hour default)
- ✅ Revoked tokens immediately invalid

---

## Test Suite 9: Privacy and Data Leakage

### Test 9.1: AI Response Doesn't Leak Other User Data

**Test Steps:**

1. User A creates conversation with medical data
2. User B asks AI: "What did User A ask about?"

**Expected Results:**
- ✅ AI responds: "I don't have access to other users' conversations"
- ✅ No data from User A's conversation leaked
- ✅ Each conversation isolated

### Test 9.2: Error Messages Don't Expose Sensitive Data

**Test Steps:**

Trigger various errors and inspect messages:

**Tests:**
```bash
# Invalid conversation ID
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [TOKEN]" \
  -d '{"conversationId":"nonexistent-id","userId":"user","message":"test","conversationHistory":[]}'

# Invalid user ID
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [TOKEN]" \
  -d '{"conversationId":"test","userId":"invalid-user","message":"test","conversationHistory":[]}'
```

**Expected Results:**
- ✅ Generic error messages (no database details)
- ✅ No SQL error messages exposed
- ✅ No internal paths or stack traces
- ✅ Error: "Resource not found" (NOT "User with ID 'xyz' does not exist in table 'users'")

### Test 9.3: Profile Data Isolation

**Test Steps:**

1. User A sets profile picture
2. User B queries User A's conversation
3. Inspect response for User A's data

**Expected Results:**
- ✅ User B cannot see User A's profile picture URL
- ✅ User B cannot see User A's personal info
- ✅ Only conversation participants' data visible

---

## Test Suite 10: Audit Logging and Monitoring

### Test 10.1: Failed Authentication Logging

**Test Steps:**

1. Send 5 requests with invalid tokens
2. Check audit logs

**Verification:**
```bash
# Check Edge Function logs for failed auth
npx supabase functions logs bedrock-ai-chat --tail | grep "unauthorized\|401\|403"
```

**Expected Results:**
- ✅ All failed authentication attempts logged
- ✅ Logs include timestamp, IP (if available), error type
- ✅ No sensitive data in logs (tokens redacted)

### Test 10.2: Suspicious Activity Detection

**Test Steps:**

Simulate suspicious behavior:
1. Rapid failed login attempts (5+ in 1 minute)
2. Access attempts to many different conversations
3. Unusual message patterns

**Expected Results:**
- ✅ Suspicious activity flagged in logs
- ✅ Rate limiting applied
- ✅ Optional: Alert triggered for security team

### Test 10.3: Security Incident Response

**Test Steps:**

1. Simulate security incident (e.g., compromised token)
2. Revoke token in Firebase Console
3. Verify immediate effect

**Expected Results:**
- ✅ Revoked token immediately invalid
- ✅ User must re-authenticate
- ✅ No grace period for revoked tokens

---

## Database Security Verification

### Verify RLS Policies on All Tables

```sql
-- Check RLS enabled
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('ai_conversations', 'ai_messages', 'ai_assistants')
ORDER BY tablename;

-- Expected: rowsecurity = true for all tables
```

### Verify RLS Policies Exist

```sql
-- List all RLS policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('ai_conversations', 'ai_messages', 'ai_assistants')
ORDER BY tablename, cmd;
```

**Expected Policies:**

**ai_conversations:**
- SELECT: `(patient_id = auth.uid())`
- INSERT: `(patient_id = auth.uid())`
- UPDATE: `(patient_id = auth.uid())`
- DELETE: `(patient_id = auth.uid())`

**ai_messages:**
- SELECT: `(EXISTS (SELECT 1 FROM ai_conversations WHERE id = ai_messages.conversation_id AND patient_id = auth.uid()))`
- INSERT: `(EXISTS (SELECT 1 FROM ai_conversations WHERE id = ai_messages.conversation_id AND patient_id = auth.uid()))`

**ai_assistants:**
- SELECT: `true` (public read access)

### Test RLS with Different Roles

```sql
-- Test as authenticated user
SET ROLE authenticated;
SET request.jwt.claims.sub = 'test-user-id';

SELECT * FROM ai_conversations;
-- Should only return conversations for test-user-id

-- Test as service_role (should bypass RLS)
SET ROLE service_role;
SELECT COUNT(*) FROM ai_conversations;
-- Should return all conversations
```

---

## Security Best Practices Validation

### Checklist

- [ ] **Authentication:**
  - [ ] All API endpoints require authentication
  - [ ] Firebase tokens validated on every request
  - [ ] Expired tokens rejected immediately
  - [ ] Revoked tokens cannot be used

- [ ] **Authorization:**
  - [ ] Users can only access own conversations (RLS)
  - [ ] User cannot modify userId in requests
  - [ ] Conversation ownership validated server-side
  - [ ] Role-based assistant assignment cannot be bypassed

- [ ] **Input Validation:**
  - [ ] SQL injection prevented (parameterized queries)
  - [ ] XSS prevented (HTML escaping in UI)
  - [ ] Message length limits enforced
  - [ ] UUID format validation

- [ ] **Rate Limiting:**
  - [ ] Message rate limiting active (10/minute)
  - [ ] Conversation creation limited (5/minute)
  - [ ] 429 errors returned when exceeded

- [ ] **Data Privacy:**
  - [ ] No cross-user data leakage
  - [ ] Error messages don't expose sensitive info
  - [ ] Tokens not logged
  - [ ] Audit logging enabled

- [ ] **Transport Security:**
  - [ ] HTTPS enforced
  - [ ] CORS configured correctly
  - [ ] Tokens in headers (not URLs)
  - [ ] Request size limits enforced

- [ ] **Database Security:**
  - [ ] RLS enabled on all tables
  - [ ] RLS policies tested and verified
  - [ ] Service role used only by Edge Functions
  - [ ] Database credentials secured (not in code)

---

## Common Security Issues & Troubleshooting

### Issue 1: RLS Not Working (Users See Others' Data)

**Symptoms:**
- User B can see User A's conversations
- Database queries return all rows

**Diagnosis:**
```sql
-- Check if RLS enabled
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'ai_conversations';
```

**Solutions:**
```sql
-- Enable RLS
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- Create SELECT policy
CREATE POLICY ai_conversations_select_policy ON ai_conversations
  FOR SELECT USING (patient_id = auth.uid());

-- Verify policies
SELECT * FROM pg_policies WHERE tablename = 'ai_conversations';
```

### Issue 2: Service Role Cannot Access Data

**Symptoms:**
- Edge Function fails with "permission denied"
- RLS blocking service role

**Solutions:**
```sql
-- Verify service_role bypasses RLS
ALTER TABLE ai_conversations FORCE ROW LEVEL SECURITY;
-- Then ensure service_role has BYPASSRLS attribute
```

### Issue 3: Rate Limiting Not Applied

**Symptoms:**
- Users can spam unlimited messages
- No 429 errors

**Solution:**
- Implement rate limiting in Edge Function or API Gateway
- Add Redis/memory cache for rate limit tracking
- Return 429 with Retry-After header

### Issue 4: Tokens Exposed in Logs

**Symptoms:**
- Authorization tokens visible in logs
- Security risk

**Solution:**
```typescript
// Sanitize logs - DO NOT log full token
console.log('User authenticated:', { userId: user.id });
// NOT: console.log('Token:', authHeader);
```

### Issue 5: XSS in Message Display

**Symptoms:**
- JavaScript executing in message bubbles
- HTML tags rendered

**Solution:**
```dart
// In Flutter, use Text widget (auto-escapes)
Text(message.content)

// NOT: HtmlWidget(message.content) without sanitization
```

---

## Security Testing Report Template

After completing all tests, fill out this report:

```markdown
## AI Chat Security Testing Results

**Test Date:** YYYY-MM-DD
**Tester:** [Name]
**Environment:** [Production/Staging/Development]

### Test Results Summary

**Row Level Security:**
- [ ] User isolation verified
- [ ] Cross-user access blocked
- [ ] Service role bypass working
- [ ] All RLS policies tested

**Authentication:**
- [ ] Unauthenticated requests blocked
- [ ] Expired tokens rejected
- [ ] Malformed tokens rejected
- [ ] Token revocation working

**Authorization:**
- [ ] User ID manipulation prevented
- [ ] Conversation hijacking blocked
- [ ] Assistant assignment secure

**Input Validation:**
- [ ] SQL injection prevented
- [ ] XSS prevented
- [ ] Message length limits enforced

**Rate Limiting:**
- [ ] Message rate limiting active
- [ ] Conversation creation limited
- [ ] 429 errors returned correctly

**API Security:**
- [ ] HTTPS enforced
- [ ] CORS configured correctly
- [ ] Request size limits working

**Privacy:**
- [ ] No cross-user data leakage
- [ ] Error messages sanitized
- [ ] Tokens not logged

**Audit Logging:**
- [ ] Failed auth logged
- [ ] Suspicious activity detected
- [ ] Security incidents traceable

### Critical Issues Found

1. [Issue description]
   - **Severity:** Critical/High/Medium/Low
   - **Impact:** [Description]
   - **Remediation:** [Steps to fix]

### Recommendations

1. [Security recommendation]
2. [Security recommendation]

### Sign-Off

**Security Approved:** YES/NO
**Critical Issues:** [List or None]
**Notes:** [Any additional security concerns]
```

---

## Next Phase

Once Phase 8 (Security and Authorization Testing) is complete, proceed to:

**Phase 9:** Token Usage and Cost Optimization Testing
- Token counting accuracy
- Cost estimation validation
- Usage analytics
- Cost optimization strategies
- Budget alerting
- Conversation history optimization

---

## Reference Documentation

- **RLS Documentation**: [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- **Firebase Auth**: [Firebase Token Verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
- **OWASP Top 10**: [Security Best Practices](https://owasp.org/www-project-top-ten/)
- **AWS Security**: [Lambda Security Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/lambda-security.html)

---

**Last Updated:** December 18, 2025
**Backend Status:** ✅ Fully operational
**Testing Status:** ⏳ Ready for security testing
**Phase:** 8 of 9
