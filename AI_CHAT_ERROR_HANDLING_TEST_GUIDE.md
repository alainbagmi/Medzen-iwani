# AI Chat Error Handling and Edge Cases Test Guide

**Date:** December 18, 2025
**Phase:** 6 of 9
**Status:** Ready for Testing
**Prerequisites:** Phases 1-5 completed successfully

---

## Overview

This guide covers comprehensive testing of error handling, graceful degradation, and edge case scenarios for the MedZen AI chat system. These tests ensure the application handles failures gracefully, provides meaningful error messages to users, and maintains data integrity during error conditions.

**Key Testing Areas:**
- Network failure scenarios
- Invalid input handling
- API timeout handling
- Database constraint violations
- Concurrent operation conflicts
- Authentication failures
- Resource exhaustion
- Malformed data handling

---

## Pre-Test Checklist

Before starting error handling tests:
- [ ] Backend services verified operational (Phase 1)
- [ ] Role-based assignment working (Phase 2)
- [ ] Basic messaging functional (Phase 3)
- [ ] Multilingual support tested (Phase 4)
- [ ] Persistence verified (Phase 5)
- [ ] Browser console open to view error messages
- [ ] Network throttling tools available (Chrome DevTools or similar)
- [ ] Test user accounts for each role ready

---

## Test Suite 1: Network Failure Scenarios

### Test 1.1: Complete Network Loss During Message Send

**Setup:**
1. Open existing conversation
2. Open browser DevTools → Network tab
3. Type message but don't send yet

**Test Steps:**
1. Type message: "What are common cold symptoms?"
2. In DevTools, enable "Offline" mode
3. Click Send button
4. Wait for error response
5. Re-enable network
6. Verify message can be retried

**Expected Results:**
- ✅ Error message appears: "Network error. Please check your connection."
- ✅ Message remains in input field (not cleared)
- ✅ Send button re-enabled after error
- ✅ User can retry after network restored
- ✅ No duplicate messages created
- ✅ Console shows network error, not JavaScript error

**Database Verification:**
```sql
-- Should show NO new messages created during offline period
SELECT COUNT(*) FROM ai_messages
WHERE conversation_id = '[conversation-id]'
AND created_at > NOW() - INTERVAL '5 minutes';
```

**Edge Function Logs:**
```bash
npx supabase functions logs bedrock-ai-chat --tail
```
Should show: No requests during offline period, or requests with network timeout errors

---

### Test 1.2: Intermittent Network (Connection Drops Mid-Request)

**Setup:**
1. Open Chrome DevTools → Network tab
2. Set throttling to "Slow 3G"

**Test Steps:**
1. Send message
2. While "AI is thinking..." indicator shows, toggle network offline
3. Wait 10 seconds
4. Re-enable network
5. Observe behavior

**Expected Results:**
- ✅ Request times out after 30 seconds
- ✅ Error message: "Request timed out. Please try again."
- ✅ Writing indicator disappears
- ✅ User can retry
- ✅ No partial messages stored in database

**Database Verification:**
```sql
SELECT role, content, created_at
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at DESC LIMIT 5;
```
Expected: No incomplete or duplicate messages

---

### Test 1.3: Network Restored After Timeout

**Test Steps:**
1. Simulate network failure during message send
2. Wait for timeout error
3. Restore network
4. Click retry or send again
5. Verify normal operation resumes

**Expected Results:**
- ✅ Retry succeeds after network restored
- ✅ AI responds normally
- ✅ No data corruption
- ✅ Message history intact

---

## Test Suite 2: Invalid Input Handling

### Test 2.1: Empty Message

**Test Steps:**
1. Leave message input field empty
2. Click Send button

**Expected Results:**
- ✅ No API call made
- ✅ Error message: "Please enter a message"
- ✅ Input field retains focus
- ✅ No database writes

**Console Verification:**
Should see validation error, NOT network request

---

### Test 2.2: Whitespace-Only Message

**Test Steps:**
1. Type only spaces/tabs: "     "
2. Click Send

**Expected Results:**
- ✅ Message rejected
- ✅ Error: "Message cannot be empty"
- ✅ No API call
- ✅ Input field cleared

---

### Test 2.3: Extremely Long Message (>10,000 characters)

**Test Steps:**
1. Paste very long text (copy Lorem Ipsum 100 times)
2. Click Send

**Expected Results:**
- ✅ Either:
  - Message truncated to max length with warning, OR
  - Error: "Message too long. Maximum [X] characters."
- ✅ No system crash
- ✅ If allowed, AI responds appropriately
- ✅ Database handles large content field

