# FlutterFlow AI Chat Quick Start Guide

**For:** Frontend developers integrating the new AI chat backend
**Backend Status:** ✅ Fully ready and tested
**Your Task:** Build UI in FlutterFlow using the new custom actions

---

## 3 Custom Actions You Can Use Now

### 1. Create New Conversation (One-Step)

```dart
// In FlutterFlow: Custom Action → createAIConversation
final result = await createAIConversation(
  currentUserId,
  conversationTitle: 'Medical Questions', // Optional
  defaultLanguage: 'en',                  // Optional
);

// Returns:
{
  'success': true,
  'conversationId': 'uuid-string',
  'assistantType': 'clinical',  // or 'health', 'operations', 'platform'
  'assistantId': 'uuid-string'
}
```

**When to use:** "Start New Chat" button click

---

### 2. Send Message to AI

```dart
// In FlutterFlow: Custom Action → sendBedrockMessage
final response = await sendBedrockMessage(
  conversationId,           // From createAIConversation or page param
  currentUserId,           // Authenticated user ID
  messageText,             // User's message
  conversationHistory,     // List of {role: 'user/assistant', content: 'text'}
  'en',                    // Language (or empty for auto-detect)
);

// Returns:
{
  'success': true,
  'response': 'AI generated response text',
  'language': 'en',
  'languageName': 'English',
  'confidenceScore': 0.95,
  'inputTokens': 120,
  'outputTokens': 450,
  'totalTokens': 570,
  'userMessageId': 'uuid',
  'aiMessageId': 'uuid'
}
```

**When to use:** Send button click in chat interface

---

### 3. Detect User Role (Advanced)

```dart
// In FlutterFlow: Custom Action → detectUserRole
final assistantType = await detectUserRole(currentUserId);

// Returns: 'clinical', 'operations', 'platform', or 'health'
```

**When to use:** Only if you need to manually check user role (rare - `createAIConversation` does this automatically)

---

## Database Tables to Query

### Get User's Conversations
```
Table: ai_conversations
Filter: patient_id = currentUserId
Order by: updated_at DESC
Select: id, conversation_title, status, total_messages, detected_language, created_at
Join: ai_assistants (for assistant_name, icon_url)
```

### Get Messages for a Conversation
```
Table: ai_messages
Filter: conversation_id = selectedConversationId
Order by: created_at ASC
Select: id, role, content, language_code, confidence_score, created_at
```

### Get Assistant Details
```
Table: ai_assistants
Filter: id = conversation.assistant_id
Select: assistant_name, assistant_type, description, icon_url
```

---

## Typical User Flow

### 1. Start New Chat

**UI Elements:**
- Button: "Start New Chat"

**Actions on Click:**
```
1. Custom Action: createAIConversation(currentUserId)
   → Saves result to: conversationResult

2. Navigate To: Chat Page
   → Pass parameter: id = conversationResult['conversationId']
```

---

### 2. Chat Page

**On Page Load:**
```
1. Backend Query: ai_conversations
   → Filter: id = page_parameter.id
   → Save to: currentConversation

2. Backend Query: ai_messages
   → Filter: conversation_id = page_parameter.id
   → Order: created_at ASC
   → Save to: messagesList

3. Backend Query: ai_assistants
   → Filter: id = currentConversation.assistant_id
   → Save to: currentAssistant
```

**Display:**
- AppBar Title: currentAssistant.assistant_name
- AppBar Subtitle: currentAssistant.assistant_type
- ListView: messagesList (user messages right, AI left)
- TextField: Message input
- Button: Send

**On Send Click:**
```
1. Validate: messageInput not empty

2. Format history:
   conversationHistory = messagesList.map((m) => {
     'role': m.role,
     'content': m.content
   }).toList()

3. Custom Action: sendBedrockMessage(
     conversationId,
     currentUserId,
     messageInput,
     conversationHistory,
     'en'
   )
   → Save to: aiResponse

4. If aiResponse['success']:
   a. Add user message to messagesList:
      {
        'id': aiResponse['userMessageId'],
        'role': 'user',
        'content': messageInput,
        'created_at': now
      }

   b. Add AI message to messagesList:
      {
        'id': aiResponse['aiMessageId'],
        'role': 'assistant',
        'content': aiResponse['response'],
        'language_code': aiResponse['language'],
        'created_at': now
      }

   c. Backend Update: ai_conversations
      → Set: total_messages += 2
      → Set: total_tokens += aiResponse['totalTokens']

   d. Clear messageInput
   e. Scroll ListView to bottom

5. Else:
   Show error: aiResponse['error']
```

---

### 3. Conversation History Page

**On Page Load:**
```
Backend Query: ai_conversations
→ Filter: patient_id = currentUserId
→ Order: updated_at DESC
→ Join: ai_assistants
→ Save to: conversationsList
```

**Display (ListView):**
```
For each conversation:
  ListTile(
    leading: Assistant icon (currentAssistant.icon_url),
    title: conversation.conversation_title,
    subtitle: '${conversation.total_messages} messages • ${conversation.detected_language}',
    trailing: Status badge (active/closed/archived),
    onTap: Navigate to Chat Page with id = conversation.id
  )
```

---

## Role-Based Assistant Display

Each user automatically gets the right assistant:

| User Role | Gets Assistant | Icon Suggestion | Color |
|-----------|---------------|-----------------|-------|
| **Patient** | Health Assistant | 🏥 Heart | Green |
| **Provider** | Clinical Assistant | 🩺 Stethoscope | Blue |
| **Facility Admin** | Operations Assistant | 🏢 Building | Orange |
| **System Admin** | Platform Assistant | ⚙️ Gear | Purple |

**No manual selection needed** - `createAIConversation()` handles this automatically!

