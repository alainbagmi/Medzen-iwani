# AI Chat Backend Update - New UUID Architecture

**Date:** December 17, 2025
**Status:** ✅ COMPLETE
**Architecture:** Futuristic AI Chat with Role-Based Assistants

---

## Executive Summary

The MedZen AI chat backend has been successfully updated to use the new UUID-based table architecture with role-based AI assistants. All backend infrastructure is now ready for frontend integration in FlutterFlow.

### What's Ready

✅ **3 New Custom Actions Created** (Flutter → Supabase)
✅ **Supabase Edge Function Deployed** (bedrock-ai-chat)
✅ **AWS Lambda Active** (bedrock-ai-chat-handler in eu-central-1)
✅ **AWS Bedrock AI Model** (eu.amazon.nova-pro-v1:0)
✅ **Database Schema** (ai_conversations, ai_messages, ai_assistants)
✅ **4 Role-Based AI Assistants Seeded**
✅ **Row Level Security (RLS) Enabled**
✅ **Multilingual Support** (12 languages with auto-detection)

---

## New Architecture Overview

### Data Flow
```
Flutter UI (Your Frontend)
    ↓
Custom Actions (New: detectUserRole, getAssistantByType, createAIConversation)
    ↓
Supabase Database (ai_conversations, ai_messages)
    ↓
Supabase Edge Function (bedrock-ai-chat)
    ↓
AWS Lambda (bedrock-ai-chat-handler)
    ↓
AWS Bedrock AI (eu.amazon.nova-pro-v1:0)
    ↓
Response with language detection, token tracking, medical entity extraction
```

### Table Architecture (UUID-Based)

**`ai_assistants` Table** - 4 Role-Based AI Configurations
- Health Assistant → Patients (general wellness, symptom guidance)
- Clinical Assistant → Medical Providers (diagnosis, drug interactions, research)
- Operations Assistant → Facility Admins (staff management, compliance, financial)
- Platform Assistant → System Admins (analytics, security, database optimization)

**`ai_conversations` Table** - Conversation Management
- UUID-based conversation tracking
- Links to specific assistant (assistant_id)
- Tracks total messages, tokens, language
- Status management (active/closed/archived)
- Triage results and escalation flags

**`ai_messages` Table** - Message Storage
- UUID-based message records
- Rich metadata (language, confidence, tokens)
- Supports user, assistant, and system roles
- Tracks input/output token usage for cost management

---

## Custom Actions Created

### 1. `detectUserRole(userId)`
**File:** `lib/custom_code/actions/detect_user_role.dart`

**Purpose:** Automatically detects user role from profile tables

**Returns:** String - 'clinical', 'operations', 'platform', or 'health'

**Logic:**
```dart
1. Check medical_provider_profiles → 'clinical'
2. Check facility_admin_profiles → 'operations'
3. Check system_admin_profiles → 'platform'
4. Default → 'health' (patient)
```

**Usage in FlutterFlow:**
```dart
final assistantType = await detectUserRole(currentUserId);
// Returns: 'clinical', 'operations', 'platform', or 'health'
```

---

### 2. `getAssistantByType(assistantType)`
**File:** `lib/custom_code/actions/get_assistant_by_type.dart`

**Purpose:** Fetches the AI assistant UUID for a given type

**Returns:** String? - Assistant UUID or null if not found

**Usage in FlutterFlow:**
```dart
final assistantId = await getAssistantByType('clinical');
// Returns UUID like: 'a1b2c3d4-5678-90ab-cdef-111111111111'
```

---

### 3. `createAIConversation(userId, {title, language})`
**File:** `lib/custom_code/actions/create_ai_conversation.dart`

**Purpose:** One-step conversation creation with automatic role detection

**Returns:** Map with:
- `success` (bool)
- `conversationId` (String UUID)
- `assistantType` (String)
- `assistantId` (String UUID)
- `error` (String, if failed)