**Database Verification:**
```sql
SELECT LENGTH(content) as message_length, content
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
AND role = 'user'
ORDER BY created_at DESC LIMIT 1;
```

---

### Test 2.4: Special Characters in Message

**Test Steps:**
1. Send message with special chars: `"Hello <script>alert('test')</script> 你好 العربية 🔥💯"`
2. Verify handling

**Expected Results:**
- ✅ Special characters properly escaped
- ✅ No XSS vulnerability
- ✅ Unicode characters (emoji, Chinese, Arabic) displayed correctly
- ✅ HTML tags rendered as text, not executed

---

### Test 2.5: SQL Injection Attempt

**Test Steps:**
1. Send message: `'; DROP TABLE ai_messages; --`
2. Verify database security

**Expected Results:**
- ✅ Message treated as literal text
- ✅ No SQL execution
- ✅ AI responds to message content (not SQL)
- ✅ Database tables intact

**Database Verification:**
```sql
-- Verify tables still exist
\dt ai_*
-- Should show: ai_assistants, ai_conversations, ai_messages
```

---

## Test Suite 3: API Timeout Handling

### Test 3.1: Edge Function Timeout

**Setup:**
1. Simulate slow AI response by testing with very complex medical question

**Test Steps:**
1. Send message: "Explain the complete pathophysiology of septic shock, including molecular mechanisms, inflammatory cascades, and treatment protocols"
2. Wait for response
3. If takes >30 seconds, observe timeout handling

**Expected Results:**
- ✅ Timeout after 30 seconds max
- ✅ Error message: "AI response timed out. Please try again with a shorter question."
- ✅ Partial response not displayed
- ✅ User can retry

**Edge Function Logs:**
```bash
npx supabase functions logs bedrock-ai-chat --tail
```
Should show: Timeout error or Lambda invocation timeout

---

### Test 3.2: Lambda Function Timeout

**Test Steps:**
1. Monitor CloudWatch logs for Lambda
2. Send message that causes Lambda timeout
3. Verify error propagation

**Expected Results:**
- ✅ Edge Function receives Lambda timeout error
- ✅ User sees: "Service temporarily unavailable. Please try again."
- ✅ No incomplete data in database

**AWS Logs:**
```bash
aws logs tail /aws/lambda/medzen-ai-chat-handler --region eu-central-1 --follow
```
Look for: "Task timed out after X seconds"

---

## Test Suite 4: Database Constraint Violations

### Test 4.1: Duplicate Conversation ID

**Setup:**
1. Note existing conversation ID
2. Attempt to create new conversation with same ID (via API if possible)

**Expected Results:**
- ✅ Database rejects duplicate with unique constraint error
- ✅ User sees: "An error occurred. Please try again."
- ✅ No data corruption
- ✅ Application remains functional

**Database Verification:**
```sql
SELECT COUNT(*) FROM ai_conversations
WHERE id = '[conversation-id]';
```
Expected: Only 1 row

---

### Test 4.2: Foreign Key Violation (Invalid Assistant ID)

**Test Steps:**
1. Attempt to create conversation with non-existent assistant_id
2. Verify constraint enforcement

**Expected Results:**
- ✅ Database rejects insert
- ✅ Error logged in backend
- ✅ User sees generic error (not technical details)
- ✅ No orphaned data

---

### Test 4.3: NULL Constraint Violation

**Test Steps:**
1. Attempt to insert message without required fields (conversation_id, role, content)
2. Verify validation

**Expected Results:**
- ✅ Insert rejected
- ✅ Error logged
- ✅ User notified
- ✅ Transaction rolled back

---

## Test Suite 5: Concurrent Operation Conflicts

### Test 5.1: Rapid Sequential Messages

**Test Steps:**
1. Send 5 messages in rapid succession (within 5 seconds)
2. Observe handling

**Expected Results:**
- ✅ All messages queued properly
- ✅ Each receives AI response
- ✅ Responses in correct order
- ✅ No race conditions
- ✅ No lost messages
- ✅ Database shows correct total_messages count

**Database Verification:**
```sql
SELECT role, content, created_at
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at DESC LIMIT 10;
```
Expected: All 10 messages (5 user + 5 AI) in chronological order

---

### Test 5.2: Simultaneous Updates (Multi-Tab)

**Test Steps:**
1. Open same conversation in 2 browser tabs
2. Send message from Tab 1
3. Send different message from Tab 2 immediately
4. Verify both messages handled

**Expected Results:**
- ✅ Both messages stored
- ✅ Both receive AI responses
- ✅ Both tabs show all messages
- ✅ No data loss
- ✅ Correct message sequence

---

### Test 5.3: Token Count Update Conflicts

