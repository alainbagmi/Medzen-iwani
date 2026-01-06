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

/// Gets nearby blood donors from the user's location.
///
/// This function is intended for medical providers to find nearby patients
/// who have registered as blood donors.
///
/// [latitude] - Search center latitude (-90 to 90)
/// [longitude] - Search center longitude (-180 to 180)
/// [maxDistanceKm] - Maximum search radius in kilometers (default 50)
/// [limit] - Maximum number of results (default 50)
///
/// Returns a list of blood donors with:
/// - patient_id: UUID of the patient
/// - full_name: Patient's full name
/// - avatar_url: Profile picture URL
/// - phone_number: Contact number
/// - country: Country
/// - blood_type: Blood type (A+, A-, B+, B-, AB+, AB-, O+, O-)
/// - is_blood_donor: Whether they are a registered blood donor
/// - blood_donor_status: Donor status (active, inactive, etc.)
/// - latitude, longitude: Coordinates
/// - distance_km: Distance in kilometers
/// - last_seen_at: Last activity timestamp
Future<List<dynamic>> getNearbyBloodDonors(
  double latitude,
  double longitude,
  double maxDistanceKm,
  int limit,
) async {
  try {
    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      debugPrint('Invalid latitude: $latitude. Must be between -90 and 90.');
      return [];
    }
    if (longitude < -180 || longitude > 180) {
      debugPrint(
          'Invalid longitude: $longitude. Must be between -180 and 180.');
      return [];
    }

    // Call the Supabase RPC function
    final result = await SupaFlow.client.rpc(
      'get_nearby_blood_donors',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'max_distance_km': maxDistanceKm,
        'result_limit': limit,
      },
    );

    if (result is List) {
      return result;
    }

    return [];
  } catch (e) {
    debugPrint('Error getting nearby blood donors: $e');
    return [];
  }
}