**Usage in FlutterFlow:**
```dart
final result = await createAIConversation(
  currentUserId,
  conversationTitle: 'New Chat',
  defaultLanguage: 'en',
);

if (result['success']) {
  final conversationId = result['conversationId'];
  // Navigate to chat page with conversationId
}
```

---

### 4. `sendBedrockMessage(...)` (Already Exists - Production Ready)
**File:** `lib/custom_code/actions/send_bedrock_message.dart`

**Purpose:** Send message to AI and get response

**Parameters:**
- `conversationId` (String) - UUID of conversation
- `userId` (String) - User ID
- `message` (String) - Message text
- `conversationHistory` (List<dynamic>) - Previous messages
- `preferredLanguage` (String?) - Optional language code

**Returns:** Map with:
```dart
{
  'success': true/false,
  'response': "AI generated text",
  'language': 'en',
  'languageName': 'English',
  'confidenceScore': 0.95,
  'responseTime': 1234,
  'inputTokens': 120,
  'outputTokens': 450,
  'totalTokens': 570,
  'userMessageId': 'uuid',
  'aiMessageId': 'uuid',
}
```

---

## Role-Based AI Assistants

### 1. Health Assistant (Patients)
- **Type:** `health`
- **ID:** `f11201de-09d6-4876-ac62-fd8eb2e44692`
- **Model:** `eu.amazon.nova-pro-v1:0`
- **Capabilities:**
  - General wellness advice
  - Symptom guidance
  - Medication information
  - Appointment scheduling
  - Health education
- **Avg Response Time:** 1500ms
- **Languages:** All 12 supported

### 2. Clinical Assistant (Medical Providers)
- **Type:** `clinical`
- **ID:** `a1b2c3d4-5678-90ab-cdef-111111111111`
- **Model:** `eu.amazon.nova-pro-v1:0`
- **Capabilities:**
  - Clinical decision support
  - Diagnosis assistance
  - Drug interaction checks
  - Medical research summaries
  - Treatment plan recommendations
- **Avg Response Time:** 1200ms
- **Languages:** All 12 supported

### 3. Operations Assistant (Facility Admins)
- **Type:** `operations`
- **ID:** `b2c3d4e5-6789-01bc-def1-222222222222`
- **Model:** `eu.amazon.nova-pro-v1:0`
- **Capabilities:**
  - Staff management guidance
  - Compliance assistance
  - Financial reporting help
  - Capacity planning
  - Resource optimization
- **Avg Response Time:** 1300ms
- **Languages:** All 12 supported

### 4. Platform Assistant (System Admins)
- **Type:** `platform`
- **ID:** `c3d4e5f6-7890-12cd-ef12-333333333333`
- **Model:** `eu.amazon.nova-pro-v1:0`
- **Capabilities:**
  - System analytics
  - Performance monitoring
  - Security analysis
  - Database optimization
  - API usage tracking
- **Avg Response Time:** 1100ms
- **Languages:** All 12 supported

---

## Multilingual Support

**12 Languages Supported:**
1. English (en)
2. French (fr)
3. Arabic (ar)
4. Swahili (sw)
5. Kinyarwanda (rw)
6. Hausa (ha)
7. Yoruba (yo)
8. Pidgin (pcm)
9. Afrikaans (af)
10. Amharic (am)
11. Sango (sg)
12. Fulfulde (ff)

**Auto-Detection:** AI automatically detects input language and responds in the same language.

**Confidence Score:** Each response includes language confidence (0.0-1.0).

---

## Database Schema Details