**Test Steps:**
1. Send multiple messages rapidly
2. Check total_tokens update accuracy

**Expected Results:**
- ✅ Total tokens accurately accumulated
- ✅ No lost updates
- ✅ Database consistency maintained

**Database Verification:**
```sql
SELECT
  c.id,
  c.total_tokens as conversation_total,
  SUM(m.input_tokens + m.output_tokens) as messages_sum
FROM ai_conversations c
JOIN ai_messages m ON m.conversation_id = c.id
WHERE c.id = '[conversation-id]'
GROUP BY c.id, c.total_tokens;
```
Expected: `conversation_total` = `messages_sum`

---

## Test Suite 6: Authentication Failures

### Test 6.1: Expired Firebase Token

**Setup:**
1. Logout and login to get fresh token
2. Wait for token to expire (usually 1 hour)
3. OR manually invalidate token

**Test Steps:**
1. After token expiration, attempt to send message
2. Verify authentication re-prompt

**Expected Results:**
- ✅ Error: "Session expired. Please login again."
- ✅ Redirect to login page
- ✅ After re-login, conversation still accessible
- ✅ Message history preserved

---

### Test 6.2: Invalid User ID

**Test Steps:**
1. Attempt to create conversation with non-existent user ID (via API)
2. Verify validation

**Expected Results:**
- ✅ Request rejected
- ✅ Error: "Invalid user"
- ✅ No conversation created

**Edge Function Logs:**
```bash
npx supabase functions logs bedrock-ai-chat --tail
```
Should show: "User not found" error

---

### Test 6.3: Missing Authorization Header

**Test Steps (Direct API):**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"test","userId":"test","message":"test","conversationHistory":[]}'
```

**Expected Results:**
- ✅ 401 Unauthorized error
- ✅ Response: "Authorization header required"
- ✅ No data processing

---

## Test Suite 7: Resource Exhaustion

### Test 7.1: Maximum Conversation History

**Test Steps:**
1. Create conversation with 200+ messages
2. Send new message
3. Verify system handles large history

**Expected Results:**
- ✅ AI responds (may be slower)
- ✅ History truncated to last N messages if needed
- ✅ No memory errors
- ✅ Response time < 10 seconds

**Database Verification:**
```sql
SELECT COUNT(*) FROM ai_messages
WHERE conversation_id = '[conversation-id]';
```

---

### Test 7.2: Maximum Token Limit Per Message

**Test Steps:**
1. Send extremely long detailed question (5000+ tokens estimated)
2. Verify token limit handling

**Expected Results:**
- ✅ Either:
  - Request succeeds with truncated history, OR
  - Error: "Message too complex. Please simplify."
- ✅ No system crash
- ✅ Cost limits enforced

---

### Test 7.3: Database Connection Pool Exhaustion

**Test Steps:**
1. Simulate 50+ concurrent users (if load testing tools available)
2. Monitor database connections

**Expected Results:**
- ✅ Connection pooling works
- ✅ Requests queued if pool full
- ✅ Eventual consistency
- ✅ No permanent failures

**Monitor:**
```sql
SELECT count(*) FROM pg_stat_activity WHERE datname = 'postgres';
```

---

## Test Suite 8: Malformed Data Handling

### Test 8.1: Invalid JSON in Request

**Test Steps (Direct API):**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [token]" \
  -H "Content-Type: application/json" \
  -d '{invalid json here'
```

**Expected Results:**
- ✅ 400 Bad Request error
- ✅ Response: "Invalid request format"
- ✅ No processing attempted

---

### Test 8.2: Missing Required Fields

**Test Steps:**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer [token]" \
  -H "Content-Type: application/json" \
  -d '{"conversationId":"test"}'
