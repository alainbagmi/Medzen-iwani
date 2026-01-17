# Ready to Test Video Calls - Quick Start Guide

**Date:** December 15, 2025
**Status:** ✅ All fixes deployed, ready for testing
**Issue Addressed:** 401 "User not found in database" authentication error

---

## What Was Fixed

### 1. Enhanced Debugging ✅ DEPLOYED
- Added detailed JWT verification logging
- Shows extracted Firebase UID before database query
- Displays database query results
- Identifies exact failure point

### 2. Schema Correction ✅ DEPLOYED
- Fixed column name: `display_name` → `full_name`
- Edge Function now queries correct column
- Test script updated to match

### 3. Configuration Verified ✅ CONFIRMED
- Firebase Project ID: `medzen-bf20e` (matching)
- User exists in database
- Service role key working

---

## Test the Fix - Quick Steps

### Option 1: Use the Flutter App (RECOMMENDED)

**Step 1:** Open Supabase Dashboard
```
https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions
```
- Click "chime-meeting-token"
- Click "Logs" tab
- Keep tab open

**Step 2:** Try Video Call in App
1. Log in as: `+12406156089@medzen.com`
2. Navigate to an appointment
3. Click "Join Video Call"

**Step 3:** Check Logs
Refresh Dashboard and look for:
```
✓ Success Case:
🔍 Verifying Firebase token...
📋 Token payload: {
  extractedUid: "jt3xBjcPEdQzltsC9hEkzBzqbWz1"
}
🔍 Looking up user in database...
📊 Database query result: {
  found: true,
  userData: { id: "...", email: "..." }
}
✓ Auth Success
```

OR

```
❌ Failure Case:
📊 Database query result: {
  found: false,  <-- WHY?
  error: { ... }
}
```

### Option 2: Run Test Script

```bash
# Verify user exists
export SUPABASE_SERVICE_ROLE_KEY="your-key"
./test_video_call_auth.sh
```

Expected output:
```
✅ User exists in Supabase
   ID: 31ce65da-b802-4550-be29-da0694f47b6f
   Email: +12406156089@medzen.com
   Firebase UID: jt3xBjcPEdQzltsC9hEkzBzqbWz1
```

---

## What the Logs Will Show

### If Authentication Succeeds ✅

```
=== Chime Meeting Token Request ===
🔍 Verifying Firebase token...
=== JWT Verification START ===
✓ Token structure valid
✓ Header decoded: RS256
✓ Payload decoded
✓ Token not expired
✓ Issuer valid
✓ Audience valid: medzen-bf20e
✓ RSA signature verified
=== Firebase JWT Verified Successfully ===

📋 Token payload: {
  user_id: "jt3xBjcPEdQzltsC9hEkzBzqbWz1",
  sub: "jt3xBjcPEdQzltsC9hEkzBzqbWz1",
  email: "+12406156089@medzen.com",
  extractedUid: "jt3xBjcPEdQzltsC9hEkzBzqbWz1"
}

🔍 Looking up user in database with Firebase UID: jt3xBjcPEdQzltsC9hEkzBzqbWz1

📊 Database query result: {
  found: true,
  error: null,
  userData: {
    id: "31ce65da-b802-4550-be29-da0694f47b6f",
    email: "+12406156089@medzen.com",
    firebase_uid: "jt3xBjcPEdQzltsC9hEkzBzqbWz1",
    full_name: "Demo  Doctor1"
  }
}

✓ Auth Success - User: 31ce65da-b802-4550-be29-da0694f47b6f +12406156089@medzen.com
Action: create
Appointment ID: ...
Creating meeting...
✓ Meeting created: ...
✓ Attendee created: ...
```

**Result:** Video call loads successfully 🎉

### If Authentication Still Fails ❌

```
🔍 Verifying Firebase token...
❌ [Specific error at specific step]
```

OR

```
📊 Database query result: {
  found: false,
  error: { code: "...", message: "..." }
}
```

**Action:** Review logs to identify which step failed

---

## Files Changed

| File | Change | Status |
|------|--------|--------|
| `supabase/functions/chime-meeting-token/index.ts` | Added detailed logging, fixed column name | ✅ Deployed |
| `test_video_call_auth.sh` | User verification script | ✅ Created |
| `VIDEO_CALL_AUTH_DEBUG_STATUS.md` | Debugging guide | ✅ Created |
| `VIDEO_CALL_AUTH_FIX_SUMMARY.md` | Fix summary | ✅ Created |
| `AWS_CHIME_SDK_V3_DEPLOYMENT.md` | Updated troubleshooting | ✅ Updated |

---

## Success Criteria

Video calls are working when:
- [ ] User logs in to app
- [ ] Joins video call without 401 error
- [ ] Chime meeting loads
- [ ] Logs show `found: true`
- [ ] Video/audio streams successfully

---

## If It Still Doesn't Work

Check the logs for one of these issues:

### Issue 1: JWT Verification Fails
**Log shows:** `❌ Token structure invalid` or `RSA signature failed`
**Cause:** Invalid or expired Firebase token
**Fix:** Ensure app uses correct Firebase project (`medzen-bf20e`)

### Issue 2: UID Mismatch
**Log shows:** `extractedUid: "DIFFERENT_UID"`
**Cause:** Token is for different user
**Fix:** Verify correct user is logged in

### Issue 3: Database Query Error
**Log shows:** `error: { code: "...", message: "..." }`
**Cause:** Database issue
**Fix:** Based on specific error message

### Issue 4: User Not Found
**Log shows:** `found: false` with correct UID
**Cause:** User missing from database or RLS blocking query
**Fix:** Run test script to verify user exists, check RLS policies

---

## Quick Reference

| Resource | URL/Command |
|----------|-------------|
| **Supabase Logs** | https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions |
| **Test Script** | `./test_video_call_auth.sh` |
| **Debug Guide** | `VIDEO_CALL_AUTH_DEBUG_STATUS.md` |
| **Fix Summary** | `VIDEO_CALL_AUTH_FIX_SUMMARY.md` |
| **Deployment Doc** | `AWS_CHIME_SDK_V3_DEPLOYMENT.md` |

---

## Summary

**Problem:** 401 error prevented video calls
**Root Cause:** Insufficient logging + wrong column name
**Fix Applied:**
1. Enhanced logging for full visibility
2. Fixed `display_name` → `full_name`
3. Verified configuration
4. Deployed all changes

**Status:** ✅ Ready for testing
**Next Action:** Attempt video call and check Dashboard logs

---

**Expected Result:** Video call authentication should now succeed with full logging showing each step of the verification process. If it still fails, the logs will show exactly where and why.
