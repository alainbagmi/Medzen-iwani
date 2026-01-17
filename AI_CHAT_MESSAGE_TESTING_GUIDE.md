# AI Chat Message Sending & Response Testing Guide

**Date:** December 18, 2025
**Status:** Phase 3 Testing - Ready for Execution
**Prerequisites:** ✅ Phase 1 Complete (Backend Verified), ⏳ Phase 2 In Progress (Role-Based Testing)

---

## Overview

This guide covers **Phase 3: Message Sending and AI Response Testing** to verify the end-to-end message flow from Flutter UI → Supabase Edge Function → AWS Lambda → AWS Bedrock AI → Database storage → UI display.

---

## Test Environment Setup

### Required Tools
- MedZen app running (web, iOS, or Android)
- Browser DevTools console open (for web) or Flutter DevTools (for mobile)
- Database access (optional for verification)
- Network monitoring enabled (optional)

### Pre-Test Verification
```bash
# Verify Edge Function is responsive
npx supabase functions logs bedrock-ai-chat --tail

# Check Lambda function health (optional)
aws lambda get-function --function-name medzen-ai-chat-handler --region eu-central-1
```

---

## Test Suite 1: Basic Message Send/Response

### Test 1.1: Simple Text Message
**Objective:** Verify basic message sending and AI response

**Setup:**
1. Login to app as any user role
2. Open existing conversation OR create new conversation
3. Have browser console/DevTools open

**Test Steps:**
1. Type message: `"Hello, this is a test message"`
2. Click Send button
3. Observe UI behavior

**Expected Results:**
- ✅ User message appears on right side of chat (blue bubble)
- ✅ "Writing indicator" appears (animated dots or "AI is thinking...")
- ✅ AI response appears within 2-3 seconds on left side (gray bubble)
- ✅ Console logs show:
  ```
  Firebase token verified for user: [user-id]
  Detected user role: [health|clinical|operations|platform] for user: [user-id]
  Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: [type]
  ```
- ✅ No JavaScript errors in console
- ✅ Message persists after page refresh

**Database Verification (Optional):**
```sql
-- Check user message was stored
SELECT
  id,
  role,
  content,
  language_code,
  created_at
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
  AND role = 'user'
ORDER BY created_at DESC
LIMIT 1;

-- Check AI response was stored
SELECT
  id,
  role,
  content,
  language_code,
  input_tokens,
  output_tokens,
  confidence_score,
  created_at
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
  AND role = 'assistant'
ORDER BY created_at DESC
LIMIT 1;

-- Verify conversation stats updated
SELECT
  total_messages,
  total_tokens,
  detected_language
FROM ai_conversations
WHERE id = '[conversation-id]';
```

**Success Criteria:**
- [ ] User message displayed correctly
- [ ] AI responds within 3 seconds
- [ ] No errors in console
- [ ] Messages persist in database
- [ ] Conversation stats increment by 2 messages

---

### Test 1.2: Conversation Context Awareness
**Objective:** Verify AI maintains conversation history context

**Test Steps:**
1. Send message: `"My name is John"`
2. Wait for AI response
3. Send follow-up: `"What is my name?"`
4. Wait for AI response

**Expected Results:**
- ✅ AI remembers context and responds with "John" or "You said your name is John"
- ✅ Both exchanges complete successfully
- ✅ Conversation history properly formatted in Edge Function call

**Edge Function Log Check:**
```bash
npx supabase functions logs bedrock-ai-chat --tail
```
Look for log entry showing conversation history array with both user messages.

---

### Test 1.3: Multiple Back-and-Forth Exchanges
**Objective:** Test sustained conversation flow

**Test Steps:**
1. Send 5 messages in succession with AI responses:
   - `"What is hypertension?"`
   - `"What are the symptoms?"`
   - `"How is it treated?"`
   - `"What medications are used?"`
   - `"Are there lifestyle changes that help?"`
2. Wait for each AI response before sending next