### ai_conversations Table
```sql
CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES users(id),
  user_id TEXT,  -- For compatibility
  assistant_id UUID REFERENCES ai_assistants(id),
  conversation_title TEXT DEFAULT 'New Conversation',
  status TEXT CHECK (status IN ('active', 'closed', 'archived')),
  total_messages INTEGER DEFAULT 0,
  total_tokens INTEGER DEFAULT 0,
  detected_language TEXT,
  default_language TEXT DEFAULT 'en',
  triage_result JSONB,
  escalated_to_provider BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### ai_messages Table
```sql
CREATE TABLE ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES ai_conversations(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  language_code TEXT,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  total_tokens INTEGER DEFAULT 0,
  confidence_score DECIMAL(3,2),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### ai_assistants Table
```sql
CREATE TABLE ai_assistants (
  id UUID PRIMARY KEY,
  assistant_name TEXT NOT NULL,
  assistant_type TEXT UNIQUE CHECK (assistant_type IN ('health', 'clinical', 'operations', 'platform')),
  description TEXT,
  model_version TEXT NOT NULL,
  system_prompt TEXT,
  capabilities TEXT[],
  icon_url TEXT,
  response_time_avg_ms INTEGER,
  model_config JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Security (Row Level Security)

**RLS Policies Enabled on All Tables:**

### ai_conversations
- ✅ Users can only SELECT their own conversations
- ✅ Users can only INSERT conversations for themselves
- ✅ Users can only UPDATE their own conversations
- ✅ Service role has full access (for Edge Functions)

### ai_messages
- ✅ Users can only SELECT messages from their conversations
- ✅ Users can only INSERT messages in their conversations
- ✅ Service role has full access

### ai_assistants
- ✅ Public SELECT access (all users can see available assistants)
- ✅ No INSERT/UPDATE/DELETE for regular users (admin only)

---

## Testing the Backend

### Test 1: Role Detection
```dart
// In FlutterFlow Custom Action
final role = await detectUserRole('user-uuid-here');
print('Detected role: $role');
// Expected: 'clinical', 'operations', 'platform', or 'health'
```

### Test 2: Get Assistant
```dart
final assistantId = await getAssistantByType('clinical');
print('Assistant ID: $assistantId');
// Expected: 'a1b2c3d4-5678-90ab-cdef-111111111111'
```

### Test 3: Create Conversation
```dart
final result = await createAIConversation(
  currentUserId,
  conversationTitle: 'Test Chat',
);
print('Result: ${result['success']}');
print('Conversation ID: ${result['conversationId']}');
```

### Test 4: Send Message
```dart
final response = await sendBedrockMessage(
  conversationId,
  userId,
  'Hello, I need medical advice',
  [],
  'en',
);
print('AI Response: ${response['response']}');
print('Tokens used: ${response['totalTokens']}');
```

---

## FlutterFlow Integration Steps

### Step 1: Create New Conversation Flow

**In FlutterFlow UI (e.g., Start Chat button):**

1. **Action 1:** Custom Action → `createAIConversation`
   - Pass: `currentUserId`
   - Save result to: Page State variable `conversationResult`

2. **Action 2:** Navigate To → Chat Page
   - Pass parameter: `conversationId` = `conversationResult['conversationId']`

### Step 2: Chat Page Load

**On page load:**

1. **Action 1:** Backend Query
   - Query: `ai_conversations` table
   - Filter: `id` = page parameter `conversationId`
   - Save to: Page State `currentConversation`

2. **Action 2:** Backend Query
   - Query: `ai_messages` table
   - Filter: `conversation_id` = page parameter `conversationId`
   - Order by: `created_at` ASC
   - Save to: Page State `messages` (List)

3. **Action 3:** Backend Query
   - Query: `ai_assistants` table
   - Filter: `id` = `currentConversation.assistant_id`
   - Save to: Page State `currentAssistant`

### Step 3: Send Message Flow

**On Send Button Click:**

1. **Action 1:** Validate input (not empty)

2. **Action 2:** Format conversation history
   ```dart
   List<Map<String, String>> history = messages.map((msg) => {
     'role': msg.role,
     'content': msg.content,
   }).toList();
   ```

3. **Action 3:** Custom Action → `sendBedrockMessage`
   - Pass: conversationId, userId, message, history, language
   - Save result to: Page State `aiResponse`

4. **Action 4:** Add user message to UI
   - Append to `messages` list:
   ```dart
   {
     'id': aiResponse['userMessageId'],
     'role': 'user',
     'content': message,
     'created_at': DateTime.now(),
   }
   ```

5. **Action 5:** Add AI response to UI
   - Append to `messages` list:
   ```dart
   {
     'id': aiResponse['aiMessageId'],
     'role': 'assistant',
     'content': aiResponse['response'],
     'language_code': aiResponse['language'],
     'confidence_score': aiResponse['confidenceScore'],
     'created_at': DateTime.now(),
   }
   ```

6. **Action 6:** Update conversation totals
   - Backend Call: UPDATE `ai_conversations`
   - Set: `total_messages` += 2
   - Set: `total_tokens` += aiResponse['totalTokens']

7. **Action 7:** Clear input field and scroll to bottom

### Step 4: Conversation List Page

**Query to show all user conversations:**

```dart
// Backend Query
Table: ai_conversations
Filter: patient_id = currentUserId
Order by: updated_at DESC
Join: ai_assistants (to get assistant name/icon)
```

**Display for each conversation:**
- Title: `conversation_title`
- Subtitle: `"${total_messages} messages • ${detected_language}"`
- Icon: Assistant icon from `ai_assistants.icon_url`
- Badge: Status (active/closed/archived)

---

## Cost Estimation

### AWS Bedrock Pricing (eu-central-1)
- **Model:** eu.amazon.nova-pro-v1:0
- **Input:** $0.80 per 1M tokens
- **Output:** $3.20 per 1M tokens

### Example Calculation (1000 users, 5 conversations/month each)
- Total conversations: 5,000
- Avg conversation: 10 messages (5 user + 5 AI)
- Avg user message: 50 tokens
- Avg AI response: 200 tokens
- Total per conversation: 1,250 tokens

**Monthly Cost:**
- Total tokens: 6,250,000
- Input tokens (40%): 2,500,000 × $0.80 = $2.00
- Output tokens (60%): 3,750,000 × $3.20 = $12.00
- **Total: ~$14/month**

### Supabase
- **Free Tier:** 500MB DB, 1GB storage, 2GB bandwidth
- **Pro Tier ($25/month):** 8GB DB, 100GB storage
- AI chat uses minimal storage (text only)
- **Likely fits in free tier for small-medium deployments**

### Total Estimated Cost
- **Small (100 users):** $1-5/month
- **Medium (1000 users):** $10-20/month
- **Large (10,000 users):** $100-200/month

---

## Monitoring & Debugging

### View Edge Function Logs
```bash
npx supabase functions logs bedrock-ai-chat --tail
```

### View AWS Lambda Logs
```bash
aws logs tail /aws/lambda/medzen-bedrock-ai-chat-handler --follow --region eu-central-1
```

### Check Database
```sql
-- Verify assistants seeded
SELECT * FROM ai_assistants ORDER BY assistant_type;

-- Check recent conversations
SELECT * FROM ai_conversations ORDER BY created_at DESC LIMIT 5;

-- Check messages
SELECT * FROM ai_messages
WHERE conversation_id = 'your-conversation-uuid'
ORDER BY created_at;

-- Check token usage
SELECT
  SUM(total_tokens) as total_tokens,
  COUNT(*) as total_conversations,
  AVG(total_messages) as avg_messages_per_conversation
FROM ai_conversations
WHERE created_at > NOW() - INTERVAL '30 days';
```

---

## Migration from Legacy Tables (Optional)

If you have existing conversations in `chat` and `conversation` tables, a migration script is available in the plan document.

**To migrate:**
1. Run migration SQL to copy data from legacy tables to new UUID tables
2. Verify counts match
3. Update all UI pages to use new queries
4. Deprecate old tables after 30-day monitoring period

---

## Key Files Reference

### Custom Actions (Flutter)
- ✅ `lib/custom_code/actions/detect_user_role.dart`
- ✅ `lib/custom_code/actions/get_assistant_by_type.dart`
- ✅ `lib/custom_code/actions/create_ai_conversation.dart`
- ✅ `lib/custom_code/actions/send_bedrock_message.dart`
- ✅ `lib/custom_code/actions/index.dart` (exports all actions)

### Backend Functions
- ✅ `supabase/functions/bedrock-ai-chat/index.ts` (Edge Function)
- ✅ AWS Lambda: `bedrock-ai-chat-handler` (eu-central-1)

### Database Migrations
- ✅ `supabase/migrations/20251119000000_seed_ai_assistants.sql`
- ✅ `supabase/migrations/20251207181523_add_role_specific_assistants.sql`
- ✅ `supabase/migrations/20251217010000_fix_patient_assistant_type.sql`
- ✅ `supabase/migrations/20251217020000_add_health_model_config.sql`

### Documentation
- 📄 `AI_CHAT_MULTI_ROLE_IMPLEMENTATION_SUMMARY.md`
- 📄 `BEDROCK_AI_IMPLEMENTATION_SUMMARY.md`
- 📄 `ROLE_BASED_AI_MODELS_IMPLEMENTATION.md`
- 📄 `/Users/alainbagmi/.claude/plans/iridescent-booping-meerkat.md` (Detailed UI plan)

---

## Next Steps (Frontend in FlutterFlow)

You mentioned you'll handle the frontend updates. Here's what you need to do in FlutterFlow:

### 1. Create Data Types
- `AIConversationRow` (fields: id, patient_id, assistant_id, conversation_title, status, total_messages, etc.)
- `AIMessageRow` (fields: id, conversation_id, role, content, language_code, tokens, etc.)
- `AIAssistantRow` (fields: id, assistant_name, assistant_type, description, icon_url, etc.)

### 2. Create Supabase Queries
- `GetUserConversations` (query ai_conversations WHERE patient_id = userId)
- `GetConversationMessages` (query ai_messages WHERE conversation_id = conversationId)
- `GetAssistantDetails` (query ai_assistants WHERE id = assistantId)

### 3. Update Pages
- **Start Chat Page:** Use `createAIConversation()` action
- **Chat Page:** Load from `ai_conversations` and `ai_messages` tables
- **History Page:** Query `ai_conversations` with joins to `ai_assistants`

### 4. Test Flow
1. User clicks "Start Chat" → creates conversation with auto role detection
2. User sends message → calls `sendBedrockMessage()`
3. AI responds → displays with language badge and token info
4. Conversation persists → user can return later

---

## Success Criteria

✅ Each user role gets the appropriate AI assistant automatically
✅ Conversations are created with UUID-based architecture
✅ Messages send and receive within 2-3 seconds
✅ Language detection works for all 12 supported languages
✅ Token usage is tracked for cost management
✅ RLS prevents unauthorized access to conversations
✅ Backend is ready for frontend integration

---

## Support

If you encounter issues:

1. **Check Custom Action Exports:**
   ```bash
   cat lib/custom_code/actions/index.dart
   ```
   Should show exports for all 4 actions.

2. **Verify Database:**
   ```sql
   SELECT COUNT(*) FROM ai_assistants;
   -- Should return 4
   ```

3. **Test Edge Function:**
   ```bash
   npx supabase functions logs bedrock-ai-chat --tail
   ```

4. **Check AWS Lambda:**
   ```bash
   aws lambda invoke \
     --function-name medzen-bedrock-ai-chat-handler \
     --region eu-central-1 \
     --payload '{"body":"{}"}' \
     response.json
   ```

---

## Conclusion

The backend is now fully equipped with the "futuristic chat app architecture" using UUID-based tables and role-based AI assistants. All 4 custom actions are ready for use in FlutterFlow. The Supabase Edge Function and AWS Lambda are active and handling role detection, assistant selection, language detection, and token tracking automatically.

**You can now proceed with frontend updates in FlutterFlow using the new custom actions and database tables.**

---

**Backend Update Status:** ✅ COMPLETE
**Frontend Integration:** 🔄 Ready for your FlutterFlow work
**Deployment:** 🚀 Production-ready
