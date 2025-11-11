# Supabase Storage Upload Guide

## Issue Resolved

**Problem**: Files were being uploaded to flat storage paths (`user-avatars/filename.jpg`) instead of user-specific directories, causing 400 errors due to RLS policy mismatches.

**Solution**: Implemented user-specific directory structure with proper RLS policies:
- User Avatars: `user-avatars/{user_firebase_uid}/filename.jpg`
- Facility Images: `facility-images/{facility_id}/filename.jpg`
- Documents: `documents/{user_firebase_uid}/filename.pdf`

## Storage Buckets

### 1. user-avatars (Private)
- **Purpose**: Profile pictures for all 4 user types (Patient, Provider, Facility Admin, System Admin)
- **File Size Limit**: 5MB
- **Allowed Types**: JPEG, JPG, PNG, GIF, WebP
- **Public**: No (requires authentication to view)
- **Path Format**: `user-avatars/{user_firebase_uid}/{timestamp}_{filename}`

### 2. facility-images (Public)
- **Purpose**: Care center photos and logos
- **File Size Limit**: 10MB
- **Allowed Types**: JPEG, JPG, PNG, GIF, WebP
- **Public**: Yes (anyone can view)
- **Path Format**: `facility-images/{facility_id}/{timestamp}_{filename}`

### 3. documents (Private)
- **Purpose**: Medical records, prescriptions, lab results
- **File Size Limit**: 50MB
- **Allowed Types**: PDF, JPEG, JPG, PNG, DOC, DOCX
- **Public**: No (requires authentication + role-based access)
- **Path Format**: `documents/{user_firebase_uid}/{timestamp}_{filename}`

## Row-Level Security (RLS) Policies

### User Avatars
✅ Users can upload to their own directory
✅ Users can view, update, and delete their own avatars
✅ Public can view all avatars (for profile pictures in UI)

### Facility Images
✅ Facility admins can upload/update/delete images for their facilities
✅ Public can view all facility images

### Documents
✅ Users can manage their own documents
✅ Medical providers can view all documents (for patient care)
✅ Facility admins can view all documents
✅ System admins can view all documents

## Usage in FlutterFlow

### Method 1: Custom Action (Recommended)

**Step 1: Upload Media**
1. Add "Upload/Download" → "Upload Media" action
2. Configure:
   - Allow Photo: Yes
   - Source: Photo Gallery / Camera
   - Max Width/Height: Optional
3. Store result in page state variable: `uploadedFile` (Type: `FFUploadedFile`)

**Step 2: Call Custom Action**
1. Add "Custom Action" → `uploadToSupabaseStorage`
2. Configure parameters:
   - `uploadedFile`: Select page state variable from Step 1
   - `bucketName`: Type string literal:
     - `"user-avatars"` for profile pictures
     - `"facility-images"` for care center photos
     - `"documents"` for medical documents
   - `customPath`: (Optional) Leave blank to use user's Firebase UID
3. Store return value in variable: `uploadedUrl` (Type: String)

**Step 3: Save URL to Database**
1. Add "Backend Call" → "Supabase Call"
2. Update appropriate table:
   ```
   For Providers:
   Table: medical_provider_profiles
   Set: avatar_url = uploadedUrl
   Filter: user_id = Current User ID

   For Facility Admins:
   Table: facility_admin_profiles
   Set: avatar_url = uploadedUrl
   Filter: user_id = Current User ID

   For Care Centers:
   Table: facilities
   Set: image_url = uploadedUrl
   Filter: id = Facility ID
   ```

### Example: Patient Profile Picture Upload

```dart
// FlutterFlow Action Flow:
1. User taps "Upload Photo" button
2. Upload Media action → stores in uploadedFile
3. Custom Action: uploadToSupabaseStorage
   - uploadedFile: uploadedFile
   - bucketName: "user-avatars"
   → Returns: "https://...supabase.co/storage/v1/object/public/user-avatars/{uid}/1762403182962000.jpg"
4. Backend Call: Update users table
   - SET avatar_url = uploadedUrl
   - WHERE firebase_uid = currentUserUid
5. Show success message
```

### Example: Facility Image Upload (Care Center)

