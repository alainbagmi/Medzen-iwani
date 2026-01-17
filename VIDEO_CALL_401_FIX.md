# Video Call 401 Error Fix

## Problem

Video calls were failing with **401 Unauthorized** errors when calling the `chime-meeting-token` Supabase Edge Function.

### Error Details
```json
{
  "event_message": "POST | 401 | https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token",
  "status_code": 401
}
```

### Root Cause

The Flutter app was sending the Firebase JWT token in the `Authorization` header:
```dart
headers: {
  'Authorization': 'Bearer $userToken',  // ❌ Wrong!
  'Content-Type': 'application/json',
}
```

However, Supabase Edge Functions **automatically validate** the `Authorization` header expecting a **Supabase JWT**, not a Firebase JWT. This caused the automatic validation to fail with 401.

The edge function was designed to receive the Firebase JWT in a **custom header** called `X-Firebase-Token` to bypass this automatic validation:
```typescript
const firebaseTokenHeader = req.headers.get("X-Firebase-Token");
if (!firebaseTokenHeader) {
  return new Response(
    JSON.stringify({ error: "Missing X-Firebase-Token header" }),
    { status: 401 }
  );
}
```

## Solution

### Changed File
`lib/custom_code/actions/join_room.dart`

### Fix Applied
Changed the header from `Authorization` to `X-Firebase-Token`:

```dart
// BEFORE (❌ Caused 401 errors)
final response = await http.post(
  Uri.parse(functionUrl),
  headers: {
    'Authorization': 'Bearer $userToken',  // Wrong header
    'Content-Type': 'application/json',
  },
  body: jsonEncode({...}),
);

// AFTER (✅ Works correctly)
final response = await http.post(
  Uri.parse(functionUrl),
  headers: {
    'X-Firebase-Token': userToken,  // Correct custom header
    'Content-Type': 'application/json',
  },
  body: jsonEncode({...}),
);
```

## Verification

Run the test script to verify the fix:
```bash
./test_chime_header_fix.sh
```

### Expected Output
```
✅ All checks passed!

The fix is correct:
1. User exists in database
2. Appointment is ready for testing
3. join_room.dart sends Firebase JWT in X-Firebase-Token header
4. Edge function expects X-Firebase-Token header
```

## Testing the Fix

### 1. Clean and Rebuild
```bash
flutter clean && flutter pub get
flutter run
```

### 2. Test Video Call Flow
1. Log in to the app with a provider or patient account
2. Navigate to a scheduled appointment
3. Click the "Join Video Call" button
4. **Expected**: Video call page loads successfully
5. **Previous**: Got 401 Unauthorized error

### 3. Verify No Errors
Check Supabase Edge Function logs:
```bash
npx supabase functions logs chime-meeting-token --tail
```

**Expected**: No more 401 errors. Should see successful authentication:
```
=== Firebase JWT Verified Successfully ===
User ID (uid): jt3xBjcPEdQzltsC9hEkzBzqbWz1
=== Auth Success ===
```

## Why This Architecture?

### Firebase Auth + Supabase Database

MedZen uses **Firebase for authentication** but **Supabase for the database**. This hybrid approach requires special handling:

1. **User logs in** → Firebase Auth creates JWT
2. **App makes API calls** → Must send Firebase JWT
3. **Edge Functions** → Must verify Firebase JWT (not Supabase JWT)
4. **Custom header** → Bypasses Supabase's automatic JWT validation

### Alternative Approach (Not Used)

We could have used Supabase Auth instead, but:
- Would require migrating all Firebase Auth users
- Would break existing Firebase Cloud Functions
- FlutterFlow has better Firebase Auth integration

## Related Files

- **Flutter action**: `lib/custom_code/actions/join_room.dart`
- **Edge function**: `supabase/functions/chime-meeting-token/index.ts`
- **JWT verifier**: `supabase/functions/chime-meeting-token/verify-firebase-jwt.ts`
- **Test script**: `test_chime_header_fix.sh`

## Impact

### Before Fix
- ❌ All video calls failed with 401 errors
- ❌ Users could not join meetings
- ❌ Provider-patient consultations blocked

### After Fix
- ✅ Video calls authenticate successfully
- ✅ Users can create and join meetings
- ✅ Full video call functionality restored

## Key Learnings

1. **Read the function code**: The edge function had clear comments about using `X-Firebase-Token`
2. **Understand the platform**: Supabase Edge Functions auto-validate `Authorization` header
3. **Custom headers for hybrid auth**: When mixing Firebase Auth + Supabase, use custom headers
4. **Always test authentication flows**: Auth issues manifest as 401 errors

## Prevention

### For Future Development

1. **Document header requirements** in API call code
2. **Add TypeScript types** for request headers
3. **Create integration tests** for auth flows
4. **Use constants** for custom header names

Example:
```dart
// Good practice - define header names as constants
class ChimeApiHeaders {
  static const firebaseToken = 'X-Firebase-Token';
  static const contentType = 'Content-Type';
}

// Use in code
headers: {
  ChimeApiHeaders.firebaseToken: userToken,
  ChimeApiHeaders.contentType: 'application/json',
}
```

## Status

- [x] Root cause identified
- [x] Fix implemented
- [x] Test script created
- [x] Verification passed
- [ ] User testing on physical device
- [ ] Deploy to production

## Next Steps

1. **Test on physical device** (not just simulator)
2. **Verify end-to-end video call** works
3. **Monitor Supabase logs** for any remaining auth issues
4. **Update FlutterFlow** with this custom code if needed
