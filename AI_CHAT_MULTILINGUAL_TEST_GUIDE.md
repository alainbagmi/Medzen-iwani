# AI Chat Multilingual Testing Guide (Phase 4)

**Date:** December 18, 2025
**Status:** ✅ Backend Ready - Testing 12 Language Support
**Prerequisites:** Phase 2 (Role-Based Assignment) and Phase 3 (Message Sending) completed

---

## Overview

The MedZen AI Chat system supports **12 languages** with automatic language detection and intelligent responses in the detected language. This guide covers comprehensive testing of multilingual capabilities.

**Supported Languages:**
1. English (en)
2. French (fr)
3. Swahili (sw)
4. Arabic (ar)
5. Kinyarwanda (rw)
6. Hausa (ha)
7. Yoruba (yo)
8. Nigerian Pidgin (pcm)
9. Afrikaans (af)
10. Amharic (am)
11. Sango (sg)
12. Fulfulde (ff)

**Backend Components:**
- AWS Bedrock AI: `eu.amazon.nova-pro-v1:0` (multilingual model)
- AWS Lambda: `medzen-ai-chat-handler` (language detection + translation)
- Database: `ai_messages.language_code`, `ai_messages.confidence_score`
- Edge Function: `bedrock-ai-chat` (language processing)

---

## Test Suite 1: Single Language Detection

### Test 1.1: English (Default Language)

**Objective:** Verify English messages are correctly detected and stored

**Setup:**
1. Login as any user role
2. Start new conversation (or use existing)

**Test Steps:**
1. Send message: `"What are the symptoms of hypertension?"`
2. Wait for AI response
3. Check browser console logs
4. Verify database entries

**Expected Results:**
- ✅ Console log shows: `Language detected: en` or `Language: English`
- ✅ AI responds in English with relevant medical information
- ✅ No language badge displayed (English is default)
- ✅ Database shows `language_code = 'en'`
- ✅ Confidence score ≥ 0.95

**Database Verification:**
```sql
SELECT
  id,
  role,
  content,
  language_code,
  confidence_score,
  created_at
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at DESC
LIMIT 2;
```

Expected:
```
language_code | confidence_score | content (preview)
--------------+------------------+----------------------------------
en            | 0.98             | What are the symptoms of hypertension?
en            | 0.99             | Hypertension symptoms include...
```

---

### Test 1.2: French

**Test Message:** `"Quels sont les symptômes de l'hypertension?"`

**Expected Results:**
- ✅ Language detected: `fr` (French)
- ✅ AI responds in French (e.g., "L'hypertension artérielle...")
- ✅ Language badge shows "fr" or "French"
- ✅ Database: `language_code = 'fr'`
- ✅ Confidence score ≥ 0.90

**AI Response Quality Check:**
- Medical terms in French (tension artérielle, symptômes)
- Grammatically correct French
- Professional medical tone maintained

---

### Test 1.3: Swahili

**Test Message:** `"Ni nini dalili za shinikizo la damu?"`

**Expected Results:**
- ✅ Language detected: `sw` (Swahili)
- ✅ AI responds in Swahili
- ✅ Language badge visible
- ✅ Database: `language_code = 'sw'`
- ✅ Confidence score ≥ 0.85

---

### Test 1.4: Arabic

**Test Message:** `"ما هي أعراض ارتفاع ضغط الدم؟"`

**Expected Results:**
- ✅ Language detected: `ar` (Arabic)
- ✅ AI responds in Arabic (right-to-left text)
- ✅ Language badge visible
- ✅ Database: `language_code = 'ar'`
- ✅ Confidence score ≥ 0.90

---

### Test 1.5: Kinyarwanda

**Test Message:** `"Ni iki gitera indwara y'umuvuduko w'amaraso?"`

**Expected Results:**
- ✅ Language detected: `rw` (Kinyarwanda)
- ✅ AI responds in Kinyarwanda
- ✅ Language badge visible
- ✅ Database: `language_code = 'rw'`
- ✅ Confidence score ≥ 0.80

---

### Test 1.6: Hausa

**Test Message:** `"Menene alamun hawan jini?"`

**Expected Results:**
- ✅ Language detected: `ha` (Hausa)
- ✅ AI responds in Hausa
- ✅ Language badge visible
- ✅ Database: `language_code = 'ha'`

---

### Test 1.7: Yoruba

**Test Message:** `"Kini awon ami aisan eje giga?"`

**Expected Results:**
- ✅ Language detected: `yo` (Yoruba)
- ✅ AI responds in Yoruba
- ✅ Language badge visible
- ✅ Database: `language_code = 'yo'`

