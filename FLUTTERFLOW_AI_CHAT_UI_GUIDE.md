# FlutterFlow AI Chat UI - Step-by-Step Implementation Guide

Complete guide to building the AI chat interface in FlutterFlow from scratch.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [Create Start Chat Page](#step-1-create-start-chat-page)
4. [Create Chat History Page](#step-2-create-chat-history-page)
5. [Create Main Chat Page](#step-3-create-main-chat-page)
6. [Create Writing Indicator Widget](#step-4-create-writing-indicator-widget)
7. [Add Custom Actions](#step-5-add-custom-actions)
8. [Wire Up Logic](#step-6-wire-up-logic)
9. [Test the Implementation](#step-7-test-the-implementation)

---

## Prerequisites

Before starting, ensure you have:

✅ FlutterFlow account with project created
✅ Supabase project connected to FlutterFlow
✅ Firebase project connected (for authentication)
✅ Database tables created: `ai_conversations`, `ai_messages`, `ai_assistants`
✅ Supabase Edge Function `bedrock-ai-chat` deployed

---

## Database Setup

### Create Supabase Tables

1. **Navigate to Supabase Dashboard** → SQL Editor

2. **Create ai_conversations table:**

```sql
CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES users(id) ON DELETE CASCADE,
  assistant_id UUID DEFAULT 'f11201de-09d6-4876-ac62-fd8eb2e44692',
  title TEXT DEFAULT 'New Conversation',
  status TEXT DEFAULT 'active',
  default_language TEXT DEFAULT 'en',
  total_tokens INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY "Users can view own conversations"
  ON ai_conversations FOR SELECT
  USING (patient_id = auth.uid());
```

3. **Create ai_messages table:**

```sql
CREATE TABLE ai_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES ai_conversations(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT,
  language_code VARCHAR(10) DEFAULT 'en',
  input_tokens INTEGER,
  output_tokens INTEGER,
  total_tokens INTEGER,
  model_used TEXT,
  response_time_ms INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY "Users can view own messages"
  ON ai_messages FOR SELECT
  USING (
    conversation_id IN (
      SELECT id FROM ai_conversations WHERE patient_id = auth.uid()
    )
  );
```

4. **In FlutterFlow:** Settings → Integrations → Supabase → Refresh Schema

---

## STEP 1: Create Start Chat Page

### 1.1 Create New Page

1. **Click Pages (left sidebar)** → `+ Add Page`
2. **Name:** `StartChat`
3. **Page Type:** Blank Page
4. **Route:** `/startChat`

### 1.2 Add Page Structure

**Widget Tree:**
```
StartChatWidget
└── Scaffold
    ├── AppBar
    │   └── Text: "AI Chat"
    └── SafeArea
        └── Align (center)
            └── Container (max-width: 670px)
                └── Column (centered)
                    ├── Image/Icon (AI logo)
                    ├── Text (title: "MedX AI")
                    ├── Text (description)
                    ├── Button ("Start New Chat")
                    └── Button ("Chat History")
```

### 1.3 Build the UI

**Step-by-step in FlutterFlow:**

1. **Scaffold Background:**
   - Select `Scaffold`
   - Properties panel → Background Color → `primaryBackground`

2. **Add AppBar:**
   - Select `Scaffold` → `+ Widget` → `AppBar`
   - AppBar Title: `Text` → "AI Chat"
   - Title Text Style: `headlineMedium`

3. **Add Body Container:**
   - Under Scaffold → `+ Widget` → `SafeArea`
   - Under SafeArea → `+ Widget` → `Align`
   - Align: `Center`
   - Under Align → `+ Widget` → `Container`
   - Container Properties:
     - Max Width: `670`
     - Padding: `24` all sides
     - Background Color: `secondaryBackground`
     - Border Radius: `12`

4. **Add Column:**
   - Under Container → `+ Widget` → `Column`
   - Column Properties:
     - Main Axis Alignment: `Center`
     - Cross Axis Alignment: `Center`
     - Main Axis Size: `Max`

5. **Add AI Logo/Icon:**
   - Under Column → `+ Widget` → `Icon`
   - Icon: `Icons.smart_toy` (or upload custom image)
   - Size: `80`
   - Color: `primary`
   - Bottom Margin: `24`

6. **Add Title:**
   - Under Column → `+ Widget` → `Text`
   - Text: "MedX AI"
   - Text Style: `titleLarge`
   - Font: `ReadexPro` (or your brand font)
   - Bottom Margin: `16`

7. **Add Description:**
   - Under Column → `+ Widget` → `Text`
   - Text: "Your trusted healthcare assistant. Ask me anything about your health, symptoms, or medications."
   - Text Style: `bodyMedium`
   - Font: `NotoSerif`
   - Text Align: `Center`
   - Line Height: `1.6`
   - Bottom Margin: `32`

8. **Add "Start New Chat" Button:**
   - Under Column → `+ Widget` → `Button`
   - Button Text: "Start New Chat"
   - Button Type: `Elevated`
   - Button Style:
     - Background Color: `primary`
     - Text Color: `white`
     - Border Radius: `8`
     - Padding: `16` vertical, `24` horizontal
   - Width: `200`
   - Bottom Margin: `16`

9. **Add "Chat History" Button:**
   - Under Column → `+ Widget` → `Button`
   - Button Text: "Chat History"
   - Button Type: `Outlined`
   - Button Style:
     - Border Color: `primary`
     - Text Color: `primary`
     - Border Radius: `8`
     - Padding: `16` vertical, `24` horizontal
   - Width: `200`

### 1.4 Add Page State

1. **Select Page** (top of widget tree)
2. **State Management Panel** (right side) → `+ Add Field`
3. **Field Name:** `createChatResult`
4. **Field Type:** `Supabase Row`
5. **Table:** `ai_conversations`
6. **Nullable:** Yes

---

## STEP 2: Create Chat History Page

### 2.1 Create Page

1. **Pages** → `+ Add Page`
2. **Name:** `HistoryPage`
3. **Route:** `/historyPage`
4. **Page Type:** Blank

### 2.2 Add UI Structure

**Widget Tree:**
```
HistoryPageWidget
└── Scaffold
    ├── AppBar
    │   ├── IconButton (back)
    │   └── Text: "Previous Conversations"
    └── SafeArea
        └── Container (padding: 16)
            └── ListView (from Supabase query)
                └── Container (for each chat)
                    └── ListTile
                        ├── Title: chat.title
                        ├── Subtitle: chat.created_at
                        └── onTap: Navigate to ChatWidget
```

### 2.3 Build the UI

1. **Add AppBar:**
   - Scaffold → `+ Widget` → `AppBar`
   - Leading: `IconButton` → Icon: `Icons.close`
   - Title: `Text` → "Previous Conversations"

2. **Add Container:**
   - Scaffold Body → `+ Widget` → `SafeArea`
   - SafeArea → `+ Widget` → `Container`
   - Padding: `16` all sides
   - Max Height: `500`

3. **Add ListView with Supabase Query:**
   - Container → `+ Widget` → `ListView`
   - ListView Type: `Dynamic`
   - **Backend Query:**
     - Click `Generate Dynamic Children`
     - Query Type: `Supabase Query`
     - Table: `ai_conversations`
     - Query:
       ```
       .eq('patient_id', currentUser.id)
       .order('updated_at', ascending: false)
       ```
   - **Variable Name:** `conversationItem`

4. **Add List Item Container:**
   - ListView → `+ Widget` → `Container`
   - Background: `primaryBackground`
   - Border Radius: `8`
   - Padding: `12` all sides
   - Bottom Margin: `8`

5. **Add Column in Container:**
   - Container → `+ Widget` → `Column`
   - Cross Axis Alignment: `Start`

6. **Add Title Text:**
   - Column → `+ Widget` → `Text`
   - Text: `conversationItem.title` (from variable)
   - Text Style: `titleMedium`
   - Bottom Margin: `4`

7. **Add Timestamp Text:**
   - Column → `+ Widget` → `Text`
   - Text: `conversationItem.created_at` (from variable)
   - Text Style: `bodySmall`
   - Color: `secondaryText`

8. **Add Tap Action to Container:**
   - Select Container (list item)
   - Actions Panel → `+ Add Action`
   - Action: `Navigate To`
   - Page: `ChatWidget`
   - **Pass Parameters:**
     - `conversationId`: `conversationItem.id`

---

## STEP 3: Create Main Chat Page

This is the most complex page. Follow carefully!

### 3.1 Create Page

1. **Pages** → `+ Add Page`
2. **Name:** `Chat`
3. **Route:** `/chat`
4. **Page Type:** Blank

### 3.2 Add Page Parameters

1. **Select Page** → Parameters Panel
2. **Add Parameter:**
   - Name: `conversationId`
   - Type: `String`
   - Required: `Yes`

### 3.3 Add Page State Variables

1. **State Management Panel** → Add these fields:

| Field Name | Type | Nullable | Default |
|------------|------|----------|---------|
| `conversationList` | List of Supabase Rows (`ai_messages`) | No | Empty List |
| `isLoading` | Boolean | No | `false` |
| `conversationListResult` | List of Supabase Rows (`ai_messages`) | Yes | `null` |
| `bedrockMessageResult` | JSON | Yes | `null` |

### 3.4 Build Chat UI Structure

**Widget Tree:**
```
ChatWidget
└── Scaffold
    ├── AppBar
    │   ├── Leading: Row
    │   │   ├── Image (AI avatar 40x40)
    │   │   └── Text: "MedX AI"
    │   ├── Actions: [
    │   │   ├── IconButton (refresh)
    │   │   └── IconButton (back)
    │   ]
    └── SafeArea
        └── Row (responsive)
            ├── SideNavWidget (if desktop)
            └── Expanded
                └── Column
                    ├── Container (message list, height: 565)
                    │   └── ListView (conversationList)
                    │       └── Row (for each message)
                    │           ├── Avatar (50x50)
                    │           └── Message Bubble
                    ├── Row (input area)
                    │   ├── Expanded → TextField
                    │   └── IconButton (send)
                    └── MainBottomNav (if mobile)
```

### 3.5 Build the AppBar

1. **Add AppBar:**
   - Scaffold → `+ Widget` → `AppBar`
   - Background Color: `secondaryBackground`

2. **AppBar Leading - Avatar Row:**
   - AppBar Leading → `+ Widget` → `Row`
   - Row → `+ Widget` → `Container`
     - Width: `40`, Height: `40`
     - Border Radius: `20` (circle)
     - Background Color: `primary`
   - Container → `+ Widget` → `Icon`
     - Icon: `Icons.smart_toy`
     - Size: `24`
     - Color: `white`
   - Row → `+ Widget` → `Text`
     - Text: "MedX AI"
     - Text Style: `titleMedium`
     - Left Margin: `8`

3. **AppBar Actions - Buttons:**
   - AppBar Actions → `+ Widget` → `IconButton`
     - Icon: `Icons.refresh`
     - Color: `primary`
   - AppBar Actions → `+ Widget` → `IconButton`
     - Icon: `Icons.arrow_back`
     - Color: `secondaryText`

### 3.6 Build Message List

1. **Add SafeArea:**
   - Scaffold Body → `+ Widget` → `SafeArea`

2. **Add Conditional Row (Responsive):**
   - SafeArea → `+ Widget` → `Row`
   - Add **SideNavWidget** (if width >= 1170) - this is your existing nav component
   - Add `Expanded` widget for main content

3. **Add Column:**
   - Expanded → `+ Widget` → `Column`
   - Main Axis Size: `Max`

4. **Add Message List Container:**
   - Column → `+ Widget` → `Container`
   - Height: `565.3`
   - Padding: `16` horizontal

5. **Add ListView with State Variable:**
   - Container → `+ Widget` → `ListView`
   - ListView Type: `Dynamic`
   - **Data Source:**
     - Type: `Page State`
     - Variable: `conversationList`
   - **Item Variable Name:** `conversationItem`
   - **Scroll Controller:** Create new → Name: `messagesListController`

6. **Add Message Row (conditional based on index):**
   - ListView → `+ Widget` → `Conditional Builder`
   - **Condition:** `conversationItemIndex % 2 != 0` (odd = AI message)
   - **If True:** AI Message Layout (left-aligned)
   - **If False:** User Message Layout (right-aligned)

### 3.7 Build AI Message Layout (Left-Aligned)

**Under "If True" branch:**

1. **Add Row:**
   - Alignment: `Start`
   - Bottom Margin: `12`

2. **Add Avatar Container:**
   - Row → `+ Widget` → `Container`
   - Width: `50`, Height: `50`
   - Border Radius: `25`
   - Background Color: `primary`
   - Container → `+ Widget` → `Icon`
     - Icon: `Icons.smart_toy`
     - Color: `white`
     - Size: `30`
   - Right Margin: `12`

3. **Add Message Bubble Container:**
   - Row → `+ Widget` → `Container`
   - **Constraints:**
     - Max Width: Conditional Expression
       - If `MediaQuery.width >= 1170`: `700`
       - Else If `MediaQuery.width >= 470`: `530`
       - Else: `260`
   - Background Color: `secondaryBackground`
   - **Border:**
     - Width: `2`
     - Color: `primary`
   - **Border Radius:**
     - Top Left: `12`
     - Top Right: `12`
     - Bottom Right: `12`
     - Bottom Left: `0` (pointed corner)
   - Padding: `12` all sides

4. **Add Conditional Content:**
   - Container → `+ Widget` → `Conditional Builder`
   - **Condition:** `conversationItem.content != null && conversationItem.content != ''`

   **If content exists:**
   - Add `Text` widget
   - Text: `conversationItem.content`
   - Font: `Lato`
   - Size: `16`
   - Line Height: `1.5`
   - Selectable: `true` (wrap in SelectionArea)

   **If content is empty:**
   - Add `WritingIndicatorWidget` (we'll create this later)

### 3.8 Build User Message Layout (Right-Aligned)

**Under "If False" branch:**

1. **Add Row:**
   - Alignment: `End`
   - Bottom Margin: `12`

2. **Add Message Bubble Container:**
   - Same max-width logic as AI message
   - Background Color: `secondaryBackground`
   - **Border:**
     - Width: `1`
     - Color: `alternate`
   - **Border Radius:**
     - Top Left: `12`
     - Top Right: `12`
     - Bottom Left: `12`
     - Bottom Right: `0` (pointed corner)
   - Padding: `12` all sides
   - **Content:**
     - Text: `conversationItem.content`
     - Font: `Lato`
     - Size: `16`

3. **Add Avatar:**
   - Row → `+ Widget` → `Container`
   - Width: `50`, Height: `50`
   - Border Radius: `25`
   - Left Margin: `12`
   - **Content:** Network Image
     - Image Path: `currentUser.photoUrl`
     - Fit: `Cover`

### 3.9 Build Input Area

1. **Add Input Row:**
   - Column (after message container) → `+ Widget` → `Padding`
   - Padding: `16` horizontal, `8` vertical
   - Padding → `+ Widget` → `Row`

2. **Add TextField:**
   - Row → `+ Widget` → `Expanded`
   - Expanded → `+ Widget` → `TextFormField`
   - **Properties:**
     - Hint Text: "Type something ..."
     - Border Style: `Outline`
     - Border Radius: `8`
     - Background Color: `secondaryBackground`
     - Read Only: Bind to `isLoading` state variable
     - Text Input Action: `Send`
   - **Create Controller:**
     - Name: `promptTextFieldTextController`
   - **Create Focus Node:**
     - Name: `promptTextFieldFocusNode`

3. **Add Send Button:**
   - Row → `+ Widget` → `IconButton`
   - Icon: `Icons.send`
   - Icon Size: `25`
   - Icon Color: `primary`
   - Left Margin: `8`
   - Show Loading Indicator: `true`

---

## STEP 4: Create Writing Indicator Widget

### 4.1 Create Custom Widget

1. **Components** (left sidebar) → `+ Create Component`
2. **Name:** `WritingIndicator`
3. **Type:** Widget

### 4.2 Build Structure

**Widget Tree:**
```
WritingIndicatorWidget
└── Container (77x32)
    └── Row
        ├── Container (dot 1, 16x16)
        ├── SizedBox (width: 8)
        ├── Container (dot 2, 16x16)
        ├── SizedBox (width: 8)
        └── Container (dot 3, 16x16)
```

### 4.3 Build the Widget

1. **Add Container:**
   - Width: `77`
   - Height: `32`
   - Alignment: `Center`

2. **Add Row:**
   - Main Axis Alignment: `Center`
   - Cross Axis Alignment: `Center`

3. **Add Dot 1:**
   - Row → `+ Widget` → `Container`
   - Width: `16`, Height: `16`
   - Background Color: `secondaryText`
   - Border Radius: `8` (circle)

4. **Add Spacer:**
   - Row → `+ Widget` → `SizedBox`
   - Width: `8`

5. **Add Dot 2:**
   - Same as Dot 1

6. **Add Spacer:**
   - Width: `8`

7. **Add Dot 3:**
   - Same as Dot 1

### 4.4 Add Animations

For each dot container:

1. **Select Dot Container** → Animations Panel
2. **Click `+ Add Animation`**
3. **Animation Trigger:** `On Page Load`
4. **Effects:**
   - **Scale Effect:**
     - Begin: `0.8`
     - End: `1.0`
     - Duration: `300ms`
     - Curve: `easeInOut`
   - **Fade Effect:**
     - Begin: `0.7`
     - End: `1.0`
     - Duration: `300ms`
   - **Set Loop:** `true`

5. **Stagger the animations:**
   - Dot 1: Delay `0ms`
   - Dot 2: Delay `300ms`
   - Dot 3: Delay `600ms`

---

## STEP 5: Add Custom Actions

### 5.1 Create createBedrockConversation Action

1. **Custom Code** (left sidebar) → **Actions** → `+ New Action`
2. **Action Name:** `createBedrockConversation`
3. **Return Type:** `String` (nullable)
4. **Parameters:**
   - `patientId` (String, required)
   - `title` (String, optional)

5. **Code:**

```dart
import 'package:uuid/uuid.dart';

Future<String?> createBedrockConversation(
  String patientId,
  String? title,
) async {
  try {
    final conversationId = const Uuid().v4();

    await SupaFlow.client.from('ai_conversations').insert({
      'id': conversationId,
      'patient_id': patientId,
      'assistant_id': 'f11201de-09d6-4876-ac62-fd8eb2e44692',
      'title': title ?? 'New Conversation',
      'status': 'active',
      'default_language': 'en',
      'total_tokens': 0,
    });

    return conversationId;
  } catch (e) {
    debugPrint('Error creating conversation: $e');
    return null;
  }
}
```

6. **Add Dependencies:**
   - Go to **Settings** → **Dependencies** → Add `uuid: ^4.0.0`

### 5.2 Create sendBedrockMessage Action

1. **Custom Code** → **Actions** → `+ New Action`
2. **Action Name:** `sendBedrockMessage`
3. **Return Type:** `JSON` (nullable)
4. **Parameters:**
   - `conversationId` (String, required)
   - `userId` (String, required)
   - `message` (String, required)
   - `conversationHistory` (List\<dynamic>, optional)
   - `preferredLanguage` (String, optional)

5. **Code:**

```dart
Future<dynamic> sendBedrockMessage(
  String conversationId,
  String userId,
  String message,
  List<dynamic>? conversationHistory,
  String? preferredLanguage,
) async {
  try {
    // Format conversation history
    final formattedHistory = conversationHistory?.map((msg) {
      return {
        'role': msg['type'] ?? msg['role'],
        'content': msg['content'] ?? '',
      };
    }).toList() ?? [];

    // Call Supabase Edge Function
    final response = await SupaFlow.client.functions.invoke(
      'bedrock-ai-chat',
      body: {
        'message': message,
        'conversationId': conversationId,
        'userId': userId,
        'conversationHistory': formattedHistory,
        'preferredLanguage': preferredLanguage ?? 'en',
      },
    );

    // Check HTTP status
    if (response.status >= 400) {
      debugPrint('Edge function error: HTTP ${response.status}');
      return {
        'success': false,
        'error': 'Edge function error: HTTP ${response.status}',
      };
    }

    // Parse response
    final data = response.data;
    if (data == null) {
      return {
        'success': false,
        'error': 'No data returned from Edge Function',
      };
    }

    // Return success
    if (data['success'] == true) {
      return {
        'success': true,
        'response': data['response'] ?? '',
        'language': data['language'] ?? 'en',
        'languageName': data['languageName'] ?? 'English',
        'confidenceScore': data['confidenceScore'] ?? 0.95,
        'responseTime': data['responseTime'] ?? 0,
        'inputTokens': data['usage']?['inputTokens'] ?? 0,
        'outputTokens': data['usage']?['outputTokens'] ?? 0,
        'totalTokens': data['usage']?['totalTokens'] ?? 0,
        'userMessageId': data['messageIds']?['userMessageId'],
        'aiMessageId': data['messageIds']?['aiMessageId'],
      };
    }

    return {
      'success': false,
      'error': data['error'] ?? 'Failed to get AI response',
    };
  } catch (e) {
    debugPrint('Error sending Bedrock message: $e');
    return {
      'success':