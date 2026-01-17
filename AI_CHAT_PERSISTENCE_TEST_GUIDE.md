# AI Chat Conversation Persistence & History Testing Guide

**Date:** December 18, 2025
**Phase:** 5 of 9
**Status:** Ready for Testing
**Prerequisites:** Phases 1-4 completed

---

## Overview

This phase validates that AI chat conversations persist correctly across sessions, devices, and time. Tests cover conversation creation, retrieval, message history loading, and metadata accuracy.

---

## Test Suite 1: Conversation Creation and Retrieval

### Test 1.1: Create New Conversation

**Setup:**
1. Login as any user role (patient, provider, admin)
2. Navigate to AI Chat feature

**Test Steps:**
1. Click "Start New Chat" button
2. Note the conversation ID from URL or logs
3. Send 3 messages in the conversation
4. Navigate away from chat page
5. Return to chat page with same conversation ID

**Expected Results:**
- ✅ New conversation created with unique UUID
- ✅ All 3 messages visible after returning
- ✅ Messages in correct chronological order
- ✅ No duplicate messages
- ✅ Conversation metadata accurate (message count, tokens)

**Database Verification:**
```sql
SELECT
  id,
  patient_id,
  conversation_title,
  total_messages,
  total_tokens,
  status,
  created_at,
  updated_at
FROM ai_conversations
WHERE id = '[conversation-id]'
ORDER BY created_at DESC;
```

Expected:
- `total_messages` = 6 (3 user + 3 AI)
- `status` = 'active'
- `updated_at` > `created_at`

---

### Test 1.2: Multiple Concurrent Conversations

**Test Steps:**
1. Create conversation A, send 2 messages
2. Create conversation B, send 2 messages
3. Return to conversation A, send 1 more message
4. Return to conversation B, send 1 more message
5. Navigate to conversation history/list page

**Expected Results:**
- ✅ Both conversations listed separately
- ✅ Conversation A has 6 messages (4 user + 2 AI, then 2 more)
- ✅ Conversation B has 6 messages
- ✅ Messages not mixed between conversations
- ✅ Most recently updated conversation at top of list

**Database Verification:**
```sql
SELECT
  id,
  conversation_title,
  total_messages,
  updated_at
FROM ai_conversations
WHERE patient_id = '[user-id]'
ORDER BY updated_at DESC;
```

Expected:
- 2 distinct conversation IDs
- Most recent `updated_at` is from last message sent
- Correct `total_messages` for each

---

### Test 1.3: Conversation Across Browser Sessions

**Test Steps:**
1. Login and create conversation with 5 messages
2. Close browser completely
3. Reopen browser
4. Login with same credentials
5. Navigate to conversation history
6. Open the conversation created in step 1

**Expected Results:**
- ✅ Conversation appears in history list
- ✅ All 5 messages load correctly
- ✅ Can send new message and continue conversation
- ✅ Message order preserved
- ✅ No session-related errors

**Database Verification:**
```sql
SELECT COUNT(*) as message_count
FROM ai_messages
WHERE conversation_id = '[conversation-id]';
```

Expected: `message_count` = 10 (5 user + 5 AI)

---

## Test Suite 2: Message History Loading

### Test 2.1: Load Conversation with 10+ Messages

**Setup:**
1. Create conversation
2. Send 15 messages (resulting in 30 total with AI responses)

**Test Steps:**
1. Navigate away from conversation
2. Return to conversation page
3. Observe load time and UI behavior

**Expected Results:**
- ✅ All 30 messages load within 2 seconds
- ✅ Messages display in chronological order (oldest first)
- ✅ No loading errors or timeouts
- ✅ Scroll position at bottom (most recent message)
- ✅ UI remains responsive during load

**Performance Criteria:**
- Load time < 2 seconds for 30 messages
- Load time < 5 seconds for 100+ messages
- No UI freezing or stuttering

---

### Test 2.2: Message Pagination (100+ Messages)