---

### Test 1.8: Nigerian Pidgin

**Test Message:** `"Wetin be the signs of high blood?"`

**Expected Results:**
- ✅ Language detected: `pcm` (Pidgin)
- ✅ AI responds in Nigerian Pidgin
- ✅ Language badge visible
- ✅ Database: `language_code = 'pcm'`

---

### Test 1.9: Afrikaans

**Test Message:** `"Wat is die simptome van hipertensie?"`

**Expected Results:**
- ✅ Language detected: `af` (Afrikaans)
- ✅ AI responds in Afrikaans
- ✅ Language badge visible
- ✅ Database: `language_code = 'af'`

---

### Test 1.10: Amharic

**Test Message:** `"የደም ግፊት ምልክቶች ምንድናቸው?"`

**Expected Results:**
- ✅ Language detected: `am` (Amharic)
- ✅ AI responds in Amharic
- ✅ Language badge visible
- ✅ Database: `language_code = 'am'`

---

### Test 1.11: Sango

**Test Message:** `"Nzoni ya makila ti gonda zo?"`

**Expected Results:**
- ✅ Language detected: `sg` (Sango)
- ✅ AI responds in Sango
- ✅ Language badge visible
- ✅ Database: `language_code = 'sg'`

---

### Test 1.12: Fulfulde

**Test Message:** `"Ko hoɗi keefi yaadu?"`

**Expected Results:**
- ✅ Language detected: `ff` (Fulfulde)
- ✅ AI responds in Fulfulde
- ✅ Language badge visible
- ✅ Database: `language_code = 'ff'`

---

## Test Suite 2: Code-Mixing and Multilingual Conversations

### Test 2.1: Swahili-English Code-Mixing

**Objective:** Verify AI handles mixed-language messages

**Test Message:** `"Ninahisi sick na nina headache kila siku"`
(Translation: "I feel sick and have headache every day")

**Expected Results:**
- ✅ Primary language detected (likely `sw` or `en`)
- ✅ AI responds appropriately understanding both languages
- ✅ Response may be in dominant language or mixed
- ✅ Confidence score ≥ 0.70 (lower due to mixing)

**Database Verification:**
```sql
SELECT language_code, confidence_score, content
FROM ai_messages
WHERE content LIKE '%Ninahisi sick%';
```

---

### Test 2.2: Language Switching Within Conversation

**Objective:** Test language switching mid-conversation

**Test Steps:**
1. Send message in English: `"What causes diabetes?"`
2. Wait for English response
3. Switch to French: `"Et quels sont les traitements?"`
4. Wait for French response
5. Switch back to English: `"Can it be cured?"`

**Expected Results:**
- ✅ Message 1: `language_code = 'en'`
- ✅ Message 3: `language_code = 'fr'`, AI responds in French
- ✅ Message 5: `language_code = 'en'`, AI switches back to English
- ✅ AI maintains conversation context despite language changes
- ✅ Language badges update correctly for each message

**Database Verification:**
```sql
SELECT
  role,
  language_code,
  LEFT(content, 50) as content_preview
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at;
```

Expected pattern:
```
role      | language_code | content_preview
----------+---------------+----------------------------------
user      | en            | What causes diabetes?
assistant | en            | Diabetes is caused by...
user      | fr            | Et quels sont les traitements?
assistant | fr            | Les traitements incluent...
user      | en            | Can it be cured?
assistant | en            | While diabetes cannot be cured...
```

---

### Test 2.3: French-Arabic Code-Mixing

**Test Message:** `"Je veux savoir ما هو العلاج pour le diabète"`
(Translation: "I want to know what is the treatment for diabetes")

**Expected Results:**
- ✅ Dominant language detected (likely `fr` or `ar`)
- ✅ AI responds understanding mixed query
- ✅ Confidence score ≥ 0.65

---

## Test Suite 3: Language Detection Edge Cases

### Test 3.1: Very Short Messages

**Objective:** Test detection with minimal text

**Test Messages:**
- `"Oui"` (French: Yes)
- `"Ndiyo"` (Swahili: Yes)
- `"نعم"` (Arabic: Yes)
- `"Ee"` (Yoruba: Yes)

**Expected Results:**
- ✅ Correct language detected or defaulted to English
- ✅ Lower confidence scores (0.5-0.7) acceptable for 1-word messages
- ✅ AI responds appropriately

---

### Test 3.2: Numbers and Medical Terms

**Test Message:** `"Mon BP est 140/90 mmHg"`
(Translation: "My BP is 140/90 mmHg")

