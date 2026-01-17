# Video Call Debug - Quick Test Reference

**Version:** Edge Function v36 (ASN.1 Parser Fix - DEPLOYED)
**Status:** ✅ READY FOR PRODUCTION TESTING
**Date:** December 3, 2025

## Quick Test Steps

### 1. Test Video Call
1. Open MedZen app
2. Navigate to appointment
3. Click "Join Video Call"
4. Allow camera/microphone permissions
5. Observe behavior (errors, navigation, video success/failure)

### 2. Check Logs Immediately
**🔗 Direct Link:** https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions/chime-meeting-token/logs

Click **Refresh** to see latest logs.

### 3. Find This Section in Logs

Look for:
```
=== All Request Headers ===
authorization: Bearer eyJhbGci...
content-type: application/json
x-firebase-token: eyJhbGci...  ← IS THIS LINE HERE?
===========================
X-Firebase-Token header specifically: [value or null]
```

## Quick Diagnosis

### ✅ If you see: `x-firebase-token: eyJhbGci...`
**Meaning:** Two-header pattern is working!
**Next:** Check if JWT verification succeeds in logs

### ❌ If you see: `X-Firebase-Token header specifically: null`
**Meaning:** Header not being sent from Flutter app
**Next:** Client-side debugging needed in `join_room.dart`

### ⚠️ If you see different error
**Next:** Copy complete error message and log output

## What to Report Back

Please provide:
1. **Log output** - Copy the "=== All Request Headers ===" section
2. **X-Firebase-Token line** - Is it present? What's the value?
3. **App behavior** - What error message appeared?
4. **Screenshots** - (Optional) App error or log section

## Key Information

- **Firebase Project:** medzen-bf20e
- **Supabase Project:** noaeltglphdlkbflipit
- **Edge Function:** chime-meeting-token (version 36)
- **Deployment Time:** 2025-12-03 18:08:45

## Common Errors

| Error Message | What It Means |
|---------------|---------------|
| "Missing X-Firebase-Token header" | Header not received by server |
| "Invalid or expired token" | JWT verification failed |
| "User not found in database" | Firebase UID doesn't match Supabase user |
| "Not authorized to create meeting" | User not provider/patient for appointment |

## Full Documentation

For detailed information, see: `VIDEO_CALL_DEBUG_TEST_GUIDE.md`

---

**Ready to test!** Follow steps above and report back with log output.
