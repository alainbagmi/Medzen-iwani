# Supabase Auth Session Missing - Profile Picture Upload Fix

**Date:** November 10, 2025
**Issue:** RLS policy violation when uploading profile pictures
**Root Cause:** No Supabase auth session after Firebase login
**Status:** DIAGNOSIS COMPLETE - FIX REQUIRED

---

## Problem Analysis

### Error Logs Show:
```json
{
  "event_message": "new row violates row-level security policy for table \"objects\"",
  "user_name": "supabase_storage_admin",
  "query": "insert into \"objects\" (...) values (...)"
}
```

### Why This Happens:

The RLS policy requires:
```sql
AND auth.uid() IS NOT NULL  -- Requires authenticated Supabase user
```

But `auth.uid()` returns `NULL` because:
1. ✅ User is logged into Firebase
2. ❌ User is NOT logged into Supabase Auth
3. ❌ Upload uses anon key only (no session)

---

## Current Authentication Flow (Broken)

```
1. User Signs Up
   ↓
   Firebase Auth creates user (uid: abc123)
   ↓
   Firebase Cloud Function onUserCreated()
   ├─ Creates Supabase auth user (id: xyz789)
   ├─ Links via firebase_uid in metadata
   └─ Creates users table record
   ↓
   ✅ Supabase user exists but NO SESSION created

2. User Logs In
   ↓
   Firebase Auth login SUCCESS (uid: abc123)
   ↓
   App queries Supabase database with anon key
   ├─ SELECT * FROM users WHERE firebase_uid = 'abc123'  ← Works fine
   └─ Uses anon key, no auth session needed for reads
   ↓
   ❌ NO Supabase auth.signIn() call

3. User Uploads Profile Picture
   ↓
   uploadSupabaseStorageFiles() called
   ├─ Uses SupaFlow.client (has anon key only)
   ├─ No auth session token
   └─ auth.uid() = NULL  ← RLS policy FAILS
   ↓
   ❌ ERROR: "new row violates row-level security policy"
```

---

## Root Cause

**Missing Step:** After Firebase login, the app must also create a Supabase auth session.

The Cloud Function creates a Supabase user with:
```javascript
await supabase.auth.admin.createUser({
  email: user.email,
  email_confirm: true,
  user_metadata: { firebase_uid: user.uid }
});
```

But this:
- ✅ Creates the Supabase user account
- ❌ Does NOT give the Flutter app a session token
- ❌ Does NOT create a password for the user

So the Flutter app has no way to sign into Supabase.

---

## Solution Options

### Option 1: Generate Temporary Password (RECOMMENDED)

**Modify Firebase Cloud Function:**
```javascript
// In firebase/functions/index.js - onUserCreated function

exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  // Generate a temporary random password
  const tempPassword = crypto.randomBytes(32).toString('hex');

  // Create Supabase user with password
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email: user.email,
    password: tempPassword,  // ← ADD THIS
    email_confirm: true,
    user_metadata: {
      firebase_uid: user.uid,
      display_name: user.displayName || '',
      phone_number: user.phoneNumber || '',
    }
  });

  // IMPORTANT: Store temp password hash in user metadata or custom claims
  // The app will retrieve this and use it for first Supabase login
});
```

**Add Flutter Sign-In Logic:**
```dart
// After Firebase login in lib/home_pages/sign_in/sign_in_widget.dart

final user = await authManager.signInWithEmail(
  context,
  '${_model.userphone}@medzen.com',
  _model.passwordTextController1.text,
);

if (user != null) {
  // NEW: Also sign into Supabase
  await signIntoSupabase(user.email);
}

// NEW FUNCTION:
Future<void> signIntoSupabase(String email) async {
  try {
    // Get temp password from Firestore user doc or custom claims
    final tempPassword = await getSupabaseTempPassword(currentUserUid);

    // Sign into Supabase
    final response = await SupaFlow.client.auth.signInWithPassword(
      email: email,
      password: tempPassword,
    );

    if (response.session != null) {
      print('✅ Supabase session created');
      // Now auth.uid() will work in RLS policies!
    }
  } catch (e) {
    print('❌ Supabase sign-in failed: $e');
  }
}
```

### Option 2: Use Supabase Anonymous Auth + Link

**Simpler but less secure:**

```dart
// After Firebase login
final user = await authManager.signInWithEmail(...);

if (user != null) {
  // Sign in anonymously to Supabase
  final anonResponse = await SupaFlow.client.auth.signInAnonymously();

  if (anonResponse.session != null) {
    // Update user metadata to link to Firebase
    await SupaFlow.client.auth.updateUser(
      UserAttributes(
        data: {'firebase_uid': currentUserUid},
      ),
    );
  }
}
```

**Cons:**
- Less secure (anyone can create anonymous sessions)
- Harder to manage user linkage
- Not recommended for production

### Option 3: Use Service Role Key (NOT RECOMMENDED)

**Never expose service_role key in client apps** - this would bypass all RLS.

---

## Recommended Implementation Plan

### Step 1: Update Cloud Function (Backend)

**File:** `firebase/functions/index.js`