---

## Message Bubble UI Suggestions

### User Message (Right Side)
```
Container(
  alignment: Alignment.centerRight,
  child: Container(
    background: Blue,
    textColor: White,
    borderRadius: Top-left only,
    padding: 12px,
    margin: 8px,
    child: Text(message.content)
  )
)
```

### AI Message (Left Side)
```
Container(
  alignment: Alignment.centerLeft,
  child: Column(
    crossAxisAlignment: Start,
    children: [
      Row(
        children: [
          Avatar(assistant.icon_url),
          Text(assistant.assistant_name, style: Small Bold),
        ]
      ),
      Container(
        background: LightGray,
        textColor: Black,
        borderRadius: Top-right only,
        padding: 12px,
        margin: 8px,
        child: Column(
          children: [
            Text(message.content),
            IF message.language_code != 'en':
              Chip(text: message.language_code, size: tiny)
          ]
        )
      )
    ]
  )
)
```

---

## Testing Your UI

### Test 1: Create Conversation
1. Click "Start New Chat"
2. Verify navigation to Chat page
3. Check AppBar shows correct assistant name
4. Confirm assistant icon displays

### Test 2: Send Message
1. Type "Hello, I have a medical question"
2. Click Send
3. Verify user message appears on right side
4. Wait 2-3 seconds
5. Verify AI response appears on left side
6. Check language badge if non-English

### Test 3: Role Detection
1. Login as different user roles
2. Create new chat for each role
3. Verify correct assistant assigned:
   - Patient → Health Assistant
   - Provider → Clinical Assistant
   - Admin → Operations/Platform Assistant

### Test 4: Conversation History
1. Create 3-5 conversations
2. Navigate to History page
3. Verify all conversations listed
4. Click any conversation
5. Verify messages load correctly

---

## Common FlutterFlow Queries

### Get Conversation Count
```
Table: ai_conversations
Filter: patient_id = currentUserId
Aggregate: COUNT(*)
```

### Get Total Tokens Used (Cost Tracking)
```
Table: ai_conversations
Filter: patient_id = currentUserId
Aggregate: SUM(total_tokens)
```

### Get Recent Conversations
```
Table: ai_conversations
Filter: patient_id = currentUserId AND updated_at > (now - 7 days)
Order by: updated_at DESC
Limit: 10
```

### Search Conversations by Title
```
Table: ai_conversations
Filter: patient_id = currentUserId AND conversation_title ILIKE '%search_term%'
Order by: updated_at DESC
```

---

## Performance Tips

### 1. Message Pagination
For conversations with 100+ messages, paginate:
```
Backend Query: ai_messages
Filter: conversation_id = conversationId
Order by: created_at DESC
Limit: 20
Offset: pageNumber * 20
```

### 2. Conversation History Cache
Cache conversation list in app state:
```
On first load: Fetch and store in AppState
On subsequent loads: Use cached data
On pull-to-refresh: Re-fetch
```

### 3. Debounce Send Button
Prevent double-clicks:
```
On Send Click:
1. Disable send button
2. Send message
3. Re-enable send button after response
```

---

## Styling Recommendations

### Brand Colors (Example)
```
Primary: #2563eb (Blue) - User messages
Secondary: #f3f4f6 (Light Gray) - AI messages
Accent: #10b981 (Green) - Success/active status
Error: #ef4444 (Red) - Errors
```

### Typography
```
User Message: 16px, White, Medium
AI Message: 16px, Black, Regular
Assistant Name: 14px, Gray, Bold
Timestamp: 12px, Gray, Regular
Language Badge: 10px, Blue, Medium
```

### Spacing
```
Message Padding: 12px
Message Margin: 8px vertical
ListView Padding: 16px horizontal
Input Height: 48px
Avatar Size: 40px
```

---

## Error Handling

### Network Error
```dart
if (!aiResponse['success']) {
  if (aiResponse['error'].contains('network') ||
      aiResponse['error'].contains('timeout')) {
    showSnackBar('Network error. Please check your connection.');
  }
}
```

### Unauthorized Error
```dart
if (aiResponse['error'].contains('authorized') ||
    aiResponse['error'].contains('401')) {
  showSnackBar('Session expired. Please login again.');
  navigateToLogin();
}
```

### Empty Response
```dart
if (aiResponse['response'] == null ||
    aiResponse['response'].isEmpty) {
  showSnackBar('AI response was empty. Please try again.');
}
```

---

## Data Types Needed in FlutterFlow

Create these custom data types:

### AIConversationRow
```
id: String
patient_id: String
assistant_id: String
conversation_title: String
status: String
total_messages: int
total_tokens: int
detected_language: String
created_at: DateTime
updated_at: DateTime
```

### AIMessageRow
```
id: String
conversation_id: String
role: String
content: String
language_code: String
confidence_score: double
input_tokens: int
output_tokens: int
created_at: DateTime
```

### AIAssistantRow
```
id: String
assistant_name: String
assistant_type: String
description: String
icon_url: String
capabilities: List<String>
response_time_avg_ms: int
```

---

## Ready to Build!

Everything is configured and waiting for your frontend:

✅ 3 custom actions ready
✅ Database tables populated
✅ Edge Function deployed
✅ AWS Lambda active
✅ 4 AI assistants seeded
✅ RLS security enabled
✅ 12 languages supported

**Start with:** Create a simple "Start Chat" button that calls `createAIConversation()` and navigates to a basic chat page.

**Questions?** Check `AI_CHAT_BACKEND_UPDATE_COMPLETE.md` for full technical details.

---

**Backend Status:** ✅ 100% Complete
**Your Turn:** 🎨 Build the beautiful UI in FlutterFlow!
