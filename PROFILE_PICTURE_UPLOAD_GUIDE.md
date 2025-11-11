# Profile Picture Upload Guide

## Overview

The `upload-profile-picture` Edge Function automatically handles profile picture uploads with these features:

✅ **One Picture Per User** - Automatically deletes old profile pictures when uploading a new one
✅ **File Validation** - Checks file type (JPEG, PNG, GIF, WebP) and size (max 5MB)
✅ **Authentication** - Requires authenticated user (Firebase Auth → Supabase Auth)
✅ **Automatic Cleanup** - Removes old files to save storage space
✅ **Public URLs** - Returns immediate public URL for the uploaded image

## Usage in Flutter

### Method 1: Using Supabase Client (Recommended)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

Future<String?> uploadProfilePicture() async {
  try {
    // Step 1: Pick image from gallery or camera
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) {
      print('No image selected');
      return null;
    }

    // Step 2: Read file as bytes
    final File file = File(image.path);
    final bytes = await file.readAsBytes();

    // Step 3: Get auth token
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      throw Exception('User not authenticated');
    }

    // Step 4: Create multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${supabase.supabaseUrl}/functions/v1/upload-profile-picture'),
    );

    // Add headers
    request.headers['Authorization'] = 'Bearer ${session.accessToken}';
    request.headers['apikey'] = supabase.supabaseKey;

    // Add file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    // Step 5: Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String publicUrl = data['data']['publicUrl'];

      print('Upload successful: $publicUrl');
      print('Deleted ${data['data']['deletedOldFiles']} old file(s)');

      return publicUrl;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Upload failed: ${error['error']}');
    }
  } catch (e) {
    print('Error uploading profile picture: $e');
    return null;
  }
}
```

### Method 2: Using FlutterFlow Custom Action

Create a custom action in FlutterFlow:

**Action Name:** `uploadProfilePictureAction`
**Parameters:**
- `imagePath` (String) - Path to the image file

**Return Type:** String (public URL)

```dart
// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
// ... other FlutterFlow imports

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

Future<String?> uploadProfilePictureAction(String imagePath) async {
  try {
    // Read file
    final File file = File(imagePath);
    final bytes = await file.readAsBytes();

    // Get Supabase client
    final supabase = SupaFlow.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      throw Exception('User not authenticated');
    }

    // Create request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${supabase.supabaseUrl}/functions/v1/upload-profile-picture'),
    );

    request.headers['Authorization'] = 'Bearer ${session.accessToken}';
    request.headers['apikey'] = supabase.supabaseKey;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['publicUrl'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']);
    }
  } catch (e) {
    print('Upload error: $e');
    return null;
  }
}
```

### Method 3: Update User Profile After Upload

After uploading, update the user's profile table with the new URL:

```dart
Future<void> updateUserProfilePicture(String publicUrl) async {
  final userId = SupaFlow.client.auth.currentUser?.id;

  if (userId == null) return;

  // Update the appropriate profile table based on user role
  // Example for medical_provider_profiles:
  await SupaFlow.client
    .from('medical_provider_profiles')
    .update({'avatar_url': publicUrl})
    .eq('user_id', userId);

  // Or for patient profiles:
  await SupaFlow.client
    .from('users')
    .update({'photo_url': publicUrl})
    .eq('id', userId);
}
```

## Complete FlutterFlow Page Example

**On Page Load:**
```dart
// Nothing special needed
```

**Upload Button Action Chain:**
1. **Upload Image Picker** → Store in page state variable `selectedImage`
2. **Custom Action**: `uploadProfilePictureAction`
   - Input: `selectedImage.path`
   - Store result in `uploadedUrl`
3. **Backend Call**: Update user profile
   - Table: `medical_provider_profiles` (or appropriate table)
   - Action: Update Row
   - Matching Row: `user_id = currentUser.id`
   - Fields: `avatar_url = uploadedUrl`
4. **Show Snackbar**: "Profile picture updated successfully"
5. **Navigate Back** or **Refresh Page**

## API Response Format

**Success (200):**
```json
{
  "success": true,
  "message": "Profile picture uploaded successfully",
  "data": {
    "path": "pics/user-uuid_1762804455606000.jpg",
    "publicUrl": "https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/profile_pictures/pics/user-uuid_1762804455606000.jpg",
    "deletedOldFiles": 1
  }
}
```

**Error (400):**
```json
{
  "success": false,
  "error": "Invalid file type. Allowed: image/jpeg, image/jpg, image/png, image/gif, image/webp"
}
```

## File Constraints

- **Max Size:** 5MB
- **Allowed Types:** JPEG, JPG, PNG, GIF, WebP
- **Storage Path:** `profile_pictures/pics/{user_id}_{timestamp}.{ext}`
- **Auto-Cleanup:** Old pictures are automatically deleted

## Security

✅ Requires authentication (Supabase JWT token)
✅ Each user can only upload their own picture
✅ Validates file type and size server-side
✅ Uses service role key to clean up old files (not exposed to client)
✅ RLS policies enforce ownership on update/delete

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Unauthorized" error | Ensure user is logged in with Supabase auth |
| "Invalid file type" | Use only JPEG, PNG, GIF, or WebP images |
| "File size exceeds limit" | Compress image before upload (max 5MB) |
| Old files not deleted | Check Edge Function logs: `npx supabase functions logs upload-profile-picture` |
| No public URL returned | Check response.statusCode and error message |

## Testing

```bash
# View function logs
npx supabase functions logs upload-profile-picture --tail

# Test with curl
curl -X POST \
  https://noaeltglphdlkbflipit.supabase.co/functions/v1/upload-profile-picture \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "apikey: YOUR_ANON_KEY" \
  -F "file=@/path/to/image.jpg"
```

## Notes

- The function automatically uses the authenticated user's ID from the JWT token
- File naming pattern: `pics/{user_id}_{timestamp}.{extension}`
- Old files are deleted asynchronously after upload succeeds
- If deletion fails, upload still succeeds (logged as warning)
- Public URLs are immediately available (bucket is public for reading)
