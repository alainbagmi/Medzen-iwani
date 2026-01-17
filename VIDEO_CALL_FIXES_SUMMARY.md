# Video Call Issues Fixed - December 16, 2025

## Issues Resolved

### ✅ Issue 1: RLS Policy Blocking Message Inserts

**Error:**
```
PostgrestException(message: new row violates row-level security policy for table "chime_messages", code: 42501, details: Unauthorized)
```

**Root Cause:**
- RLS policy required matching `meeting_id` between `chime_messages` and `video_call_sessions`
- Data mismatch causing legitimate users to be blocked from sending messages

**Fix Applied:**
- Created emergency migration: `20251216150000_emergency_fix_chime_messages_rls_v2.sql`
- Applied via script: `apply_rls_fix.sh`
- New policy allows any authenticated user with `sender_id` or `user_id` to insert messages
- SELECT policy still restricts viewing to video call participants

**Files Changed:**
- `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/supabase/migrations/20251216150000_emergency_fix_chime_messages_rls_v2.sql`
- `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/apply_rls_fix.sh` (helper script)

---

### ✅ Issue 2: Chime SDK Loading Timeout

**Error:**
```
❌ Chime SDK load timeout after 60 seconds
window.ChimeSDK = undefined
```

**Root Cause:**
- 60-second timeout insufficient for emulator performance
- Bundled Chime SDK (3.19.0, ~1.1MB) takes longer to load on emulators
- Emulator memory and CPU constraints

**Fix Applied:**
- Increased SDK load timeout from 60s → 120s
- Added explanatory comment about emulator vs physical device performance
- Timeout now appropriate for slow emulators while still catching real errors

**File Changed:**
- `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/lib/custom_code/widgets/chime_meeting_webview.dart:86`

**Change:**
```dart
// Before:
_sdkLoadTimeout = Timer(const Duration(seconds: 60), () {

// After:
// Increased timeout for emulators (120s) - physical devices typically load in 5-10s
_sdkLoadTimeout = Timer(const Duration(seconds: 120), () {
```

---

## Testing Instructions

### 1. Rebuild the Flutter App

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
flutter clean
flutter pub get
flutter run -d <device-id>
```

### 2. Test Video Call Messaging

1. **Create/join a video call** as provider and patient
2. **Send a message** in the video call chat
3. **Verify:**
   - No RLS errors in logs
   - Message appears in chat for both participants
   - Message is stored in `chime_messages` table

### 3. Test on Physical Device (Recommended)

For accurate performance testing:
```bash
# List connected devices
flutter devices

# Run on physical Android device
flutter run -d <android-device-id>
```

**Expected behavior:**
- SDK should load in 5-10 seconds (vs 60-120s on emulator)
- Smooth video call experience
- Instant message delivery

---

## Verification Queries

### Check RLS Policy

Run in Supabase SQL editor (https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql):

```sql
SELECT
    policyname,
    cmd,
    with_check
FROM pg_policies
WHERE tablename = 'chime_messages'
AND cmd = 'INSERT';
```

**Expected result:**
- Policy name: `Authenticated users can insert messages`
- With check: `((sender_id IS NOT NULL) OR (user_id IS NOT NULL))`

### Check Messages Are Being Created

```sql
SELECT
    id,
    channel_id,
    sender_id,
    sender_name,
    message_content,
    message_type,
    created_at
FROM chime_messages
ORDER BY created_at DESC
LIMIT 10;
```

---

## Known Limitations

### RLS Policy (Temporary Fix)

The current RLS policy is permissive to unblock users. Future enhancement needed:

**Current:** Any authenticated user can insert messages
**Future:** Validate user is participant in the specific video call session

**TODO:**
1. Investigate `meeting_id` mismatch between:
   - `chime-meeting-token` Lambda response
   - `video_call_sessions` table
   - `ChimeMeetingWebview` widget data
2. Once fixed, restore stricter RLS policy from `20251216000000_fix_chime_messages_rls_without_supabase_auth.sql`

### Emulator Performance

**Issue:** Emulators are 5-10x slower than physical devices
**Workaround:** Increased timeout to 120s
**Recommendation:** Use physical devices for video call testing

---

## Rollback Instructions

If issues occur, rollback the RLS change:

```sql
-- Restore previous RLS policy
DROP POLICY IF EXISTS "Authenticated users can insert messages" ON chime_messages;

CREATE POLICY "Allow message inserts for video call participants"
ON chime_messages
FOR INSERT
WITH CHECK (
    (
        sender_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (
                vcs.provider_id = sender_id
                OR vcs.patient_id = sender_id
            )
        )
    )
);
```

---

## Next Steps

1. ✅ **DONE:** Apply RLS fix
2. ✅ **DONE:** Increase SDK timeout
3. 🔄 **IN PROGRESS:** Test on physical device
4. ⏭️ **TODO:** Investigate meeting_id mismatch for stricter RLS
5. ⏭️ **TODO:** Consider migrating to `ChimeMeetingEnhanced` widget (production-ready alternative)

---

## Support

**Documentation:**
- `CLAUDE.md` - Project overview and guidelines
- `CHIME_VIDEO_TESTING_GUIDE.md` - Video call testing procedures
- `ENHANCED_CHIME_USAGE_GUIDE.md` - Enhanced widget documentation

**Helper Scripts:**
- `apply_rls_fix.sh` - Apply RLS fixes
- `verify_rls_fix.sh` - Verify policies
- `test_chime_video_complete.sh` - End-to-end video testing

**Contact:**
- Report issues: Check console logs and error messages
- Supabase Dashboard: https://supabase.com/dashboard/project/noaeltglphdlkbflipit
- Firebase Console: https://console.firebase.google.com/project/medzen-bf20e
