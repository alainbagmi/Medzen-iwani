// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/uploaded_file.dart';

import 'dart:typed_data';

/// Uploads a profile picture to Supabase Storage and returns the public URL
///
/// This function:
/// 1. Validates the image bytes and file size (max 5MB)
/// 2. Uploads the image to Supabase Storage bucket 'profile_pictures'
/// 3. Returns the public URL for the uploaded image
/// 4. Handles errors gracefully and logs them for debugging
///
/// The existing database trigger will automatically delete old profile pictures
/// to maintain one picture per user.
///
/// Returns the public URL on success, null on failure.
Future<String?> uploadProfilePicture(
  List<int> imageBytes,
  String fileName,
) async {
  try {
    // Validate input
    if (imageBytes.isEmpty) {
      debugPrint('❌ uploadProfilePicture: imageBytes is empty');
      return null;
    }

    // Validate file size (5MB max)
    const maxSizeBytes = 5 * 1024 * 1024; // 5MB
    if (imageBytes.length > maxSizeBytes) {
      debugPrint(
          '❌ uploadProfilePicture: File size ${imageBytes.length} bytes exceeds 5MB limit');
      return null;
    }

    // Get Supabase client
    final supabase = SupaFlow.client;

    // Get current user session
    final session = supabase.auth.currentSession;
    if (session == null) {
      debugPrint('❌ uploadProfilePicture: User not authenticated');
      return null;
    }

    final userId = session.user.id;
    debugPrint('📤 uploadProfilePicture: Starting upload for user $userId');

    // Generate unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = _getFileExtension(fileName);
    final uploadFileName = 'profile_${userId}_$timestamp$fileExtension';
    final storagePath = 'pics/$uploadFileName';

    debugPrint('📤 uploadProfilePicture: Uploading to path: $storagePath');

    // Convert List<int> to Uint8List for Supabase Storage
    final uint8ImageBytes = Uint8List.fromList(imageBytes);

    // Upload to Supabase Storage
    // The RLS policies will validate:
    // - bucket_id = 'profile_pictures'
    // - path starts with 'pics/'
    // - auth.uid() IS NOT NULL
    await supabase.storage
        .from('profile_pictures')
        .uploadBinary(storagePath, uint8ImageBytes);

    debugPrint('✅ uploadProfilePicture: Upload successful');

    // Get public URL
    final publicUrl =
        supabase.storage.from('profile_pictures').getPublicUrl(storagePath);

    debugPrint('✅ uploadProfilePicture: Public URL: $publicUrl');

    // Note: The database trigger 'enforce_one_profile_picture_per_user'
    // will automatically delete old profile pictures for this user

    return publicUrl;
  } catch (e) {
    debugPrint('❌ uploadProfilePicture error: $e');
    // Return null to trigger error handling in the UI
    return null;
  }
}

/// Helper function to extract file extension from filename
String _getFileExtension(String fileName) {
  if (fileName.isEmpty) {
    return '.jpg'; // Default extension
  }

  final parts = fileName.split('.');
  if (parts.length > 1) {
    final extension = parts.last.toLowerCase();
    // Validate extension is an image type
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return '.$extension';
    }
  }

  return '.jpg'; // Default extension
}