**Expected Results:**
- ✅ Language detected: `fr` (French)
- ✅ AI correctly interprets BP = blood pressure
- ✅ Numbers preserved in response
- ✅ Medical units handled correctly

---

### Test 3.3: Messages with Special Characters

**Test Message:** `"J'ai mal à la tête!!! 😢"`

**Expected Results:**
- ✅ Language detected: `fr`
- ✅ Special characters and emojis don't break detection
- ✅ AI responds empathetically in French

---

### Test 3.4: Similar Languages (Disambiguation)

**Objective:** Test differentiation between similar languages

**Test Pairs:**
- **French vs. Kinyarwanda** (both have French influence)
  - French: `"J'ai besoin d'aide"`
  - Kinyarwanda: `"Ndakeneye ubufasha"`

- **Swahili vs. Kinyarwanda**
  - Swahili: `"Ninahitaji msaada"`
  - Kinyarwanda: `"Ndakeneye ubufasha"`

**Expected Results:**
- ✅ Correct language identified for each
- ✅ Confidence scores ≥ 0.85 for clear cases

---

## Test Suite 4: Translation Quality

### Test 4.1: Medical Terminology Accuracy

**Objective:** Verify medical terms translated correctly

**Test Steps:**
1. Send English: `"What is hypertension?"`
2. Send French: `"Qu'est-ce que l'hypertension?"`
3. Send Swahili: `"Shinikizo la damu ni nini?"`

**Verification:**
- ✅ All three should receive equivalent medical explanations
- ✅ Technical terms properly translated:
  - English: "blood pressure", "heart", "arteries"
  - French: "tension artérielle", "cœur", "artères"
  - Swahili: "shinikizo la damu", "moyo", "mishipa ya damu"

---

### Test 4.2: Cultural Context Adaptation

**Test Message (French):** `"Comment prévenir le paludisme?"`
(How to prevent malaria?)

**Expected AI Response:**
- ✅ Responds in French
- ✅ Provides culturally relevant advice (mosquito nets, antimalarials)
- ✅ Medical information accurate for African context

---

## Test Suite 5: UI Language Badge Display

### Test 5.1: Badge Visibility

**Objective:** Verify language badges display correctly

**Test Steps:**
1. Send English message
2. Send French message
3. Send Swahili message

**Expected UI Behavior:**
- ✅ English message: **No badge** (default language)
- ✅ French message: Badge shows "fr" or "Français"
- ✅ Swahili message: Badge shows "sw" or "Kiswahili"
- ✅ Badges positioned consistently (below message bubble)
- ✅ Readable font size and color

---

### Test 5.2: Badge Styling