```javascript
const crypto = require('crypto');

exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  // Generate secure random password for Supabase
  const supabasePassword = crypto.randomBytes(32).toString('hex');

  // Create Supabase Auth user
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email: user.email,
    password: supabasePassword,
    email_confirm: true,
    user_metadata: {
      firebase_uid: user.uid,
      display_name: user.displayName || '',
      phone_number: user.phoneNumber || '',
    }
  });

  if (authError) {
    console.error('Supabase user creation failed:', authError);
    throw new Error(`Supabase user creation failed: ${authError.message}`);
  }

  // Store password hash in Firestore for retrieval by app
  await admin.firestore().collection('users').doc(user.uid).set({
    supabase_password_hash: crypto.createHash('sha256').update(supabasePassword).digest('hex'),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`✅ Created Supabase user ${authData.user.id} for Firebase user ${user.uid}`);

  // ... rest of function (create users table record, EHR, etc.)
});
```

### Step 2: Add Supabase Sign-In Helper (Flutter)

**Create File:** `lib/custom_code/actions/sign_into_supabase.dart`

```dart
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/auth/firebase_auth/auth_util.dart';

Future<bool> signIntoSupabase() async {
  try {
    // Get current Firebase user
    final firebaseUid = currentUserUid;
    if (firebaseUid == null || firebaseUid.isEmpty) {
      print('❌ No Firebase user to link');
      return false;
    }

    // Get user document from Firestore to retrieve password hash
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUid)
        .get();

    if (!userDoc.exists) {
      print('❌ No Firestore user document found');
      return false;
    }

    final passwordHash = userDoc.data()?['supabase_password_hash'] as String?;
    if (passwordHash == null) {
      print('❌ No Supabase password hash found');
      return false;
    }

    // Get user email
    final email = currentUserEmail;
    if (email == null || email.isEmpty) {
      print('❌ No user email found');
      return false;
    }

    // Sign into Supabase
    // Note: We can't retrieve the original password, so we need another approach
    // See Alternative below

    print('✅ Supabase sign-in initiated');
    return true;
  } catch (e) {
    print('❌ Supabase sign-in error: $e');
    return false;
  }
}
```

### Step 3: Call Sign-In After Firebase Login

**Modify:** `lib/home_pages/sign_in/sign_in_widget.dart`

```dart
final user = await authManager.signInWithEmail(
  context,
  '${_model.userphone}@medzen.com',
  _model.passwordTextController1.text,
);

if (user == null) {
  return;
}

// NEW: Sign into Supabase
await signIntoSupabase();

// Continue with existing code...
_model.resultLOgged = await UsersTable().queryRows(...);
```

---

## Alternative: Use Firebase Custom Token Exchange

**Better approach - doesn't require storing passwords:**

### Backend: Generate Custom Token

```javascript
// Firebase Cloud Function
exports.getSupabaseToken = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const firebaseUid = context.auth.uid;

  // Get linked Supabase user
  const { data: users } = await supabase
    .from('users')
    .select('id')
    .eq('firebase_uid', firebaseUid)
    .single();

  if (!users) {
    throw new functions.https.HttpsError('not-found', 'Supabase user not found');
  }

  // Generate custom token for Supabase
  // (This requires Supabase JWT secret and signing logic)
  const customToken = await generateSupabaseCustomToken(users.id);

  return { token: customToken };
});
```

### Flutter: Exchange Token

```dart
Future<bool> signIntoSupabaseWithCustomToken() async {
  try {
    // Call Firebase function to get Supabase custom token
    final result = await FirebaseFunctions.instance
        .httpsCallable('getSupabaseToken')
        .call();

    final customToken = result.data['token'] as String;

    // Sign into Supabase with custom token
    final response = await SupaFlow.client.auth.signInWithIdToken(
      provider: OAuthProvider.custom,
      idToken: customToken,
    );

    return response.session != null;
  } catch (e) {
    print('❌ Custom token exchange failed: $e');
    return false;
  }
}
```

---

## Testing After Fix

1. **Deploy Cloud Function Changes:**
   ```bash
   cd firebase/functions
   firebase deploy --only functions:onUserCreated
   ```

2. **Create New Test User:**
   ```bash
   # Old users won't have Supabase passwords
   # Create a new test user to verify the fix
   ```

3. **Login and Check Session:**
   ```dart
   // After login, verify both sessions exist
   print('Firebase: ${currentUserUid}');
   print('Supabase: ${SupaFlow.client.auth.currentUser?.id}');
   print('Session: ${SupaFlow.client.auth.currentSession != null}');
   ```

4. **Try Profile Picture Upload:**
   - Should now succeed with authenticated session
   - auth.uid() will return Supabase user ID
   - RLS policy will allow upload

---

## Next Steps

1. **Choose Solution:**
   - Option 1 (Password): Easier to implement
   - Alternative (Custom Token): More secure, no password storage

2. **Implement Backend Changes:**
   - Update `firebase/functions/index.js`
   - Deploy function

3. **Implement Flutter Changes:**
   - Add sign-in helper action
   - Call after Firebase login

4. **Test with New Users:**
   - Create new test accounts
   - Verify Supabase session creation
   - Test profile picture upload

---

## Summary

**Problem:** No Supabase auth session → `auth.uid() = NULL` → RLS blocks upload

**Solution:** Create Supabase auth session after Firebase login using one of:
1. Password-based auth (store temp password)
2. Custom token exchange (more secure)

**Impact:** After fix, all auth-required Supabase operations will work:
- ✅ Profile picture uploads
- ✅ RLS policies requiring auth.uid()
- ✅ User-specific data operations

**Estimated Fix Time:** 2-4 hours (backend + frontend + testing)
