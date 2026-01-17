# Transcription Consent Messaging Implementation Guide

**Status:** Recommended Enhancement (Not Blocking)
**Effort:** 30 minutes
**Complexity:** Low
**Files to Modify:** 1-2
**Testing Time:** 10 minutes

---

## Why This Matters

**Legal & Compliance:**
- Users need to know their call is being recorded/transcribed
- Medical/healthcare context requires explicit consent
- Transparency builds trust

**Current State:**
- Calls are transcribed automatically
- No notification to the user
- No consent required

**After Implementation:**
- User sees clear disclosure before joining
- Option to decline if needed
- Acknowledgment that transcription will happen

---

## Option 1: Add to Pre-Joining Dialog (Recommended - Simple)

**File:** `lib/custom_code/widgets/chime_pre_joining_dialog.dart`

**Location:** After line 195 (after provider role text)

**Add this code:**

```dart
// Add this import at the top if not present:
// import 'package:flutter/material.dart'; // Already imported

// Find the build() method, around line 156
// Inside the Column children list (around line 220), add:

const SizedBox(height: 20),
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    border: Border.all(color: Colors.blue.shade200),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info,
        color: Colors.blue.shade700,
        size: 20,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          'This video call will be recorded and transcribed using AWS Transcribe Medical for accurate medical documentation.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade700,
            height: 1.4,
          ),
        ),
      ),
    ],
  ),
),
```

**Visual Result:**
```
┌─────────────────────────────┐
│ Dr. Smith                   │
│ Medical Provider            │
│                             │
│ ℹ️ This video call will be  │
│    recorded and transcribed │
│    using AWS Transcribe...  │
│                             │
│ [Disable Mic] [Disable Cam] │
│  [Cancel]     [Join Call]   │
└─────────────────────────────┘
```

---

## Option 2: Separate Consent Dialog (More Formal)

**File:** Create new file OR use existing join logic

**When to show:** Right before joining the call

**Implementation:**

Create a new file: `lib/custom_code/dialogs/transcription_consent_dialog.dart`

```dart
import 'package:flutter/material.dart';

Future<bool> showTranscriptionConsentDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must make a choice
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text('Call Recording & Transcription Consent'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            const Text(
              'Important: Your Consent is Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'This video call will be:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Recorded for record-keeping purposes\n'
              '• Transcribed using AWS Transcribe Medical\n'
              '• Analyzed for medical entities (ICD-10, diagnoses)\n'
              '• Stored securely in HIPAA-compliant storage',
            ),
            const SizedBox(height: 12),
            const Text(
              'By clicking "I Consent", you acknowledge that:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              '• You understand this call will be recorded\n'
              '• You consent to transcription and analysis\n'
              '• You grant permission for medical documentation\n'
              '• The recording will be stored securely',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel Call'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: const Text('I Consent'),
        ),
      ],
    ),
  );
  return result ?? false;
}
```

**Usage in video call action:**

```dart
// In the joinRoom() action or wherever you start the video call

// Show consent dialog
final userConsents = await showTranscriptionConsentDialog(context);

if (!userConsents) {
  // User declined - don't start the call
  print('User declined transcription consent');
  return;
}

// User consented - proceed with video call
// ... rest of video call setup
```

---

## Option 3: Banner on Video Call Page (Persistent Reminder)

**Location:** Top of the video call widget

**Code:**

```dart
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  color: Colors.orange.shade100,
  child: Row(
    children: [
      Icon(Icons.videocam_outlined, color: Colors.orange.shade700),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          '🔴 Recording: This call is being recorded and transcribed.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.orange.shade900,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  ),
)
```

---

## Implementation Checklist

### Step 1: Choose Your Approach
- [ ] Option 1 (Simple - Add to dialog)
- [ ] Option 2 (Formal - Separate dialog with full consent)
- [ ] Option 3 (Persistent - Banner on call page)
- [ ] Multiple options (all three for maximum clarity)

### Step 2: Modify Code
- [ ] Edit or create the file
- [ ] Add the disclosure/consent UI
- [ ] Add logic to require acknowledgment (if using Option 2)

