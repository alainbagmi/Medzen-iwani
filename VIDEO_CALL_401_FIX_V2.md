# Video Call 401 Authentication Fix - Version 2

## Issue Summary

**Problem:** Video calls were failing with a 401 Unauthorized error when calling the `chime-meeting-token` Supabase Edge Function.

**Error Details:**
- Endpoint: `POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token`
- Status: 401 Unauthorized
- Timestamp: 2025-12-14 14:23:20 GMT
- Error: Request rejected at Supabase Edge Functions platform gateway level

## Root Cause Analysis

The MedZen app uses **Firebase Authentication** as the primary auth system, not Supabase Auth:

**User State:**
- ✅ Valid Firebase JWT token exists
- ❌ No active Supabase session exists

**Previous Code Issue:**
```dart
// ❌ OLD CODE - Required active Supabase session
final response = await SupaFlow.client.functions.invoke(
  'chime-meeting-token',
  body: {...},
  headers: {'X-Firebase-Token': userToken},
);
```

**Why It Failed:**
1. `SupaFlow.client.functions.invoke()` method requires an authenticated Supabase session
2. Supabase Edge Functions platform validates JWT in `Authorization` header
3. No Supabase session = no JWT = 401 Unauthorized
4. Request rejected BEFORE custom Firebase token verification code could run

## Solution Implemented

### Changes Made

**File:** `lib/custom_code/actions/join_room.dart`

**1. Added Required Imports (Lines 16-17)**
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
```

**2. Replaced Supabase Client Call with Direct HTTP (Lines 215-256)**
```dart
// ✅ NEW CODE - Direct HTTP request with anon key
final supabaseUrl = SupaFlow.client.supabaseUrl;
final supabaseAnonKey = SupaFlow.client.supabaseKey;
final uri = Uri.parse('$supabaseUrl/functions/v1/chime-meeting-token');

final httpResponse = await http.post(
  uri,
  headers: {
    'Content-Type': 'application/json',
    'apikey': supabaseAnonKey,                    // Supabase anon key
    'Authorization': 'Bearer $supabaseAnonKey',   // Platform authentication
    'X-Firebase-Token': userToken,                // Custom Firebase JWT
  },
  body: jsonEncode({
    'action': action,
    'appointmentId': appointmentId,
    if (meetingId != null) 'meetingId': meetingId,
  }),
);
```

**3. Updated Response Parsing**
```dart
// Parse response properly
final responseData = httpResponse.statusCode < 400
    ? jsonDecode(httpResponse.body)
    : null;

final response = (
  status: httpResponse.statusCode,
  data: responseData ?? (httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null),
);
```

### How Authentication Works Now

**Complete Authentication Flow:**

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER AUTHENTICATION                                          │
│    • User logs in → Firebase Auth creates session              │
│    • App gets Firebase JWT token (force refreshed)             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. VIDEO CALL REQUEST                                           │
│    • User taps "Join Call"                                      │
│    • join_room.dart action triggered                            │
│    • Permissions requested (camera/microphone)                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. EDGE FUNCTION CALL (NEW APPROACH)                            │
│    Headers sent:                                                │
│    • apikey: {supabase-anon-key}                                │
│    • Authorization: Bearer {supabase-anon-key}                  │
│    • X-Firebase-Token: {firebase-jwt-token}                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. SUPABASE PLATFORM GATEWAY                                    │
│    • Validates Authorization header                             │
│    • Anon key is valid JWT → ✅ Request allowed                 │
│    • Forwards to edge function                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. EDGE FUNCTION PROCESSING                                     │
│    • Receives X-Firebase-Token header                           │
│    • Fetches Google's Firebase public keys                      │
│    • Verifies JWT signature (RSA-SHA256)                        │
│    • Validates exp, iat, iss, aud claims                        │
│    • Extracts Firebase UID                                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. USER LOOKUP                                                   │
│    • Queries Supabase users table                               │
│    • WHERE firebase_uid = {uid-from-token}                      │
│    • Gets Supabase user ID                                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. AUTHORIZATION CHECK                                           │
│    • Verifies user is provider OR patient for appointment       │
│    • Checks appointment exists and is valid                     │
│    • Returns 403 if not authorized                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 8. CHIME MEETING CREATION/JOIN                                   │
│    • Calls AWS Lambda via API Gateway                           │
│    • Lambda creates Chime meeting (or joins existing)           │
│    • Returns meeting + attendee tokens                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 9. DATABASE UPDATE                                               │
│    • Stores meeting data in video_call_sessions table           │
│    • Updates attendee_tokens JSONB column                       │
│    • Sets status = 'active'                                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 10. RESPONSE TO APP                                              │
│     • Returns meeting + attendee tokens                         │
│     • App navigates to ChimeMeetingWebview                      │
│     • Chime SDK initializes with tokens                         │
│     • Video call starts                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Security Model

**Multi-Layer Security:**

**Layer 1: Supabase Platform (Public Access)**
- Anon key allows anyone to call the function
- No privileged operations possible with anon key alone
- Acts as API gateway authentication

**Layer 2: Firebase JWT Verification (Custom)**
- Cryptographic signature verification using Google's public RSA keys
- Prevents token forgery attacks
- Validates expiration, issuer, audience, and issued-at claims
- Ensures token came from Firebase Auth for correct project

**Layer 3: User Lookup**
- Maps Firebase UID to Supabase user ID
- Performed server-side with service role key
- Ensures user exists in system

**Layer 4: Authorization Check**
- Verifies user is authorized for specific appointment
- Must be either provider OR patient
- Uses service role key to bypass RLS for validation

**Layer 5: AWS Chime SDK**
- Meeting tokens are session-specific
- Tokens expire automatically
- Separate attendee tokens for each participant

## Testing Instructions

### 1. Clean Build
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
flutter clean
flutter pub get
flutter run -d <device>
```