**Check:**
- ✅ Badge background color distinguishable
- ✅ Text color contrasts well
- ✅ Badge shape/border clear (rounded corners, chip style)
- ✅ Badge doesn't overlap with message text
- ✅ Mobile responsive (doesn't break layout on small screens)

---

## Test Suite 6: Confidence Score Validation

### Test 6.1: High Confidence Messages

**Test Messages with Expected High Confidence (≥ 0.90):**
- English: `"Good morning, how are you?"`
- French: `"Bonjour, comment allez-vous?"`
- Arabic: `"صباح الخير، كيف حالك؟"`

**Database Verification:**
```sql
SELECT
  language_code,
  confidence_score,
  content
FROM ai_messages
WHERE confidence_score >= 0.90
ORDER BY confidence_score DESC;
```

---

### Test 6.2: Low Confidence Messages

**Test Messages Likely to Produce Low Confidence (<0.70):**
- Mixed language: `"Hello comment vas-tu today?"`
- Very short: `"Hi"`
- Numbers only: `"120/80"`

**Expected Results:**
- ✅ System still attempts detection
- ✅ Confidence score accurately reflects uncertainty
- ✅ AI responds appropriately despite low confidence

**Database Verification:**
```sql
SELECT
  language_code,
  confidence_score,
  content
FROM ai_messages
WHERE confidence_score < 0.70
ORDER BY confidence_score ASC;
```

---

## Test Suite 7: Conversation History with Multiple Languages

### Test 7.1: History Retrieval

**Objective:** Verify language information preserved in history

**Test Steps:**
1. Create conversation with messages in 3+ languages
2. Close conversation
3. Reopen conversation
4. Scroll through history

**Expected Results:**
- ✅ All language badges display correctly
- ✅ Language codes preserved in database
- ✅ Confidence scores unchanged
- ✅ Messages load in correct order

**Database Query:**
```sql
SELECT
  role,
  language_code,
  confidence_score,
  created_at,
  LEFT(content, 30) as preview
FROM ai_messages
WHERE conversation_id = '[conversation-id]'
ORDER BY created_at ASC;
```

---

### Test 7.2: Conversation Language Summary

**Check Conversation Metadata:**

**Database Query:**
```sql
SELECT
  c.id,
  c.detected_language,
  c.total_messages,
  COUNT(DISTINCT m.language_code) as unique_languages,
  string_agg(DISTINCT m.language_code, ', ') as languages_used
FROM ai_conversations c
JOIN ai_messages m ON c.id = m.conversation_id
WHERE c.id = '[conversation-id]'
GROUP BY c.id, c.detected_language, c.total_messages;
```

Expected:
```
detected_language | total_messages | unique_languages | languages_used
------------------+----------------+------------------+-------------------
en                | 12             | 3                | en, fr, sw
```

---

## Test Suite 8: Performance with Non-Latin Scripts

### Test 8.1: Arabic (Right-to-Left)

**Test Message:** `"أحتاج إلى مساعدة طبية عاجلة"`
(I need urgent medical help)

**UI Verification:**
- ✅ Text displays right-to-left
- ✅ Message bubble aligns correctly
- ✅ No text overflow or wrapping issues
- ✅ Arabic characters render properly

---

### Test 8.2: Amharic (Ethiopic Script)

**Test Message:** `"የሕመም ምልክቶቼ እየባሱ ነው"`
(My symptoms are getting worse)

**UI Verification:**
- ✅ Ethiopic characters display correctly
- ✅ No font fallback issues
- ✅ Message readable

---

## Test Suite 9: Edge Function Language Processing

### Test 9.1: Edge Function Logs Review

**Check Supabase Edge Function Logs:**

```bash
npx supabase functions logs bedrock-ai-chat --tail
```

**Look for Log Entries:**
```
Language detected: fr with confidence 0.94
Processing message in language: fr
Bedrock AI model response in language: fr
```

**Verification:**
- ✅ Language detection logged
- ✅ Confidence score logged
- ✅ Language passed to Bedrock AI
- ✅ Response language matches request

---

### Test 9.2: AWS Lambda Language Detection

**Check CloudWatch Logs (if accessible):**

```bash
aws logs tail /aws/lambda/medzen-ai-chat-handler --follow --region eu-central-1
```

**Expected Log Format:**
```
[INFO] Input language detected: sw
[INFO] Confidence score: 0.87
[INFO] Invoking Bedrock with language: sw
[INFO] Response generated in language: sw
```

---

## Database Schema Reference

### ai_messages Table (Language Fields)

```sql
\d ai_messages

Column                | Type      | Description
----------------------+-----------+----------------------------------
id                    | uuid      | Primary key
conversation_id       | uuid      | Foreign key to ai_conversations
role                  | text      | user/assistant/system
content               | text      | Message text
language_code         | text      | ISO 639-1 language code (en, fr, sw, etc.)
confidence_score      | numeric   | Language detection confidence (0.0-1.0)
created_at            | timestamp | Message creation time
```

### ai_conversations Table (Language Fields)

```sql
\d ai_conversations

Column                | Type      | Description
----------------------+-----------+----------------------------------
id                    | uuid      | Primary key
patient_id            | uuid      | User ID
detected_language     | text      | Primary conversation language
default_language      | text      | User's preferred language
```

---

## Common Issues & Troubleshooting

### Issue 1: Language Not Detected Correctly

**Symptoms:**
- English messages show as French
- Swahili detected as English

**Possible Causes:**
1. Very short message (1-2 words)
2. Code-mixing confusing detector
3. Medical terminology in English used across languages

**Solutions:**
- Check confidence score (low score indicates uncertainty)
- Use longer, more natural sentences
- Verify message content in database
- Review Edge Function logs for detection details

**Debugging:**
```sql
SELECT content, language_code, confidence_score
FROM ai_messages
WHERE language_code != 'en' AND confidence_score < 0.70
ORDER BY confidence_score ASC;
```

---

### Issue 2: AI Responds in Wrong Language

**Symptoms:**
- User sends French, AI responds in English
- User sends Swahili, AI responds in French

**Possible Causes:**
1. Language code not passed to Bedrock AI
2. Model not supporting requested language
3. Edge Function language mapping error

**Solutions:**
- Check Edge Function logs for language passed to Bedrock
- Verify AWS Lambda receives correct language parameter
- Confirm model `eu.amazon.nova-pro-v1:0` supports language

**Edge Function Debug:**
```bash
npx supabase functions logs bedrock-ai-chat --tail | grep -i "language"
```

---

### Issue 3: Language Badge Not Displaying

**Symptoms:**
- Non-English messages show no language indicator

**Possible Causes:**
1. CSS styling issue
2. language_code field empty in database
3. UI conditional logic error

**Solutions:**
- Inspect message element in browser DevTools
- Check database for language_code value
- Verify conditional rendering logic in FlutterFlow

**Database Check:**
```sql
SELECT id, language_code, content
FROM ai_messages
WHERE language_code IS NULL OR language_code = '';
```

---

### Issue 4: Mixed Language Conversations Failing

**Symptoms:**
- Conversation breaks when switching languages
- AI loses context after language change

**Possible Causes:**
1. Conversation history not preserving language info
2. System prompt not handling multilingual context
3. Token limit exceeded with translations

**Solutions:**
- Verify conversation history includes language_code
- Check Edge Function conversation formatting
- Reduce history size if approaching token limits

---

### Issue 5: Low Confidence Scores for Valid Messages

**Symptoms:**
- Clear French messages show confidence 0.60
- Obvious Swahili detected with 0.55 confidence

**Possible Causes:**
1. Dialect variations (e.g., Kenyan vs. Tanzanian Swahili)
2. Regional spelling differences
3. Model not well-trained on African languages

**Solutions:**
- Accept lower confidence thresholds for African languages (≥0.70)
- Log low-confidence cases for model improvement
- Add regional language variants to supported list

---

## Success Criteria

**Phase 4 Testing Complete When:**

### Language Detection
- [ ] All 12 languages correctly detected with confidence ≥ 0.80
- [ ] English (default) has no language badge
- [ ] Non-English messages display language badge
- [ ] Code-mixing handled gracefully

### AI Response Quality
- [ ] AI responds in detected language consistently
- [ ] Medical terminology translated accurately
- [ ] Cultural context appropriate for each language
- [ ] Conversation context maintained across language switches

### Database Integrity
- [ ] `language_code` populated for all messages
- [ ] `confidence_score` within expected ranges (0.0-1.0)
- [ ] `detected_language` set correctly in conversations
- [ ] No NULL language fields

### UI/UX
- [ ] Language badges styled consistently
- [ ] Right-to-left languages display correctly (Arabic)
- [ ] Non-Latin scripts render properly (Amharic)
- [ ] Mobile responsive layout maintained

### Performance
- [ ] Language detection doesn't significantly slow responses
- [ ] Average response time < 3 seconds for all languages
- [ ] No memory leaks or errors with mixed-language conversations

---

## Multilingual Test Summary Template

After completing all tests, document results:

```markdown
## Multilingual Testing Results

**Test Date:** YYYY-MM-DD
**Tester:** [Name]
**Conversation IDs Tested:** [List UUIDs]

### Language Detection Accuracy

| Language | Messages Tested | Correctly Detected | Avg Confidence | Pass/Fail |
|----------|----------------|-------------------|----------------|-----------|
| English  | 10             | 10                | 0.97           | ✅ PASS    |
| French   | 8              | 8                 | 0.93           | ✅ PASS    |
| Swahili  | 6              | 6                 | 0.88           | ✅ PASS    |
| Arabic   | 5              | 5                 | 0.91           | ✅ PASS    |
| ...      | ...            | ...               | ...            | ...       |

### AI Response Quality (Rated 1-5)

| Language | Medical Accuracy | Translation Quality | Cultural Relevance | Overall |
|----------|-----------------|--------------------|--------------------|---------|
| English  | 5               | N/A                | 5                  | 5       |
| French   | 5               | 4                  | 5                  | 4.5     |
| Swahili  | 4               | 4                  | 5                  | 4.3     |
| ...      | ...             | ...                | ...                | ...     |

### Issues Found
1. [Issue description, severity, resolution]
2. [Issue description, severity, resolution]

### Recommendations
1. [Recommendation for improvement]
2. [Recommendation for improvement]

**Overall Status:** ✅ PASS / ⚠️ PARTIAL / ❌ FAIL

**Sign-Off:**
- Multilingual functionality ready for production: YES/NO
- Blocker issues: [List or None]
```

---

## Next Phase

Once Phase 4 (Multilingual Testing) is complete, proceed to:

**Phase 5:** Conversation Persistence & History Testing
- Test conversation creation/retrieval across sessions
- Verify message history loads correctly
- Test cross-device synchronization
- Verify conversation metadata accuracy

---

**Last Updated:** December 18, 2025
**Backend Status:** ✅ Fully operational
**Testing Status:** ⏳ Ready for multilingual verification
**Required:** Manual execution through MedZen app interface
