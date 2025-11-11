# Storage Security Fixes - Summary

## Issues Identified

### 1. Bucket Configuration Mismatch
**Problem:** `profile_pictures` bucket was marked as `public: false` but had RLS policies allowing public access. App was trying to access via `/storage/v1/object/public/...` URLs causing 400 errors.

**Fix:** Updated bucket to `public: true`
```sql
UPDATE storage.buckets SET public = true WHERE id = 'profile_pictures';
```

### 2. Insecure RLS Policies
**Problem:** Original policies were dangerously permissive:
- ❌ Anonymous users could upload files (spam/abuse risk)
- ❌ Anyone could update ANY file (data corruption risk)
- ❌ Anyone could delete ANY file (data loss risk)
- ❌ No ownership verification

**Fix:** Implemented secure RLS policies:
```
✅ SELECT (view): Public (anyone can view profile pictures)
✅ INSERT (upload): Authenticated users only
✅ UPDATE: Authenticated users, own files only (owner = auth.uid())
✅ DELETE: Authenticated users, own files only (owner = auth.uid())
```

### 3. Multiple Profile Pictures Per User
**Problem:** Users could upload multiple profile pictures, wasting storage and causing confusion about which image to display.

**Fix:** Created `upload-profile-picture` Edge Function that:
- ✅ Validates file type (JPEG, PNG, GIF, WebP) and size (5MB max)
- ✅ Uploads new profile picture
- ✅ Automatically deletes all old profile pictures for that user
- ✅ Returns public URL immediately

## Files Created

### Migrations
1. `20251110195500_fix_profile_pictures_bucket_public.sql` - Makes bucket public
2. `20251110200000_fix_profile_pictures_rls_policies.sql` - Secure RLS policies
3. `20251110201000_one_profile_picture_per_user.sql` - Attempted trigger (not used, replaced by Edge Function)

### Edge Function
- `supabase/functions/upload-profile-picture/index.ts` - Profile picture upload handler

### Documentation
- `PROFILE_PICTURE_UPLOAD_GUIDE.md` - Complete usage guide for Flutter/FlutterFlow
- `STORAGE_SECURITY_FIXES_SUMMARY.md` - This file

## Deployment Status

✅ **Bucket Configuration:** Applied (bucket is now public)
✅ **RLS Policies:** Applied (secure policies active)
✅ **Edge Function:** Deployed and active (version 1)

## Current Configuration

### Bucket: `profile_pictures`
```json
{
  "id": "profile_pictures",
  "public": true,
  "file_size_limit": 5242880,  // 5MB
  "allowed_mime_types": ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"]
}
```

### RLS Policies
| Policy Name | Operation | Who | Condition |
|-------------|-----------|-----|-----------|
| Public can view profile pictures | SELECT | public | bucket_id = 'profile_pictures' |
| Authenticated users can upload profile pictures | INSERT | authenticated | bucket_id = 'profile_pictures' AND folder = 'pics' |
| Users can update own profile pictures | UPDATE | authenticated | bucket_id = 'profile_pictures' AND owner = auth.uid() |
| Users can delete own profile pictures | DELETE | authenticated | bucket_id = 'profile_pictures' AND owner = auth.uid() |

### Edge Functions
```
Function: upload-profile-picture
Status: ACTIVE
Version: 1
Endpoint: https://noaeltglphdlkbflipit.supabase.co/functions/v1/upload-profile-picture
```

## How to Use

### In Flutter App

```dart
// 1. Call the edge function with user's auth token
final response = await uploadProfilePictureAction(imageFile.path);

// 2. Get the public URL from response
final publicUrl = response['data']['publicUrl'];

// 3. Update user profile with new URL
await SupaFlow.client
  .from('medical_provider_profiles')
  .update({'avatar_url': publicUrl})
  .eq('user_id', currentUserId);
```

See `PROFILE_PICTURE_UPLOAD_GUIDE.md` for complete implementation examples.

## Security Improvements

### Before
- 🔴 **Anonymous uploads:** Anyone could spam the bucket
- 🔴 **No ownership:** Files had no owner tracking
- 🔴 **Unrestricted access:** Anyone could modify/delete any file
- 🔴 **Multiple files:** Users could upload unlimited pictures

### After
- 🟢 **Authenticated uploads:** Only logged-in users can upload
- 🟢 **Owner tracking:** Supabase automatically sets owner = auth.uid()
- 🟢 **Ownership enforcement:** Users can only modify their own files
- 🟢 **One file per user:** Old pictures automatically deleted

## Testing

### Manual Test
```bash
# View upload logs
npx supabase functions logs upload-profile-picture --tail

# Test upload with curl
curl -X POST \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/upload-profile-picture \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "apikey: YOUR_ANON_KEY" \
  -F "file=@test.jpg"
```

### Verify in Database
```sql
-- Check current files
SELECT
  name,
  owner,
  created_at,
  metadata->>'size' as size_bytes
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
ORDER BY created_at DESC;

-- Verify each user has only one file
SELECT
  owner,
  COUNT(*) as file_count
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
GROUP BY owner
HAVING COUNT(*) > 1;  -- Should return 0 rows
```

## Next Steps

1. **Update existing Flutter upload code** to use the new Edge Function
2. **Test the upload flow** in the app (dev environment first)
3. **Monitor edge function logs** for the first few uploads
4. **Clean up orphaned files** (optional - files with owner = NULL)
5. **Update user profile tables** to reference the new URL structure

## Rollback Plan (if needed)

```sql
-- Rollback to old policies (NOT RECOMMENDED - insecure)
DROP POLICY "Public can view profile pictures" ON storage.objects;
DROP POLICY "Authenticated users can upload profile pictures" ON storage.objects;
DROP POLICY "Users can update own profile pictures" ON storage.objects;
DROP POLICY "Users can delete own profile pictures" ON storage.objects;

-- Recreate old policies (INSECURE - only for emergency rollback)
CREATE POLICY "Allow public to view profile_pictures"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'profile_pictures');

CREATE POLICY "Allow anon uploads to profile_pictures"
ON storage.objects FOR INSERT TO public
WITH CHECK (bucket_id = 'profile_pictures');
```

## Monitoring

**Check for issues:**
```bash
# Edge function errors
npx supabase functions logs upload-profile-picture | grep -i error

# Check for duplicate files per user
# Run the SQL query above under "Verify in Database"
```

**Expected behavior:**
- Each user should have exactly 1 profile picture in `pics/` folder
- All files should have `owner` field set (not NULL)
- Upload requests should return 200 with publicUrl
- Old files should be automatically deleted

## Notes

- The `owner` field is **automatically set** by Supabase when an authenticated user uploads
- Edge function uses **service role key** to delete old files (bypassing RLS)
- File naming pattern: `pics/{user_id}_{timestamp}.{extension}`
- Public URLs work immediately (bucket is public for reading)
- Edge function has CORS enabled for browser-based uploads

## Contact

For issues or questions, check:
1. Edge function logs: `npx supabase functions logs upload-profile-picture`
2. Storage RLS policies: Query `pg_policies` table
3. Bucket configuration: Query `storage.buckets` table