**Expected Results:**
- ✅ All 5 exchanges complete successfully
- ✅ AI maintains medical topic context throughout
- ✅ No degradation in response time (all < 5 seconds)
- ✅ No memory/performance issues in browser
- ✅ Conversation stats show: total_messages = 10 (5 user + 5 assistant)

---

## Test Suite 2: Edge Cases and Validation

### Test 2.1: Empty Message Validation
**Objective:** Verify empty messages are rejected

**Test Steps:**
1. Leave message input field empty
2. Click Send button

**Expected Results:**
- ✅ Error message displayed: "Please enter a message"
- ✅ No API call made (check network tab - should see NO request to bedrock-ai-chat)
- ✅ Input field remains focused
- ✅ No database entries created

---

### Test 2.2: Very Long Message (>500 Characters)
**Objective:** Test handling of long user input

**Test Message (731 characters):**
```
I am experiencing persistent symptoms that have been concerning me for the past few weeks. I have been feeling unusually fatigued throughout the day, even after getting adequate sleep. Additionally, I have noticed increased thirst and frequent urination, especially at night. My vision has been slightly blurry at times, and I have experienced some tingling sensations in my hands and feet. I have also been losing weight unintentionally despite maintaining my usual eating habits. My family has a history of diabetes, and I am wondering if these symptoms could be related to blood sugar issues. I am a 45-year-old male, moderately active, with a BMI of 28. Should I be concerned about these symptoms and seek medical attention?
```

**Test Steps:**
1. Paste the long message above into input field
2. Click Send

**Expected Results:**
- ✅ Message sends successfully (no character limit error)
- ✅ Full message displays in chat bubble (may require scrolling)
- ✅ AI responds appropriately to the detailed medical inquiry
- ✅ Response acknowledges multiple symptoms mentioned
- ✅ Token count reflects longer input (input_tokens likely 150-200)

---

### Test 2.3: Special Characters and Emojis
**Objective:** Verify handling of non-standard characters

**Test Messages:**
```
1. "Hello! How are you? 😊"
2. "Test symbols: @#$%^&*()_+-={}[]|\:;"<>?,./"
3. "Unicode test: 你好 مرحبا Здравствуйте"
```

**Expected Results:**
- ✅ All messages send successfully
- ✅ Special characters and emojis display correctly in chat
- ✅ AI responds without errors
- ✅ Database stores characters correctly (UTF-8 encoding)

---

### Test 2.4: Rapid Successive Messages (Stress Test)
**Objective:** Test queueing and race condition handling

**Test Steps:**
1. Type and send 3 messages rapidly (within 2 seconds):
   - `"Message 1"`
   - `"Message 2"`
   - `"Message 3"`
2. Do NOT wait for AI responses between sends

**Expected Results:**
- ✅ All 3 messages queue properly
- ✅ All 3 user messages display in chat
- ✅ AI responds to each message in order
- ✅ No messages lost or duplicated
- ✅ No race conditions (all responses match correct prompts)
- ✅ Database shows 6 total messages (3 user + 3 assistant)

**Warning Signs to Watch For:**
- ❌ Responses out of order
- ❌ Duplicate messages
- ❌ Lost messages
- ❌ Errors in console

---

## Test Suite 3: Error Handling

### Test 3.1: Network Interruption Simulation
**Objective:** Test behavior when network connection is lost

**Test Steps:**
1. Type message: `"Testing network interruption"`
2. Open browser DevTools → Network tab
3. Click Send button
4. **Immediately** enable "Offline" mode in Network tab (before response arrives)
5. Wait 30 seconds

**Expected Results:**
- ✅ User message displays in chat
- ✅ Writing indicator appears
- ✅ After timeout (~30s), error message displays: "Network error. Please check your connection."
- ✅ User message remains in chat (not removed)
- ✅ Message input field retains sent text OR is cleared (depending on implementation)
- ✅ User can retry after re-enabling network

**Recovery Test:**
1. Re-enable network connection
2. Click Send again
3. **Expected:** Message sends successfully and AI responds

---

### Test 3.2: Invalid Conversation ID
**Objective:** Verify error handling for non-existent conversations

**Test Steps:**
1. Manually navigate to: `/chat?id=00000000-0000-0000-0000-000000000000`
2. Attempt to send message

