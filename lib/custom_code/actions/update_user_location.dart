// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

/// Updates the user's location in the database using PostGIS.
///
/// [userId] - The UUID of the user to update
/// [latitude] - Latitude coordinate (-90 to 90)
/// [longitude] - Longitude coordinate (-180 to 180)
///
/// Returns true if the location was updated successfully, false otherwise.
Future<bool> updateUserLocation(
  String userId,
  double latitude,
  double longitude,
) async {
  try {
    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      debugPrint('Invalid latitude: $latitude. Must be between -90 and 90.');
      return false;
    }
    if (longitude < -180 || longitude > 180) {
      debugPrint(
          'Invalid longitude: $longitude. Must be between -180 and 180.');
      return false;
    }

    // Call the Supabase RPC function to update user location
    final result = await SupaFlow.client.rpc(
      'update_user_location',
      params: {
        'p_user_id': userId,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );

    // The function returns a boolean
    if (result is bool) {
      return result;
    }

    // If we get here without error, assume success
    return true;
  } catch (e) {
    debugPrint('Error updating user location: $e');
    return false;
  }
}