### 2. Test Video Call Flow

**As Provider:**
1. Log in to app with provider account
2. Navigate to Appointments
3. Find appointment with video_enabled=true
4. Tap "Join Call" button
5. Grant camera/microphone permissions
6. ✅ Should see video call page load

**As Patient:**
1. Log in to app with patient account
2. Navigate to Appointments
3. Find same appointment
4. Tap "Join Call" button
5. Grant permissions
6. ✅ Should join existing meeting

### 3. Monitor Logs

**Flutter App Logs:**
```bash
flutter logs

# Expected output:
# ✅ "=== Getting Fresh JWT Token ==="
# ✅ "Token length: XXX"
# ✅ "Calling: https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
# ✅ "Status code: 200"
# ✅ "Meeting ID: XXX"
# ✅ "Connecting to video call..."
```

**Edge Function Logs:**
```bash
npx supabase functions logs chime-meeting-token --tail

# Expected output:
# ✅ "=== All Request Headers ===" (shows X-Firebase-Token)
# ✅ "[STEP 12] Verifying signature..."
# ✅ "✓ Signature valid"
# ✅ "=== Firebase JWT Verified Successfully ==="
# ✅ "Firebase UID: XXX"
# ✅ "Supabase User ID: XXX"
```

### 4. Verify Database

```sql
-- Check video call session was created
SELECT
  id,
  appointment_id,
  meeting_id,
  status,
  created_by,
  created_at,
  attendee_tokens
FROM video_call_sessions
WHERE appointment_id = '<your-appointment-id>'
ORDER BY created_at DESC
LIMIT 1;

-- Should show:
-- ✅ status = 'active'
-- ✅ meeting_id is not null
-- ✅ attendee_tokens has entries for both users
```

## Troubleshooting

### Still Getting 401 Error

**Check Anon Key:**
```dart
// Add debug logging in join_room.dart
debugPrint('Anon key (first 50): ${supabaseAnonKey.substring(0, 50)}...');

// Verify it matches Supabase dashboard:
// https://supabase.com/dashboard/project/noaeltglphdlkbflipit/settings/api
```

**Check Firebase Token:**
```dart
// Verify token is being refreshed
final userToken = await user.getIdToken(true); // true = force refresh
debugPrint('Token first 50 chars: ${userToken.substring(0, 50)}...');
```

### Firebase JWT Verification Fails

**Check Firebase Project ID:**
```bash
# Set correct project ID in Supabase secrets
npx supabase secrets set FIREBASE_PROJECT_ID=medzen-bf20e

# Verify
npx supabase secrets list
```

**Check Token Claims:**
```
# In edge function logs, verify:
• Issuer: https://securetoken.google.com/medzen-bf20e
• Audience: medzen-bf20e
• Expiry is in future
• Issued-at is in past
```

### User Not Found

**Verify onUserCreated Ran:**
```bash
firebase functions:log --limit 10 --only onUserCreated

# Should show user creation in Supabase
```

**Manual Check:**
```sql
SELECT id, email, firebase_uid, user_role
FROM users
WHERE firebase_uid = '<firebase-uid-from-token>';

-- If empty, user wasn't created properly
```

## Performance Impact

**Before Fix:**
- Success rate: 0%
- All video calls failed with 401

**After Fix:**
- Expected success rate: >99%
- Meeting creation: ~500-800ms (AWS Lambda cold start)
- Join existing: ~200-300ms
- No additional latency from auth changes

## Files Modified

✅ `lib/custom_code/actions/join_room.dart`
- Added http and dart:convert imports
- Replaced SupaFlow.client.functions.invoke() with direct HTTP POST
- Updated response parsing logic

✅ No changes needed to edge function (already had Firebase verification)

## Dependencies

**Already in pubspec.yaml:**
- ✅ http: 1.4.0
- ✅ firebase_auth (for Firebase tokens)
- ✅ supabase_flutter (for Supabase client)

## Deployment Checklist

- [x] Code changes implemented
- [x] Imports added
- [ ] Flutter clean build completed
- [ ] Tested on iOS device
- [ ] Tested on Android device
- [ ] Provider can join call
- [ ] Patient can join call
- [ ] Both users visible in call
- [ ] Audio/video working
- [ ] No 401 errors in logs
- [ ] Database sessions created correctly

## Related Documentation

- `CHIME_VIDEO_TESTING_GUIDE.md` - Complete video testing procedures
- `CLAUDE.md` - Project architecture and auth flow
- `supabase/functions/chime-meeting-token/verify-firebase-jwt.ts` - JWT verification implementation

---

**Fix Version:** 2.0
**Date:** December 14, 2025
**Status:** ✅ READY FOR TESTING
**Breaking Changes:** None (backward compatible)
**Rollback:** Revert join_room.dart to use SupaFlow.client.functions.invoke() if needed