### Step 3: Testing
- [ ] Test on Android emulator
- [ ] Test on iOS simulator
- [ ] Test on mobile device
- [ ] Verify disclosure appears before call starts
- [ ] Verify user can still join after seeing message

### Step 4: Deployment
- [ ] `flutter clean && flutter pub get`
- [ ] `flutter build web --release` (if testing web)
- [ ] `flutter build apk --release` (if testing Android)
- [ ] Deploy to dev environment
- [ ] Verify on https://001e077e.medzen-dev.pages.dev
- [ ] Get user approval before production deployment

---

## Recommended Wording Templates

### Template 1: Concise (One-liner)
```
"This video call will be recorded and transcribed for medical documentation."
```

### Template 2: Informative (Short paragraph)
```
"This video call will be recorded and transcribed using AWS Transcribe Medical
for accurate medical documentation. Recording starts when the call connects."
```

### Template 3: Comprehensive (Full disclosure)
```
"This video call will be:
• Recorded for record-keeping
• Transcribed automatically
• Analyzed for medical entities
• Stored securely (HIPAA-compliant)

By joining, you consent to this recording and transcription."
```

### Template 4: Patients Only (From provider perspective)
```
"Your healthcare provider may record and transcribe this call for quality
improvement and medical documentation. No external parties will access the recording."
```

---

## Compliance Considerations

### Medical/Healthcare Context
- **HIPAA (US):** Requires notification and consent for recordings
- **GDPR (EU):** Requires explicit consent before data processing
- **Local Laws:** Check jurisdiction-specific requirements

### Recommendations
1. ✅ Show disclosure before call starts
2. ✅ Require explicit acknowledgment (checkbox or button click)
3. ✅ Keep documentation of consent (timestamp + acknowledgment)
4. ✅ Allow opt-out (user can decline)
5. ✅ Store consent records in database

### Database Schema (Optional - for audit trail)
```sql
-- Add to track consent
CREATE TABLE IF NOT EXISTS call_transcription_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_session_id UUID NOT NULL REFERENCES video_call_sessions(id),
  user_id UUID NOT NULL REFERENCES users(id),
  consent_given BOOLEAN NOT NULL,
  consent_timestamp TIMESTAMP DEFAULT NOW(),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Testing Script

**After implementing, test with this checklist:**

```
[ ] Open video call page
[ ] See consent message/dialog before joining
[ ] Can read the disclosure clearly
[ ] Can click "I Consent" or acknowledge
[ ] Can decline if needed (if Option 2)
[ ] After consent, call joins successfully
[ ] Transcription starts automatically
[ ] No double-prompts (only shows once)
[ ] Works on mobile (Android & iOS)
[ ] Works on web (Chrome, Firefox, Safari)
[ ] Consent is logged in CloudWatch
```

---

## Estimated Effort

| Option | Development | Testing | Total |
|--------|-------------|---------|-------|
| Option 1 (Simple) | 10 min | 5 min | **15 minutes** |
| Option 2 (Formal) | 20 min | 10 min | **30 minutes** |
| Option 3 (Banner) | 5 min | 5 min | **10 minutes** |
| All Three | 30 min | 10 min | **40 minutes** |

---

## Deployment Checklist

Before deploying to production:

- [ ] Consent message implemented and tested
- [ ] Disclosure text is clear and concise
- [ ] User can acknowledge/accept
- [ ] Works on all platforms (web, Android, iOS)
- [ ] No blocking issues or errors
- [ ] Logcat shows no errors when consent is shown
- [ ] Browser console (F12) shows no JavaScript errors
- [ ] User testing completed with at least 3 users
- [ ] Legal team reviewed the wording
- [ ] Deployment PR created and reviewed

---

## Next Steps

1. **Choose your approach** (Option 1 recommended for MVP)
2. **Implement the code** (copy-paste from above)
3. **Test locally** (flutter run -d emulator or chrome)
4. **Deploy to dev** (test URL)
5. **Get approval** from team/legal
6. **Deploy to production**

---

**Questions?**
- See COMPREHENSIVE_CHECKLIST_VERIFICATION_JAN12.md for full context
- Check CLAUDE.md for architecture details
- Review git history for recent changes: `git log --oneline -20`

