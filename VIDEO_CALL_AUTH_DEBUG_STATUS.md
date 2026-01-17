# Video Call Authentication Debug Status

**Date:** December 15, 2025
**Issue:** 401 "User not found in database" error when joining video calls
**Firebase UID:** `jt3xBjcPEdQzltsC9hEkzBzqbWz1`

---

## Issue Summary

Users are unable to join video calls, receiving this error:
```
Status code: 401
Response body: {"error":"Invalid or expired token","details":"User not found in database"}
```

**Confirmed Facts:**
- ✅ User EXISTS in Supabase database
  - Supabase ID: `31ce65da-b802-4550-be29-da0694f47b6f`
  - Email: `+12406156089@medzen.com`
  - Firebase UID: `jt3xBjcPEdQzltsC9hEkzBzqbWz1`
- ✅ Firebase token is being sent correctly in `x-firebase-token` header
- ✅ Token is fresh (force refreshed)
- ❓ Unknown why database lookup fails despite user existing

---

## Actions Taken

### 1. Enhanced Edge Function Logging ✅

**File:** `supabase/functions/chime-meeting-token/index.ts`

Added detailed debug logging to show:
- 🔍 Firebase token verification status
- 📋 Token payload (user_id, sub, email, extractedUid)
- 🔍 Firebase UID used for database query
- 📊 Database query result (found/not found, error details)
- ❌ Detailed error messages on failure

**Deployment Status:** ✅ Deployed

### 2. Verified Firebase Project ID ✅

**Android App Configuration:**
- Firebase Project ID: `medzen-bf20e` (from `android/app/google-services.json`)

**Supabase Environment Variable:**
- Set: `FIREBASE_PROJECT_ID=medzen-bf20e`
- Status: ✅ Confirmed matching

### 3. Created Test Script ✅

**File:** `test_video_call_auth.sh`

Purpose: Verify user exists in Supabase before attempting video call

**Usage:**
```bash
export SUPABASE_SERVICE_ROLE_KEY="your-key-here"
./test_video_call_auth.sh
```

**Output:**
```
✅ User exists in Supabase
   ID: 31ce65da-b802-4550-be29-da0694f47b6f
   Email: +12406156089@medzen.com
   Firebase UID: jt3xBjcPEdQzltsC9hEkzBzqbWz1
```

---

## Next Steps to Debug

### Option 1: View Logs in Supabase Dashboard (RECOMMENDED)

1. Go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions
2. Click on "chime-meeting-token" function
3. Click "Logs" tab
4. Have user try joining video call from app
5. Refresh logs and look for:

```
🔍 Verifying Firebase token...
📋 Token payload: {
  user_id: "...",
  sub: "...",
  email: "...",
  extractedUid: "..."
}
🔍 Looking up user in database with Firebase UID: ...
📊 Database query result: {
  found: true/false,
  error: ...,
  userData: ...
}
```

**What to check:**
- Does `extractedUid` match expected UID: `jt3xBjcPEdQzltsC9hEkzBzqbWz1`?
- Is `found: false` despite user existing?
- Are there any database errors?

### Option 2: Test Authentication Flow

```bash
# Run the test script to confirm user exists
./test_video_call_auth.sh
```

### Option 3: Manual Firebase Token Test

If you have a valid Firebase ID token, test the Edge Function directly:

```bash
# Get a fresh Firebase token from the app (copy from logs)
FIREBASE_TOKEN="eyJhbGciOi..."

# Test the Edge Function
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -d '{
    "action": "create",
    "appointmentId": "test-appointment-id"
  }'
```

---

## Possible Root Causes

### 1. JWT Token Issues
- **Symptom:** Token verification fails before database query
- **Check:** Look for JWT verification errors in logs
- **Fix:** Verify token format, signature, and expiration

### 2. Firebase UID Mismatch
- **Symptom:** Extracted UID doesn't match database value
- **Check:** Compare `extractedUid` in logs with database `firebase_uid`
- **Fix:** Investigate why UIDs differ (case sensitivity, prefix, encoding)

### 3. Database Query Error
- **Symptom:** Query fails with error
- **Check:** Look for database error in logs
- **Fix:** Check RLS policies, table permissions, query syntax

### 4. Token from Different Firebase Project
- **Symptom:** Token issuer doesn't match expected project
- **Check:** Verify token `iss` claim matches `https://securetoken.google.com/medzen-bf20e`
- **Fix:** Ensure app uses correct Firebase configuration

### 5. Service Role Key Issue
- **Symptom:** Database query returns "User not found" with no error
- **Check:** Verify service role key has correct permissions
- **Fix:** Regenerate service role key if corrupted

---

## Technical Details

### Authentication Flow

```
1. User logs in → Firebase Auth generates JWT token
2. Flutter app calls Edge Function with token in header
3. Edge Function:
   a. Verifies JWT signature with Firebase public keys
   b. Extracts Firebase UID from token payload
   c. Queries Supabase users table: WHERE firebase_uid = extractedUid
   d. Returns 401 if user not found
4. If successful, creates Chime meeting and returns credentials
```

### Edge Function Code (Relevant Section)

```typescript
// Line 88-135 in supabase/functions/chime-meeting-token/index.ts

const payload = await verifyFirebaseToken(firebaseTokenHeader, firebaseProjectId);
const firebaseUid = payload.user_id || payload.sub;

console.log("📋 Token payload:", {
  user_id: payload.user_id,
  sub: payload.sub,
  email: payload.email,
  extractedUid: firebaseUid
});

const { data: userData, error: userError } = await supabaseAdmin
  .from("users")
  .select("id, email, firebase_uid, display_name")
  .eq("firebase_uid", firebaseUid)
  .single();

console.log("📊 Database query result:", {
  found: !!userData,
  error: userError,
  userData: userData
});

if (userError || !userData) {
  console.error("❌ User lookup failed:", {
    firebaseUid,
    error: userError,
    message: "User not found in database"
  });
  throw new Error("User not found in database");
}
```

### Database Schema

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT,
  display_name TEXT,
  ...
);

-- Index for fast lookups
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
```

---

## Resolution Checklist

- [ ] Enhanced logging deployed
- [ ] Firebase project ID verified and set
- [ ] User existence confirmed in database
- [ ] Video call attempted from app
- [ ] Logs checked in Supabase Dashboard
- [ ] Root cause identified from logs
- [ ] Fix applied based on root cause
- [ ] Video call tested and working

---

## Expected Log Output (Success Case)

```
=== Chime Meeting Token Request ===
🔍 Verifying Firebase token...
=== JWT Verification START ===
✓ Token structure valid (3 parts)
✓ Header decoded: RS256
✓ Payload decoded
✓ Token not expired
✓ Issued-at valid
✓ Issuer valid: https://securetoken.google.com/medzen-bf20e
✓ Audience valid: medzen-bf20e
✓ Fetched Firebase public keys
✓ Matched public key for kid: abc123...
✓ Public key imported successfully
✓ RSA signature verified
=== Firebase JWT Verified Successfully ===
User ID (uid): jt3xBjcPEdQzltsC9hEkzBzqbWz1
Email: +12406156089@medzen.com

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
    display_name: "User"
  }
}

✓ Auth Success - User: 31ce65da-b802-4550-be29-da0694f47b6f +12406156089@medzen.com
```

---

## Support

For questions or issues:
1. Check Supabase Dashboard logs first
2. Run test script to verify user exists
3. Compare actual logs with expected logs above
4. Identify which step is failing

**Dashboard Link:** https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions

---

**Status:** 🔍 DEBUGGING - Awaiting log output from next video call attempt
