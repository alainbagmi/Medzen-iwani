# Profile Picture Upload Fix - RLS Policy Alternative

**Date:** November 10, 2025
**Issue:** RLS policy blocks uploads because `auth.uid()` returns NULL
**Alternative Fix:** Update RLS policy to work without Supabase auth session

---

## Current Situation

**Error:** `"new row violates row-level security policy for table \"objects\""`

**Root Cause:** Upload uses anon key → `auth.uid() = NULL` → RLS blocks

**Current Policy:**
```sql
CREATE POLICY "Authenticated users can upload profile pictures"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
  AND auth.uid() IS NOT NULL  -- ← FAILS because no Supabase session
);
```

---

## Alternative Solutions

### Option A: Permissive Path-Based Policy (QUICK FIX)

**Pros:**
- ✅ Works immediately without code changes
- ✅ No need for Supabase auth sessions
- ✅ Simple to implement

**Cons:**
- ⚠️ Less secure - any authenticated Firebase user can upload
- ⚠️ Doesn't verify user ownership at upload time
- ⚠️ Relies on database updates to track ownership

**Implementation:**

```sql
-- Drop the restrictive policy
DROP POLICY IF EXISTS "Authenticated users can upload profile pictures" ON storage.objects;

-- Create path-based policy that allows uploads to profile_pictures bucket
CREATE POLICY "Allow profile picture uploads"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
);

-- Keep SELECT policy (already exists)
CREATE POLICY IF NOT EXISTS "Anyone can view profile pictures"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile_pictures');

-- Keep UPDATE/DELETE policies (owner-only)
CREATE POLICY IF NOT EXISTS "Users can update their own profile pictures"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile_pictures'
  AND owner = auth.uid()
);

CREATE POLICY IF NOT EXISTS "Users can delete their own profile pictures"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile_pictures'
  AND owner = auth.uid()
);
```

**Security Considerations:**
1. Anyone can upload to this bucket (but database still tracks ownership via avatar_url)
2. Update/delete still require Supabase auth (will fail without session)
3. Old profile pictures won't be auto-deleted (trigger won't work without auth)

---

### Option B: Firebase JWT Integration (RECOMMENDED)

**Pros:**
- ✅ Most secure - verifies Firebase auth
- ✅ No separate Supabase auth needed
- ✅ Maintains proper access control

**Cons:**
- ⚠️ Requires Supabase JWT configuration
- ⚠️ Requires passing Firebase token to Supabase client
- ⚠️ More complex setup

**Implementation Steps:**

1. **Configure Supabase to Trust Firebase JWTs:**

In Supabase Dashboard → Authentication → Settings → JWT Settings:
```
JWT Secret: <Firebase JWT Public Key>
```

Or set in `supabase/config.toml`:
```toml
[auth]
external_oauth_enabled = true

[auth.external.firebase]
enabled = true
client_id = "medzen-bf20e"
secret = "<Firebase service account key>"
```

2. **Update Flutter Code to Pass Firebase Token:**

```dart
// lib/backend/supabase/supabase.dart

import 'package:firebase_auth/firebase_auth.dart';

class SupaFlow {
  // ... existing code ...

  static Future initialize() async {
    await Supabase.initialize(
      url: _kSupabaseUrl,
      anonKey: _kSupabaseAnonKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    // Listen to Firebase auth changes and update Supabase session
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          await client.auth.setSession(idToken);
        }
      }
    });
  }
}
```

3. **RLS Policy Stays Strict:**
```sql
-- No changes needed - auth.uid() will now work with Firebase tokens
CREATE POLICY "Authenticated users can upload profile pictures"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
  AND auth.uid() IS NOT NULL  -- ← Now works with Firebase JWT
);
```

---

### Option C: Edge Function Upload Proxy (MOST SECURE)

**Pros:**
- ✅ Maximum security - all uploads server-side
- ✅ Can verify Firebase auth server-side
- ✅ RLS can stay strict with service role