**Expected Results:**
- ✅ Error page displays OR redirect to conversations list
- ✅ User-friendly message: "Conversation not found"
- ✅ No JavaScript errors crash the app
- ✅ Navigation remains functional

---

### Test 3.3: Unauthorized Access (Different User's Conversation)
**Objective:** Verify Row Level Security (RLS) prevents data leakage

**Test Steps:**
1. Login as User A
2. Create conversation and note conversation ID
3. Logout, login as User B
4. Try to navigate to User A's conversation ID: `/chat?id=[user-a-conversation-id]`

**Expected Results:**
- ✅ Access denied - cannot view conversation
- ✅ Error message: "You don't have permission to access this conversation"
- ✅ No conversation messages visible
- ✅ Cannot send messages to conversation

**Database RLS Verification (Optional):**
```sql
-- Simulate User B trying to access User A's conversation
SET ROLE authenticated;
SET request.jwt.claims.sub = '[user-b-id]';

SELECT * FROM ai_conversations WHERE id = '[user-a-conversation-id]';
-- Should return 0 rows due to RLS policy
```

---

## Test Suite 4: AI Response Quality

### Test 4.1: Medical Knowledge Accuracy (Clinical Assistant)
**Prerequisites:** Login as **Medical Provider**

**Test Message:**
```
"What are the latest treatment guidelines for hypertension in patients with diabetes?"
```

**Expected Results:**
- ✅ Response uses clinical/medical terminology
- ✅ Mentions evidence-based guidelines (e.g., JNC guidelines, ADA recommendations)
- ✅ Discusses medication classes (ACE inhibitors, ARBs, etc.)
- ✅ Professional, provider-focused tone
- ✅ No overly simplified patient-level explanations

**Console Log Verification:**
```
Detected user role: clinical for user: [user-id]
Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: clinical
```

---

### Test 4.2: Patient-Friendly Language (Health Assistant)
**Prerequisites:** Login as **Patient**

**Test Message:**
```
"I have high blood pressure. What does this mean for my health?"
```

**Expected Results:**
- ✅ Response uses simple, patient-friendly language
- ✅ Focuses on wellness and symptom guidance
- ✅ Avoids complex medical jargon
- ✅ Empathetic and supportive tone
- ✅ May include lifestyle advice

**Console Log Verification:**
```
Detected user role: health for user: [user-id]
Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: health
```

---

### Test 4.3: Operations Focus (Operations Assistant)
**Prerequisites:** Login as **Facility Admin**

**Test Message:**
```
"How can I optimize staff scheduling to reduce overtime costs?"
```

**Expected Results:**
- ✅ Response focuses on operational efficiency
- ✅ Mentions staff management, compliance, financial metrics
- ✅ Business/administrative tone
- ✅ May reference industry best practices
- ✅ No clinical medical advice

**Console Log Verification:**
```
Detected user role: operations for user: [user-id]
Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: operations
```

---

### Test 4.4: Platform/Technical Focus (Platform Assistant)
**Prerequisites:** Login as **System Admin**

**Test Message:**
```
"What are best practices for monitoring database performance?"
```

**Expected Results:**
- ✅ Response focuses on technical/platform topics
- ✅ Mentions analytics, monitoring, optimization
- ✅ Technical terminology appropriate for system admins
- ✅ May reference specific tools or technologies
- ✅ No medical or operational advice

**Console Log Verification:**
```
Detected user role: platform for user: [user-id]
Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: platform
```

---

## Test Suite 5: Performance Testing

### Test 5.1: Response Time Measurement
**Objective:** Verify AI response latency

**Test Steps:**
1. Send 10 test messages (any content)
2. For each message, measure time from Send click to AI response appearance
3. Calculate average, minimum, maximum response times

**Expected Results:**
- ✅ **Average response time:** < 3 seconds
- ✅ **95th percentile:** < 5 seconds
- ✅ **Maximum:** < 10 seconds
- ✅ No timeouts (30s limit)

