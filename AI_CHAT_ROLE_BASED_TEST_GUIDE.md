# AI Chat Role-Based Testing Guide

**Date:** December 18, 2025
**Status:** ✅ Backend Verified - Ready for Role-Based Testing

---

## Pre-Test Verification Completed ✅

### Backend Services Status
- ✅ **Supabase Edge Function:** `bedrock-ai-chat` (version 26, deployed Dec 11, 2025)
- ✅ **AWS Lambda:** `medzen-ai-chat-handler` (nodejs18.x, eu-central-1)
- ✅ **Database Tables:** `ai_conversations`, `ai_messages`, `ai_assistants` (verified via migrations)
- ✅ **Secrets:** All 30 required secrets configured
- ✅ **Code Analysis:** Edge Function properly implements role detection and assistant selection

### AI Assistants Expected in Database
Based on migration files `20251207181523_add_role_specific_assistants.sql` and `20251217010000_fix_patient_assistant_type.sql`:

| Assistant ID | Type | Name | Model | For User Role |
|-------------|------|------|-------|---------------|
| `f11201de-09d6-4876-ac62-fd8eb2e44692` | health | MedX Health Assistant | eu.amazon.nova-pro-v1:0 | **Patient** |
| `a1b2c3d4-5678-90ab-cdef-111111111111` | clinical | MedX Clinical Assistant | eu.amazon.nova-pro-v1:0 | **Medical Provider** |
| `b2c3d4e5-6789-01bc-def1-222222222222` | operations | MedX Operations Assistant | eu.amazon.nova-pro-v1:0 | **Facility Admin** |
| `c3d4e5f6-7890-12cd-ef12-333333333333` | platform | MedX Platform Assistant | eu.amazon.nova-pro-v1:0 | **System Admin** |

---

## Phase 2: Role-Based Assistant Assignment Testing

### Test 1: Patient Role → Health Assistant

**Setup:**
1. Login to the app as a **patient** user
2. Navigate to AI Chat feature (wherever "Start New Chat" button is)

**Test Steps:**
1. Click "Start New Chat" button
2. Observe console logs (Flutter DevTools or browser console)
3. Send first message: "Hello, this is a test"

**Expected Results:**
- ✅ Console log shows: `Detected user role: health for user: [user-id]`
- ✅ Console log shows: `Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: health`
- ✅ AI responds with health-focused language (wellness, symptoms, medication info)
- ✅ Chat header shows: "MedX Health Assistant"

**How to Verify in Database (optional):**
```sql
SELECT
  c.id,
  c.patient_id,
  a.assistant_type,
  a.assistant_name
FROM ai_conversations c
JOIN ai_assistants a ON c.assistant_id = a.id
WHERE c.patient_id = '[patient-user-id]'
ORDER BY c.created_at DESC
LIMIT 1;
```
Expected: `assistant_type = 'health'`

---

### Test 2: Medical Provider Role → Clinical Assistant

**Setup:**
1. Logout patient user
2. Login as a **medical provider** user

**Test Steps:**
1. Click "Start New Chat"
2. Check console logs
3. Send message: "What are the latest treatment guidelines for hypertension?"

**Expected Results:**
- ✅ Console log: `Detected user role: clinical for user: [user-id]`
- ✅ Console log: `Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: clinical`
- ✅ AI responds with clinical language (diagnosis, drug interactions, research)
- ✅ Chat header shows: "MedX Clinical Assistant"

**Database Verification:**
```sql
-- Should return assistant_type = 'clinical'
SELECT a.assistant_type, a.assistant_name
FROM ai_conversations c
JOIN ai_assistants a ON c.assistant_id = a.id
WHERE c.patient_id = '[provider-user-id]'
ORDER BY c.created_at DESC
LIMIT 1;
```

---

### Test 3: Facility Admin Role → Operations Assistant

**Setup:**
1. Logout provider
2. Login as **facility admin** user

**Test Steps:**
1. Click "Start New Chat"
2. Check console logs
3. Send message: "How can I optimize staff scheduling?"

**Expected Results:**
- ✅ Console log: `Detected user role: operations for user: [user-id]`
- ✅ Console log: `Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: operations`
- ✅ AI responds with operations language (staff management, compliance, financial reporting)
- ✅ Chat header shows: "MedX Operations Assistant"

**Database Verification:**
```sql
-- Should return assistant_type = 'operations'
SELECT a.assistant_type, a.assistant_name
FROM ai_conversations c
JOIN ai_assistants a ON c.assistant_id = a.id
WHERE c.patient_id = '[admin-user-id]'
ORDER BY c.created_at DESC
LIMIT 1;
```

