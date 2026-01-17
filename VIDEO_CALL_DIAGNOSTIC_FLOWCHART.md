# Video Call Diagnostic Flowchart

**Purpose:** Visual decision tree for diagnosing X-Firebase-Token header issue
**Version:** Edge Function v36 (ASN.1 Parser Fix - DEPLOYED)
**Date:** December 3, 2025
**Status:** ✅ READY FOR PRODUCTION TESTING

---

## START HERE: After Testing Video Call

```
┌─────────────────────────────────────────┐
│  1. Did you test video call from app?  │
│     (Clicked "Join Video Call" button) │
└─────────────────┬───────────────────────┘
                  │
                  ▼ YES
┌─────────────────────────────────────────────────────────┐
│  2. Did you check Supabase logs IMMEDIATELY after?     │
│     Link: https://supabase.com/...logs                  │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼ YES
┌─────────────────────────────────────────────────────────┐
│  3. Do you see "=== All Request Headers ===" in logs?  │
└─────────────────┬───────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
       YES                 NO
        │                   │
        │                   ▼
        │         ┌────────────────────────────┐
        │         │ ❌ NO LOGS FOUND           │
        │         │                            │
        │         │ Possible causes:           │
        │         │ • Request never reached    │
        │         │   Edge Function            │
        │         │ • Wrong function endpoint  │
        │         │ • Network error            │
        │         │                            │
        │         │ ACTION NEEDED:             │
        │         │ 1. Retry video call        │
        │         │ 2. Check app error message │
        │         │ 3. Report app behavior     │
        │         └────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  4. In the header list, do you see a line starting     │
│     with "x-firebase-token:" or "X-Firebase-Token:"?    │
└─────────────────┬───────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
       YES                 NO
        │                   │
        │                   ▼
        │         ┌──────────────────────────────────────┐
        │         │ ❌ HEADER NOT SENT FROM FLUTTER APP  │
        │         │                                      │
        │         │ Root cause: Client-side issue       │
        │         │ Location: lib/.../join_room.dart    │
        │         │                                      │
        │         │ What this means:                    │
        │         │ • Flutter HTTP client not setting   │
        │         │   X-Firebase-Token header           │
        │         │ • Two-header pattern not working    │
        │         │   on client side                    │
        │         │                                      │
        │         │ REPORT TO ME:                       │
        │         │ ✓ Copy full header list from logs  │
        │         │ ✓ Copy app error message           │
        │         │ ✓ Confirm you're on latest build   │
        │         │                                      │
        │         │ NEXT STEP:                          │
        │         │ I will debug Flutter client code    │
        │         │ and add header logging              │
        │         └──────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  5. What does the line say?                             │
│                                                          │
│     x-firebase-token: eyJhbGci...  ← Has value?         │
│        OR                                                │
│     x-firebase-token: null/undefined  ← No value?       │
└─────────────────┬───────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
    HAS VALUE          NULL/EMPTY
        │                   │
        │                   ▼
        │         ┌──────────────────────────────────────┐
        │         │ ⚠️ HEADER PRESENT BUT EMPTY          │
        │         │                                      │
        │         │ Unusual situation - header sent     │
        │         │ but no value provided               │
        │         │                                      │
        │         │ Possible causes:                    │
        │         │ • Firebase token null in Flutter    │
        │         │ • getIdToken() failed               │
        │         │ • Variable binding error            │
        │         │                                      │
        │         │ REPORT TO ME:                       │
        │         │ ✓ Copy full log section             │
        │         │ ✓ Check app logs for Firebase      │
        │         │   authentication errors             │
        │         │                                      │
        │         │ NEXT STEP:                          │
        │         │ I will debug Firebase token         │
        │         │ retrieval in Flutter                │
        │         └──────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  6. Look further down in logs for:                      │
│     "=== Firebase JWT Verified Successfully ==="        │
│                                                          │
│     Do you see this message?                            │
└─────────────────┬───────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
       YES                 NO
        │                   │
        │                   ▼
        │         ┌──────────────────────────────────────┐
        │         │ ❌ JWT VERIFICATION FAILED           │
        │         │                                      │
        │         │ Header received but token invalid   │
        │         │                                      │
        │         │ Look for error section:             │
        │         │ "=== Auth Error Details ==="        │
        │         │                                      │
        │         │ Common errors:                      │
        │         │ • "Token expired" (refresh failed)  │
        │         │ • "Invalid signature" (wrong keys)  │
        │         │ • "Invalid issuer" (wrong project)  │
        │         │ • "Invalid audience" (config issue) │
        │         │                                      │
        │         │ REPORT TO ME:                       │
        │         │ ✓ Copy "=== Auth Error Details ===" │
        │         │ ✓ Copy full error message           │
        │         │ ✓ Copy JWT verification steps       │
        │         │   (STEP 1-12 section if present)    │
        │         │                                      │
        │         │ NEXT STEP:                          │
        │         │ I will fix JWT verification based   │
        │         │ on specific error                   │
        │         └──────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  ✅ JWT VERIFICATION SUCCESSFUL                         │
│                                                          │
│  Two-header pattern working correctly!                  │
│                                                          │
│  7. Did video call actually work in the app?            │
└─────────────────┬───────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
       YES                 NO
        │                   │
        │                   ▼
        │         ┌──────────────────────────────────────┐
        │         │ ⚠️ AUTH WORKS BUT VIDEO FAILS        │
        │         │                                      │
        │         │ Different issue - not JWT related   │
        │         │                                      │
        │         │ Possible causes:                    │
        │         │ • AWS Chime SDK error               │
        │         │ • WebView loading issue             │
        │         │ • Network connectivity              │
        │         │ • Meeting creation failed           │
        │         │                                      │
        │         │ REPORT TO ME:                       │
        │         │ ✓ What happened after auth success? │
        │         │ ✓ Any error in logs after           │
        │         │   "=== Auth Success ==="?           │
        │         │ ✓ Did meeting get created?          │
        │         │   (Check for Meeting ID in logs)    │
        │         │ ✓ Did WebView open?                 │
        │         │ ✓ Any app error messages?           │
        │         │                                      │
        │         │ NEXT STEP:                          │
        │         │ I will investigate post-auth errors │
        │         └──────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  🎉 SUCCESS - EVERYTHING WORKS!                         │
│                                                          │
│  Video call authentication and joining successful!      │
│                                                          │
│  REPORT TO ME:                                          │
│  ✓ "Video calls working perfectly!"                    │
│  ✓ Optional: Screenshot of successful logs             │
│                                                          │
│  NEXT STEP:                                             │
│  I will clean up debug logging and document success    │
└─────────────────────────────────────────────────────────┘
```