**Setup:**
1. Create conversation with 150 messages (75 user + 75 AI)

**Test Steps:**
1. Open conversation
2. Scroll to top to trigger pagination
3. Observe loading behavior

**Expected Results:**
- ✅ Initial load shows last 20-50 messages
- ✅ Scrolling up loads older messages (lazy loading)
- ✅ No duplicate messages after pagination
- ✅ Smooth scrolling experience
- ✅ "Load More" button or automatic loading works

**Database Query:**
```sql
-- Verify total message count
SELECT COUNT(*) as total_messages
FROM ai_messages
WHERE conversation_id = '[conversation-id]';

-- Verify pagination works
SELECT id, created_at, content
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at ASC
LIMIT 20 OFFSET 0;  -- First page

SELECT id, created_at, content
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at ASC
LIMIT 20 OFFSET 20;  -- Second page
```

---

### Test 2.3: Message Metadata Preservation

**Test Steps:**
1. Send message in English
2. Send message in Swahili (multilingual)
3. Close and reopen conversation
4. Verify all message metadata

**Expected Results:**
- ✅ Language codes preserved (en, sw)
- ✅ Confidence scores visible
- ✅ Token counts accurate
- ✅ Timestamps correct
- ✅ User/assistant roles preserved

**Database Verification:**
```sql
SELECT
  role,
  content,
  language_code,
  confidence_score,
  input_tokens,
  output_tokens,
  created_at
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at ASC;
```

Expected:
- First message: `language_code = 'en'`
- Second message: `language_code = 'sw'`
- All fields populated (no NULLs)

---

## Test Suite 3: Cross-Device Synchronization

### Test 3.1: Same Account, Different Devices

**Setup:**
1. Login on Device A (e.g., desktop browser)
2. Login on Device B (e.g., mobile app or different browser)

**Test Steps:**
1. On Device A: Create conversation, send 3 messages
2. On Device B: Navigate to conversation history
3. On Device B: Open the conversation
4. On Device B: Send 1 more message
5. On Device A: Refresh or reopen conversation

**Expected Results:**
- ✅ Device B shows all 3 messages from Device A
- ✅ Device A shows new message from Device B after refresh
- ✅ Total messages = 8 (4 user + 4 AI)
- ✅ No duplicate messages on either device
- ✅ Timestamps accurate

**Database Verification:**
```sql
SELECT
  id,
  role,
  LEFT(content, 30) as preview,
  created_at
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at ASC;
```

Expected: 8 distinct message IDs, correct chronological order

---

### Test 3.2: Offline Message Queue (If Applicable)

**Test Steps:**
1. Open conversation
2. Disable internet connection
3. Send message
4. Re-enable internet connection

**Expected Results:**
- ✅ Message queued while offline (or error shown)
- ✅ Message sent automatically when online
- ✅ Message appears in conversation
- ✅ No data loss

**Note:** If app doesn't support offline queuing, this test verifies proper error handling:
- ❌ Message fails with clear error: "No internet connection"
- ✅ Message remains in input field for retry

---

## Test Suite 4: Conversation Metadata Accuracy

### Test 4.1: Message Count Tracking

**Test Steps:**
1. Create new conversation (should have `total_messages = 0`)
2. Send 1 message
3. Check `total_messages` after AI responds
4. Send 4 more messages
5. Check `total_messages` again

**Expected Results:**
- ✅ After 1st message: `total_messages = 2` (1 user + 1 AI)
- ✅ After 5 messages: `total_messages = 10` (5 user + 5 AI)
- ✅ Count updates immediately after AI response
- ✅ Database count matches UI display

**Database Verification:**
```sql
SELECT
  total_messages,
  (SELECT COUNT(*) FROM ai_messages WHERE conversation_id = c.id) as actual_count
FROM ai_conversations c
WHERE c.id = '[conversation-id]';
```

Expected: `total_messages = actual_count`

---

### Test 4.2: Token Count Accumulation