**Measurement Tool (Browser Console):**
```javascript
// Run this before sending message
const startTime = Date.now();

// After AI response appears in chat, run:
const endTime = Date.now();
console.log(`Response time: ${(endTime - startTime) / 1000}s`);
```

---

### Test 5.2: Large Conversation History (100+ Messages)
**Objective:** Test performance with extensive history

**Prerequisites:**
- Create conversation with 100+ messages (or use existing long conversation)

**Test Steps:**
1. Open conversation with 100+ messages
2. Measure page load time
3. Send new message
4. Measure response time

**Expected Results:**
- ✅ Page loads within 3 seconds
- ✅ Chat scrolls smoothly (no lag)
- ✅ New message sends successfully
- ✅ Response time remains < 5 seconds
- ✅ No browser memory issues
- ✅ Conversation history truncated in Edge Function call (last 10-20 messages sent to AI)

**Edge Function Log Check:**
```bash
npx supabase functions logs bedrock-ai-chat --tail
```
Look for truncated history to prevent excessive token usage.

---

### Test 5.3: Concurrent Users Simulation
**Objective:** Test system under multi-user load

**Test Steps:**
1. Open 5 browser tabs/windows
2. Login as different users in each tab (or same user)
3. Send messages simultaneously from all 5 tabs
4. Observe response times and behavior

**Expected Results:**
- ✅ All messages process successfully
- ✅ No cross-contamination (User A doesn't see User B's messages)
- ✅ Response times remain acceptable (< 5s average)
- ✅ No database deadlocks or race conditions
- ✅ Edge Function handles concurrent requests

---

## Test Suite 6: Token Tracking & Cost Verification

### Test 6.1: Token Count Accuracy
**Objective:** Verify token usage tracking

**Test Steps:**
1. Send message: `"This is a short test message"` (6 words)
2. Note AI response length
3. Check database for token counts

**Database Query:**
```sql
SELECT
  content,
  input_tokens,
  output_tokens,
  (input_tokens + output_tokens) as total_tokens
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at DESC
LIMIT 2;
```

**Expected Token Ranges:**
- ✅ **Short user message (6 words):** 10-20 input tokens
- ✅ **AI response (~50 words):** 100-200 output tokens
- ✅ **Total per exchange:** 110-220 tokens

**Verify Conversation Totals:**
```sql
SELECT
  total_messages,
  total_tokens
FROM ai_conversations
WHERE id = '[conversation-id]';
```
- ✅ total_tokens should match SUM of all message tokens

---

### Test 6.2: Cost Estimation Validation
**Objective:** Verify cost tracking accuracy

**Pricing Reference (AWS Bedrock eu-central-1):**
- Input: $0.80 per 1M tokens
- Output: $3.20 per 1M tokens

**Test Steps:**
1. Create new conversation
2. Send 10 messages of varying lengths
3. Calculate expected cost

**Database Query:**
```sql
SELECT
  conversation_id,
  SUM(input_tokens) as total_input,
  SUM(output_tokens) as total_output,
  SUM(input_tokens + output_tokens) as total_tokens,
  ROUND((SUM(input_tokens) * 0.80 / 1000000)::numeric, 4) as input_cost_usd,
  ROUND((SUM(output_tokens) * 3.20 / 1000000)::numeric, 4) as output_cost_usd,
  ROUND(((SUM(input_tokens) * 0.80 / 1000000) + (SUM(output_tokens) * 3.20 / 1000000))::numeric, 4) as total_cost_usd
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
GROUP BY conversation_id;
```

**Expected Results:**
- ✅ Total cost for 10 messages: $0.001 - $0.005 (very small amount)
- ✅ Cost calculation matches manual verification
- ✅ Token counts align with message lengths

---

## Troubleshooting Guide

### Issue 1: AI Not Responding
**Symptoms:** User message sends but no AI response appears

**Debugging Steps:**
1. Check browser console for JavaScript errors
2. Check network tab - is request to `/functions/v1/bedrock-ai-chat` completing?
3. Check Edge Function logs: `npx supabase functions logs bedrock-ai-chat --tail`
4. Check Lambda CloudWatch logs (if accessible)