```

**Expected Results:**
- ✅ 400 Bad Request
- ✅ Response: "Missing required field: userId, message"
- ✅ Clear error message

---

### Test 8.3: Invalid UUID Format

**Test Steps:**
1. Create conversation with malformed UUID: "not-a-uuid-123"
2. Verify validation

**Expected Results:**
- ✅ Request rejected
- ✅ Error: "Invalid conversation ID format"
- ✅ No database insert attempted

---

## Test Suite 9: Edge Function Error Propagation

### Test 9.1: Lambda Function Returns Error

**Test Steps:**
1. Monitor Edge Function logs
2. Send message that causes Lambda error (if possible)
3. Verify error handling

**Expected Results:**
- ✅ Edge Function catches Lambda error
- ✅ User sees: "AI service error. Please try again."
- ✅ Error logged with details
- ✅ No raw Lambda error exposed to user

**Edge Function Logs:**
```bash
npx supabase functions logs bedrock-ai-chat --tail
```
Look for: "Lambda invocation error" with details

---

### Test 9.2: Bedrock AI Rate Limit Exceeded

**Test Steps:**
1. Send many messages rapidly to trigger rate limit
2. Verify throttling behavior

**Expected Results:**
- ✅ Error: "Service temporarily busy. Please wait a moment."
- ✅ Exponential backoff implemented
- ✅ User can retry after delay
- ✅ No data loss

---

### Test 9.3: Bedrock AI Returns Invalid Response

**Test Steps:**
1. Monitor for rare cases of malformed AI response
2. Verify handling

**Expected Results:**
- ✅ Edge Function validates response
- ✅ User sees: "Invalid AI response. Please try again."
- ✅ No partial response displayed
- ✅ Error logged for debugging

---

## Troubleshooting Common Issues

### Issue 1: Error Messages Not User-Friendly

**Symptom:** Users see technical error messages like "PostgreSQL constraint violation"

**Root Cause:** Error handling not catching all error types

**Solution:**
- Check Edge Function error handling wraps all errors
- Ensure user-facing messages are generic and helpful
- Log technical details separately for debugging

**Fix Location:** `supabase/functions/bedrock-ai-chat/index.ts` error handlers

---

### Issue 2: Messages Lost During Network Failure

**Symptom:** User's message disappears after network error

**Root Cause:** Input field cleared before confirmation of send

**Solution:**
- Only clear input after successful API response
- Keep message in input on error
- Implement draft saving (local storage)

**Fix Location:** Flutter message send handler (custom action or widget)

---

### Issue 3: Duplicate Messages After Retry

**Symptom:** Retrying failed send creates duplicate messages

**Root Cause:** Idempotency not implemented

**Solution:**
- Add idempotency keys to requests
- Check for duplicate before insert
- Implement client-side duplicate detection

**Database Fix:**
```sql
-- Add unique constraint on combination
ALTER TABLE ai_messages ADD CONSTRAINT unique_message_attempt
UNIQUE (conversation_id, content, created_at);
```

---

### Issue 4: Timeout Errors Too Frequent

**Symptom:** Many messages timing out

**Root Cause:** Lambda timeout too low or Bedrock AI slow

**Solution:**
- Increase Lambda timeout from 30s to 60s
- Optimize conversation history size
- Implement streaming for long responses

**CloudFormation Update:**
```yaml
Timeout: 60  # Increase from 30
```

---

### Issue 5: RLS Errors When Accessing Conversations

**Symptom:** "permission denied for table ai_conversations"

**Root Cause:** User trying to access another user's conversation

**Solution:**
- Verify RLS policies correct
- Check user_id matches authenticated user
- Ensure service_role used for Edge Functions

**Database Check:**
```sql
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'ai_conversations';
```

---

## Success Criteria

All Phase 6 tests pass if:
- [ ] Network failures show user-friendly error messages
- [ ] Users can retry after errors without data loss
- [ ] Invalid input properly validated before API calls
- [ ] Empty/whitespace messages rejected
- [ ] Special characters and SQL injection attempts handled safely
- [ ] API timeouts handled gracefully (30s max)
- [ ] Database constraints prevent invalid data
- [ ] Concurrent operations don't cause data corruption
- [ ] Authentication failures prompt re-login without data loss
- [ ] Large conversations (200+ messages) still functional
- [ ] Malformed requests return clear error messages
- [ ] Edge Function errors don't expose technical details to users
- [ ] Rate limiting implemented for AI service
- [ ] All errors logged for debugging
- [ ] No application crashes under any error condition

---

## Next Phase

Once Phase 6 (Error Handling) is complete, proceed to:

**Phase 7:** Performance and Load Testing
- Response time benchmarks (target: <3s average)
- Concurrent user simulation (50+ users)
- Database query optimization
- Lambda cold start mitigation
- Message list rendering performance
- Memory usage profiling
- Network payload optimization

---

**Phase Status:** Ready for manual execution
**Estimated Testing Time:** 3-4 hours
**Required Tools:** Browser DevTools, network throttling, API testing tools (curl/Postman)
**Risk Level:** Medium (involves intentional error generation)

**Last Updated:** December 18, 2025
**Related Guides:**
- `AI_CHAT_ROLE_BASED_TEST_GUIDE.md` (Phase 2)
- `AI_CHAT_MESSAGE_TESTING_GUIDE.md` (Phase 3)
- `AI_CHAT_MULTILINGUAL_TEST_GUIDE.md` (Phase 4)
- `AI_CHAT_PERSISTENCE_TEST_GUIDE.md` (Phase 5)