**Test Steps:**
1. Create new conversation
2. Send 3 messages
3. Note token counts from AI responses
4. Calculate expected total: sum of all input_tokens + output_tokens
5. Check `ai_conversations.total_tokens`

**Expected Results:**
- ✅ `total_tokens` matches sum of message tokens
- ✅ Tokens accumulate with each message
- ✅ No token count resets or errors

**Database Verification:**
```sql
SELECT
  c.total_tokens as conversation_total,
  SUM(m.input_tokens + m.output_tokens) as messages_total
FROM ai_conversations c
LEFT JOIN ai_messages m ON m.conversation_id = c.id
WHERE c.id = '[conversation-id]'
GROUP BY c.id, c.total_tokens;
```

Expected: `conversation_total = messages_total`

---

### Test 4.3: Conversation Status Transitions

**Test Steps:**
1. Create conversation (status should be 'active')
2. Archive conversation (if feature exists)
3. Verify status changed to 'archived'
4. Close conversation (if feature exists)
5. Verify status changed to 'closed'

**Expected Results:**
- ✅ New conversations: `status = 'active'`
- ✅ Archived: `status = 'archived'`
- ✅ Closed: `status = 'closed'`
- ✅ Status transitions reflected immediately
- ✅ Archived/closed conversations still accessible

**Database Verification:**
```sql
SELECT id, status, updated_at
FROM ai_conversations
WHERE id = '[conversation-id]';
```

---

## Test Suite 5: Conversation History List

### Test 5.1: Conversation List Display

**Setup:**
1. Create 10 conversations over several days
2. Mix of active, archived, and closed conversations

**Test Steps:**
1. Navigate to conversation history/list page
2. Verify all conversations displayed
3. Check sorting order
4. Check metadata accuracy

**Expected Results:**
- ✅ All 10 conversations listed
- ✅ Sorted by `updated_at` DESC (most recent first)
- ✅ Each shows: title, message count, language, status
- ✅ Clicking conversation navigates to chat page
- ✅ Load time < 1 second for 10 conversations

**Database Verification:**
```sql
SELECT
  id,
  conversation_title,
  total_messages,
  detected_language,
  status,
  updated_at
FROM ai_conversations
WHERE patient_id = '[user-id]'
ORDER BY updated_at DESC
LIMIT 10;
```

---

### Test 5.2: Search and Filter Conversations

**Test Steps:**
1. On conversation history page, search for keyword
2. Filter by status (active only)
3. Filter by date range (last 7 days)

**Expected Results:**
- ✅ Search returns conversations with matching title or content
- ✅ Status filter shows only active conversations
- ✅ Date filter shows conversations in range
- ✅ Multiple filters can be combined
- ✅ Clear filters returns to full list

**Database Query Example:**
```sql
-- Search by title
SELECT *
FROM ai_conversations
WHERE patient_id = '[user-id]'
  AND conversation_title ILIKE '%keyword%'
ORDER BY updated_at DESC;

-- Filter by status and date
SELECT *
FROM ai_conversations
WHERE patient_id = '[user-id]'
  AND status = 'active'
  AND updated_at >= NOW() - INTERVAL '7 days'
ORDER BY updated_at DESC;
```

---

### Test 5.3: Empty State Handling

**Test Steps:**
1. Login with new user (no conversations)
2. Navigate to conversation history page

**Expected Results:**
- ✅ Empty state message: "No conversations yet"
- ✅ Call-to-action button: "Start Your First Chat"
- ✅ No error messages
- ✅ UI looks intentional, not broken

---

## Test Suite 6: Data Integrity and Recovery

### Test 6.1: Conversation Deletion (Soft Delete)

**Test Steps:**
1. Create conversation with 10 messages
2. Delete conversation
3. Check if conversation appears in history
4. Check database

**Expected Results:**
- ✅ Conversation removed from UI
- ✅ Database: `status = 'deleted'` OR row deleted with cascading message deletion
- ✅ Messages also deleted (if hard delete)
- ✅ No orphaned messages