```dart
// FlutterFlow Action Flow:
1. Facility admin taps "Upload Facility Photo"
2. Upload Media action → stores in uploadedFile
3. Custom Action: uploadToSupabaseStorage
   - uploadedFile: uploadedFile
   - bucketName: "facility-images"
   - customPath: facilityId (from FFAppState or page parameter)
   → Returns: "https://...supabase.co/storage/v1/object/public/facility-images/{facility_id}/1762403182962000.jpg"
4. Backend Call: Update facilities table
   - SET image_url = uploadedUrl
   - WHERE id = facilityId
5. Refresh facility data in UI
```

## Error Handling

The custom action includes built-in error handling:

### Common Errors
- **"No file selected"**: User canceled upload or file picker failed
- **"Please sign in to upload files"**: User not authenticated (redirect to sign-in)
- **"Permission denied"**: RLS policy violation (check user role and path)
- **"File is too large"**: Exceeds bucket size limit

### Debugging Upload Issues

1. **Check Authentication**
   ```dart
   print('Current User UID: ${currentUserUid}');
   ```

2. **Verify Bucket Name**
   - Must be exactly: `"user-avatars"`, `"facility-images"`, or `"documents"`

3. **Check File Size**
   - user-avatars: max 5MB
   - facility-images: max 10MB
   - documents: max 50MB

4. **Verify RLS Policies**
   - Run in Supabase SQL Editor:
   ```sql
   SELECT * FROM storage.objects
   WHERE bucket_id = 'user-avatars'
   AND (storage.foldername(name))[1] = 'YOUR_FIREBASE_UID';
   ```

5. **Check Supabase Logs**
   - Go to Supabase Dashboard → Logs → Storage
   - Look for 400/403 errors
   - Verify path format matches: `{bucket}/{user_id}/{filename}`

## Migration Details

Migration: `20251106000001_fix_storage_buckets_setup.sql`

**What it does:**
1. Drops old conflicting RLS policies
2. Creates storage buckets with proper configuration
3. Sets up RLS policies for user-specific directories
4. Creates helper functions for path building

**To apply:**
```bash
npx supabase db push
```

**To verify:**
```bash
# Check buckets exist
curl "https://YOUR_PROJECT.supabase.co/storage/v1/bucket" \
  -H "apikey: YOUR_ANON_KEY"

# Should return: user-avatars, facility-images, documents
```

## Testing Checklist

- [ ] Patient can upload profile picture to `user-avatars/{patient_uid}/`
- [ ] Medical Provider can upload profile picture to `user-avatars/{provider_uid}/`
- [ ] Facility Admin can upload profile picture to `user-avatars/{admin_uid}/`
- [ ] System Admin can upload profile picture to `user-avatars/{admin_uid}/`
- [ ] Care Center can upload photos to `facility-images/{facility_id}/`
- [ ] Patient can upload documents to `documents/{patient_uid}/`
- [ ] Medical Provider can view patient documents (role-based access)
- [ ] Facility Admin can view all documents
- [ ] System Admin can view all documents
- [ ] Files uploaded to correct directory structure
- [ ] Public URLs are returned correctly
- [ ] Old files can be replaced/deleted
- [ ] File size limits are enforced
- [ ] MIME type validation works

## Security Best Practices

1. **Never expose service role key in client code** - use anon key only
2. **Always validate file types** - use `allowed_mime_types` bucket setting
3. **Enforce file size limits** - set at bucket level + client validation
4. **Use RLS policies** - never disable RLS on storage buckets
5. **Audit access logs** - regularly check Supabase logs for unauthorized access
6. **Rotate URLs periodically** - for sensitive documents, consider signed URLs
7. **Scan for malware** - implement virus scanning for uploaded files (future enhancement)

## Future Enhancements

- [ ] Add virus scanning for uploaded files (ClamAV integration)
- [ ] Implement automatic image optimization/resizing
- [ ] Add support for video uploads (separate bucket)
- [ ] Implement CDN caching for public images
- [ ] Add watermarking for facility images
- [ ] Implement file versioning/history
- [ ] Add bulk upload functionality
- [ ] Implement signed URLs for temporary document access
- [ ] Add image compression before upload (client-side)
- [ ] Implement progress indicators for large files

## Support

For issues or questions:
1. Check Supabase Dashboard → Storage → Logs
2. Review RLS policies in Supabase Dashboard → Authentication → Policies
3. Test upload with Supabase Storage Explorer
4. Check Flutter console logs for debug messages
5. Verify migration applied: `npx supabase db remote commit`