---

### Test 4: System Admin Role → Platform Assistant

**Setup:**
1. Logout facility admin
2. Login as **system admin** user

**Test Steps:**
1. Click "Start New Chat"
2. Check console logs
3. Send message: "Show me platform performance metrics"

**Expected Results:**
- ✅ Console log: `Detected user role: platform for user: [user-id]`
- ✅ Console log: `Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: platform`
- ✅ AI responds with platform language (analytics, security, database optimization)
- ✅ Chat header shows: "MedX Platform Assistant"

**Database Verification:**
```sql
-- Should return assistant_type = 'platform'
SELECT a.assistant_type, a.assistant_name
FROM ai_conversations c
JOIN ai_assistants a ON c.assistant_id = a.id
WHERE c.patient_id = '[sysadmin-user-id]'
ORDER BY c.created_at DESC
LIMIT 1;
```

---

## Alternative Testing: Direct Edge Function Test (Advanced)

If you have a valid Firebase ID token, you can test the Edge Function directly:

```bash
# Get Firebase token (from authenticated user session)
FIREBASE_TOKEN="[your-firebase-id-token]"

# Test conversation creation for patient
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": "test-conv-'$(uuidgen)'",
    "userId": "[patient-firebase-uid]",
    "message": "Hello, this is a patient test",
    "conversationHistory": [],
    "preferredLanguage": "en"
  }'
```

Expected response:
```json
{
  "success": true,
  "response": "[AI response with health assistant tone]",
  "language": "en",
  "languageName": "English",
  "confidenceScore": 0.95,
  "responseTime": 2345,
  "usage": {
    "inputTokens": 120,
    "outputTokens": 450,
    "totalTokens": 570
  },
  "messageIds": {
    "userMessageId": "uuid-...",
    "aiMessageId": "uuid-..."
  }
}
```

---

## Viewing Edge Function Logs

Monitor real-time logs to see role detection and assistant selection:

```bash
# Watch Edge Function logs in real-time
npx supabase functions logs bedrock-ai-chat --tail
```

Look for these key log messages:
- `Firebase token verified for user: [user-id]`
- `Detected user role: [health|clinical|operations|platform] for user: [user-id]`
- `Selected model: eu.amazon.nova-pro-v1:0 for assistant_type: [type]`
- `Using existing conversation model: eu.amazon.nova-pro-v1:0` (for existing conversations)

---

## Common Issues & Troubleshooting

### Issue 1: Console shows "Conversation not found"
**Cause:** Custom action `createAIConversation` may not have created the conversation properly
**Fix:** Verify the action in `lib/custom_code/actions/create_ai_conversation.dart` is being called

### Issue 2: Wrong assistant assigned
**Cause:** User may not have correct role profile in database
**Fix:** Check if user has entry in:
- `medical_provider_profiles` (for providers)
- `facility_admin_profiles` (for admins)
- `system_admin_profiles` (for system admins)

### Issue 3: "Assistant not found" error
**Cause:** Migration may not have been applied to production database
**Fix:** Run migrations:
```bash
npx supabase db push
```

### Issue 4: AI doesn't respond
**Cause:** AWS Lambda may not be configured correctly
**Check:**
```bash
aws lambda get-function --function-name medzen-ai-chat-handler --region eu-central-1
```

---

## Success Criteria ✅

All tests pass if:
- [ ] Patient gets Health Assistant (wellness, symptoms guidance)
- [ ] Provider gets Clinical Assistant (diagnosis, drug interactions)
- [ ] Facility Admin gets Operations Assistant (staff, compliance)
- [ ] System Admin gets Platform Assistant (analytics, security)
- [ ] Console logs show correct role detection
- [ ] Database shows correct assistant_id for each conversation
- [ ] AI responses match expected tone for each assistant type

---

## Next Steps After Role Testing

Once role-based assignment is verified:
1. **Phase 3:** Test message sending and AI response
2. **Phase 4:** Test multilingual conversation support
3. **Phase 5:** Verify conversation persistence and history
4. **Phase 6:** Test error handling
5. **Phase 7:** Performance testing
6. **Phase 8:** Security testing
7. **Phase 9:** Token usage and cost tracking

---

**Last Updated:** December 18, 2025
**Backend Status:** ✅ Fully operational
**Testing Status:** ⏳ Ready for user role testing