---

## Quick Reference: What to Report for Each Outcome

### Scenario A: No Logs Found
```
📋 Copy and send:
- App error message (screenshot if possible)
- What happened when you clicked "Join Video Call"
- Did loading indicator appear?
- Did anything happen at all?
```

### Scenario B: Header Not Sent
```
📋 Copy and send from logs:
=== All Request Headers ===
[entire section]
===========================

📋 Also send:
- App error message
- Confirmation you're using latest app build
```

### Scenario C: Header Empty
```
📋 Copy and send from logs:
=== All Request Headers ===
[entire section - showing null/empty token]
===========================

📋 Check app logs for:
"=== Getting Fresh JWT Token ==="
[any Firebase authentication errors]
```

### Scenario D: JWT Verification Failed
```
📋 Copy and send from logs:
=== Auth Error Details ===
[entire section]
========================

=== JWT Verification START ===
[STEP 1-12 section if present]
[Stop at the step that failed]
```

### Scenario E: Auth Works, Video Fails
```
📋 Copy and send from logs:
=== Auth Success ===
[entire section]
====================

[Any error messages after this point]

📋 Also send:
- Did WebView open?
- What did you see in the app?
- Any error messages?
```

### Scenario F: Complete Success
```
📋 Send simple confirmation:
"✅ Video calls working! JWT auth successful."

Optional: Screenshot of logs showing success
```

---

## Log Access Quick Links

🔗 **Direct Log Access:**
https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions/chime-meeting-token/logs

**Remember to click "Refresh" button to see latest logs!**

---

## Testing Reminders

✅ **Before testing:**
- Ensure you're using latest app build
- Have valid appointment with video call scheduled
- Be ready to allow camera/microphone permissions

✅ **During testing:**
- Click "Join Video Call" button
- Allow permissions when prompted
- Observe what happens (loading, errors, navigation)

✅ **After testing:**
- Check logs IMMEDIATELY (within 2-3 minutes)
- Click "Refresh" button in logs dashboard
- Find "=== All Request Headers ===" section
- Copy relevant sections based on flowchart

---

## Additional Resources

- **Quick Test Guide:** `VIDEO_CALL_QUICK_TEST.md`
- **Comprehensive Guide:** `VIDEO_CALL_DEBUG_TEST_GUIDE.md`
- **Technical Details:** `VIDEO_CALL_JWT_FIX_COMPLETE.md`

---

**Ready to test!** 🚀
Follow the flowchart based on what you observe in the logs.