**Database Verification:**
```sql
-- If soft delete
SELECT status FROM ai_conversations WHERE id = '[conversation-id]';
-- Expected: 'deleted' or NULL (not found)

-- Check for orphaned messages
SELECT COUNT(*) FROM ai_messages WHERE conversation_id = '[conversation-id]';
-- Expected: 0 (if hard delete) or same count (if soft delete)
```

---

### Test 6.2: Data Consistency After Error

**Test Steps:**
1. Send message
2. Simulate network failure during AI response
3. Check if partial data exists
4. Retry sending message

**Expected Results:**
- ✅ User message stored (even if AI fails)
- ✅ No partial AI responses in database
- ✅ Retry sends new message (no duplicate user messages)
- ✅ Conversation remains in consistent state

**Database Verification:**
```sql
-- Check for messages without pairs
SELECT
  conversation_id,
  COUNT(*) FILTER (WHERE role = 'user') as user_msgs,
  COUNT(*) FILTER (WHERE role = 'assistant') as ai_msgs
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
GROUP BY conversation_id;
```

Expected: `user_msgs ≈ ai_msgs` (difference ≤ 1)

---

### Test 6.3: Timestamp Accuracy

**Test Steps:**
1. Send message at known time (note system clock)
2. Check `created_at` in database
3. Send another message 5 minutes later
4. Verify timestamps are accurate and ordered

**Expected Results:**
- ✅ `created_at` matches actual send time (±2 seconds)
- ✅ Second message `created_at` > first message
- ✅ Timezone handled correctly (UTC)
- ✅ UI displays local time correctly

**Database Verification:**
```sql
SELECT
  id,
  created_at,
  created_at AT TIME ZONE 'UTC' as utc_time,
  NOW() - created_at as age
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at ASC;
```

---

## Test Suite 7: Row Level Security (RLS) Validation

### Test 7.1: User Isolation

**Test Steps:**
1. Login as User A, create conversation
2. Logout, login as User B
3. Attempt to access User A's conversation ID directly (URL manipulation)

**Expected Results:**
- ✅ User B cannot access User A's conversation
- ✅ Error message: "Conversation not found" or "Access denied"
- ✅ No conversation data leaked
- ✅ Database RLS policies enforced

**Database Verification (as authenticated User B):**
```sql
-- This should return 0 rows
SELECT * FROM ai_conversations WHERE id = '[user-a-conversation-id]';

-- User B should only see their own conversations
SELECT COUNT(*) FROM ai_conversations WHERE patient_id = '[user-b-id]';
```

---

### Test 7.2: Service Role Access

**Test Steps:**
1. Query database using Supabase service role key
2. Attempt to read all conversations across all users

**Expected Results:**
- ✅ Service role can read all conversations (bypass RLS)
- ✅ Required for Edge Functions to operate
- ✅ Service key kept secure (not exposed to client)

**Database Verification (with service role):**
```sql
-- Should return all conversations across all users
SELECT COUNT(*) FROM ai_conversations;
```

---

## Test Suite 8: Performance Benchmarks

### Test 8.1: Conversation List Load Time

**Test Setup:**
- User has 50 conversations

**Test Steps:**
1. Navigate to conversation history page
2. Measure load time

**Expected Results:**
- ✅ Load time < 1 second for 50 conversations
- ✅ No UI freezing or lag
- ✅ Pagination available if 100+ conversations

---

### Test 8.2: Message History Load Time

**Test Setup:**
- Conversation with 200 messages

**Test Steps:**
1. Open conversation
2. Measure initial load time
3. Scroll to load older messages

**Expected Results:**
- ✅ Initial load (last 20-50 messages): < 1 second
- ✅ Pagination load: < 500ms per batch
- ✅ Smooth scrolling, no jank

---

### Test 8.3: Concurrent User Load

**Test Setup:**
- Simulate 10 users accessing conversations simultaneously

**Expected Results:**
- ✅ All users receive their own data
- ✅ No cross-user data leakage
- ✅ Response times remain consistent
- ✅ Database handles concurrent reads

