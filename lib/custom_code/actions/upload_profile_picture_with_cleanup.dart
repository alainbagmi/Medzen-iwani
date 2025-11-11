// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<String?> uploadProfilePictureWithCleanup(
  FFUploadedFile uploadedFile,
) async {
  try {
    final userId = currentUserUid;

    if (userId.isEmpty) {
      return null;
    }

    // Extract file extension
    final fileName = uploadedFile.name ?? 'avatar.jpg';
    final fileExtension = fileName.split('.').last.toLowerCase();

    // Determine MIME type from extension
    String mimeType;
    switch (fileExtension) {
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'png':
        mimeType = 'image/png';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      case 'webp':
        mimeType = 'image/webp';
        break;
      default:
        mimeType = 'image/jpeg'; // Default fallback
    }

    // Create unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '$timestamp.$fileExtension';

    // Create path with user subfolder: pics/{userId}/{timestamp}.ext
    final storagePath = 'pics/$userId/$newFileName';

    // Upload to Supabase Storage
    final storageBucket = SupaFlow.client.storage.from('profile_pictures');

    await storageBucket.uploadBinary(
      storagePath,
      uploadedFile.bytes!,
      fileOptions: FileOptions(contentType: mimeType),
    );

    // Get public URL
    final publicUrl = storageBucket.getPublicUrl(storagePath);

    // Update user's avatar_url in database
    await SupaFlow.client.from('users').update({
      'avatar_url': publicUrl,
    }).eq('firebase_uid', userId);

    // Call cleanup function to delete old pictures
    try {
      await SupaFlow.client.functions.invoke(
        'cleanup-old-profile-pictures',
        body: {'user_folder': userId},
      );
    } catch (cleanupError) {
      // Non-fatal error - upload still succeeded
    }

    return publicUrl;

  } catch (e) {
    return null;
  }
}