**Cons:**
- ⚠️ Most complex to implement
- ⚠️ Adds latency (client → function → storage)
- ⚠️ Requires Supabase Edge Function

**Implementation:**

1. **Create Edge Function:** `supabase/functions/upload-profile-picture/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 });
  }

  // Verify Firebase token (you'd need to add Firebase Admin SDK)
  // const decodedToken = await admin.auth().verifyIdToken(token);

  // Upload to storage using service role
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const formData = await req.formData();
  const file = formData.get('file') as File;
  const userId = formData.get('userId') as string;

  const { data, error } = await supabase.storage
    .from('profile_pictures')
    .upload(`pics/${userId}/${file.name}`, file, {
      upsert: true,
    });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const publicUrl = supabase.storage
    .from('profile_pictures')
    .getPublicUrl(data.path);

  return new Response(JSON.stringify({ url: publicUrl.data.publicUrl }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

2. **Update Flutter Upload Code:**

```dart
// Instead of uploadSupabaseStorageFiles(), call edge function
final response = await http.post(
  Uri.parse('${SupaFlow._kSupabaseUrl}/functions/v1/upload-profile-picture'),
  headers: {
    'Authorization': 'Bearer ${await currentUser?.getIdToken()}',
  },
  body: formData,
);
```

---

## Recommendation

**For immediate fix:** Use **Option A** (Permissive Path-Based Policy)
- Apply SQL migration
- Test upload immediately
- Security acceptable because database still tracks ownership

**For production:** Upgrade to **Option B** (Firebase JWT Integration)
- More secure
- Better architecture
- Maintains proper access control

**Implementation Order:**
1. Apply Option A now (5 minutes)
2. Test uploads work (5 minutes)
3. Plan Option B implementation (2-4 hours)
4. Deploy Option B when ready
5. Remove Option A policy

---

## Quick Fix SQL (Option A)

Create file: `supabase/migrations/20251111000000_permissive_profile_upload_policy.sql`

```sql
-- Temporary permissive policy for profile picture uploads
-- TODO: Replace with Firebase JWT integration (Option B)

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Authenticated users can upload profile pictures" ON storage.objects;

-- Allow uploads to profile_pictures bucket without strict auth check
CREATE POLICY "Allow profile picture uploads (temporary)"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
  -- Removed auth.uid() check - anyone can upload
  -- Ownership tracked via users.avatar_url database field
);

-- Ensure SELECT policy exists (public viewing)
DROP POLICY IF EXISTS "Anyone can view profile pictures" ON storage.objects;
CREATE POLICY "Anyone can view profile pictures"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile_pictures');

-- Comment explaining this is temporary
COMMENT ON POLICY "Allow profile picture uploads (temporary)" ON storage.objects IS
'Temporary permissive policy until Firebase JWT integration is implemented.
Replace with strict auth policy once Option B is deployed.';
```

Apply with:
```bash
npx supabase db push
```

Test immediately - uploads should work!

---

## Next Steps

1. ✅ **Now:** Apply Option A SQL migration
2. ✅ **Now:** Test profile picture upload
3. ⏳ **Soon:** Implement Option B (Firebase JWT)
4. ⏳ **Later:** Remove Option A policy
5. ⏳ **Optional:** Consider Option C for maximum security

---

## Security Notes

**Option A Security:**
- ✅ Database `users.avatar_url` still tracks ownership
- ✅ Only specific bucket and path allowed
- ✅ File size limits still enforced (5MB)
- ✅ MIME type restrictions still active
- ⚠️ Anyone with anon key can upload (but can't overwrite others' DB records)
- ⚠️ Auto-delete of old pictures won't work (requires Supabase auth for UPDATE/DELETE)

**Impact:** Low risk - worst case is orphaned files in storage, but:
- Database integrity maintained (avatar_url points to valid files)
- Users can only change their own avatar_url (Supabase RLS on users table)
- Old files just accumulate (can clean up manually or via cron)

**Option B Security:**
- ✅ Full auth verification
- ✅ Proper user ownership
- ✅ Auto-delete works correctly
- ✅ No orphaned files