**Common Causes:**
- ❌ Edge Function error (check logs for stack trace)
- ❌ Lambda timeout (default 30s)
- ❌ AWS Bedrock API error
- ❌ Invalid Firebase token (user session expired)
- ❌ Network connectivity issue

**Solutions:**
- Refresh page and retry
- Logout/login to refresh Firebase token
- Check AWS service health dashboard
- Verify Supabase secrets are configured

---

### Issue 2: Messages Not Persisting
**Symptoms:** Messages disappear after page refresh

**Debugging Steps:**
1. Check database: `SELECT * FROM ai_messages WHERE conversation_id = '[id]' ORDER BY created_at DESC;`
2. Check RLS policies: User may not have SELECT permission
3. Check Edge Function logs for database insert errors

**Common Causes:**
- ❌ Database insert failed (constraint violation)
- ❌ RLS policy blocking reads
- ❌ Frontend not refreshing after send
- ❌ Conversation ID mismatch

---

### Issue 3: Slow Response Times (>10 seconds)
**Symptoms:** AI takes too long to respond

**Debugging Steps:**
1. Check Edge Function logs for processing time
2. Check Lambda CloudWatch metrics for duration
3. Check network latency (DevTools Network tab)

**Common Causes:**
- ❌ Large conversation history sent to AI (truncate to last 10 messages)
- ❌ AWS Bedrock API slow response
- ❌ Cold start Lambda execution
- ❌ Network latency

**Solutions:**
- Implement conversation history truncation in Edge Function
- Increase Lambda provisioned concurrency (reduces cold starts)
- Monitor AWS Bedrock service health

---

### Issue 4: Token Counts Incorrect
**Symptoms:** Database token counts don't match expectations

**Debugging Steps:**
1. Check Edge Function logs - are tokens returned from Lambda?
2. Verify Lambda response includes `inputTokens` and `outputTokens` fields
3. Check database schema - columns should be INTEGER type

**Common Causes:**
- ❌ Lambda not returning token usage metadata
- ❌ Edge Function not parsing token fields
- ❌ Database column type mismatch (e.g., TEXT instead of INTEGER)

---

## Success Criteria Checklist

### Basic Functionality
- [ ] User can send text messages
- [ ] AI responds within 3 seconds on average
- [ ] Messages persist after page refresh
- [ ] Conversation history maintained correctly
- [ ] No JavaScript console errors

### Edge Cases
- [ ] Empty messages rejected with user-friendly error
- [ ] Long messages (>500 chars) handled correctly
- [ ] Special characters and emojis work
- [ ] Rapid successive messages queued properly

### Error Handling
- [ ] Network errors show user-friendly messages
- [ ] Invalid conversation IDs handled gracefully
- [ ] Unauthorized access blocked by RLS
- [ ] User can retry after errors

### AI Response Quality
- [ ] Responses match user role context (health/clinical/operations/platform)
- [ ] Medical terminology appropriate for role
- [ ] Responses are coherent and relevant
- [ ] No inappropriate or unsafe content

### Performance
- [ ] Average response time < 3 seconds
- [ ] 95th percentile response time < 5 seconds
- [ ] Large conversation history (100+ messages) loads smoothly
- [ ] Concurrent users don't impact performance significantly

### Token Tracking
- [ ] Token counts accurate (±10% tolerance)
- [ ] Conversation totals match sum of message tokens
- [ ] Cost estimation calculations correct

---

## Next Steps After Phase 3

Once Phase 3 testing is complete and all success criteria are met:

1. **Phase 4:** Test multilingual conversation support (12 languages)
2. **Phase 5:** Verify conversation persistence across sessions/devices
3. **Phase 6:** Test error handling edge cases
4. **Phase 7:** Performance and load testing
5. **Phase 8:** Security and authorization testing
6. **Phase 9:** Token usage and cost optimization

---

**Last Updated:** December 18, 2025
**Testing Status:** ⏳ Ready for Execution
**Prerequisites:** Backend verified (Phase 1 ✅), Role testing in progress (Phase 2 🔄)