---

## Troubleshooting

### Issue 1: Missing Messages After Reload

**Symptoms:** Some messages disappear after closing and reopening conversation

**Possible Causes:**
1. Message insert failed silently
2. RLS policies blocking reads
3. Frontend caching issue
4. Database replication delay

**Solutions:**
1. Check database directly:
   ```sql
   SELECT COUNT(*) FROM ai_messages WHERE conversation_id = '[id]';
   ```
2. Verify RLS policies allow user to read their messages
3. Clear browser cache and reload
4. Check Supabase realtime subscription status

---

### Issue 2: Incorrect Message Count

**Symptoms:** `total_messages` doesn't match actual message count

**Possible Causes:**
1. Update trigger not firing
2. Race condition during concurrent sends
3. Manual database edits

**Solutions:**
1. Recalculate count:
   ```sql
   UPDATE ai_conversations
   SET total_messages = (
     SELECT COUNT(*) FROM ai_messages WHERE conversation_id = ai_conversations.id
   )
   WHERE id = '[conversation-id]';
   ```
2. Check Edge Function update logic
3. Add database constraint to prevent mismatches

---

### Issue 3: Conversations Not Syncing Across Devices

**Symptoms:** Messages sent on Device A don't appear on Device B

**Possible Causes:**
1. Different user accounts
2. Caching issue
3. Realtime subscription not working

**Solutions:**
1. Verify same `patient_id` on both devices
2. Force refresh on Device B
3. Check Supabase realtime subscription:
   ```javascript
   const subscription = supabase
     .from('ai_messages')
     .on('INSERT', payload => {
       console.log('New message:', payload.new);
     })
     .subscribe();
   ```

---

### Issue 4: Slow Conversation List Loading

**Symptoms:** History page takes 5+ seconds to load

**Possible Causes:**
1. Too many conversations (100+)
2. Missing database indexes
3. Complex joins or queries
4. Network latency

**Solutions:**
1. Implement pagination (20 conversations per page)
2. Add database indexes:
   ```sql
   CREATE INDEX idx_ai_conversations_patient_updated
   ON ai_conversations(patient_id, updated_at DESC);
   ```
3. Simplify query (avoid unnecessary joins)
4. Cache conversation list in app state

---

### Issue 5: Timestamps Showing Wrong Timezone

**Symptoms:** Message times off by several hours

**Possible Causes:**
1. Database stores UTC, UI displays UTC instead of local
2. Timezone conversion logic error

**Solutions:**
1. Verify database stores as UTC:
   ```sql
   SELECT created_at, created_at AT TIME ZONE 'UTC' FROM ai_messages LIMIT 1;
   ```
2. Convert to local timezone in Flutter:
   ```dart
   final localTime = utcTime.toLocal();
   ```

---

## Success Criteria

All tests pass if:

- [ ] **Conversation Creation**: New conversations created with correct metadata
- [ ] **Message Persistence**: All messages persist across sessions
- [ ] **Cross-Device Sync**: Same data visible on all devices
- [ ] **Metadata Accuracy**: Message counts, token counts, timestamps accurate
- [ ] **Conversation List**: All conversations listed with correct info
- [ ] **Search/Filter**: Filtering works correctly
- [ ] **Data Integrity**: No orphaned messages, no data loss
- [ ] **Performance**: Load times within acceptable limits
- [ ] **RLS Security**: Users isolated, service role has access
- [ ] **Error Handling**: Graceful degradation on failures

---

## Next Phase

Once Phase 5 (Persistence Testing) is complete, proceed to:

**Phase 6:** Error Handling and Edge Cases Testing
- Network failure scenarios
- Invalid input handling
- API timeout handling
- Database constraint violations
- Concurrent operation conflicts

---

**Last Updated:** December 18, 2025
**Testing Status:** ⏳ Ready for execution
**Prerequisites:** Backend verified, role assignment tested, messaging tested, multilingual tested
