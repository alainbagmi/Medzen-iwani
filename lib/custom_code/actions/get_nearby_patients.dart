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

/// Gets nearby patients from a given location.
///
/// This function is intended for medical providers to find nearby patients.
/// Can optionally filter to only show blood donors.
///
/// [latitude] - Search center latitude (-90 to 90)
/// [longitude] - Search center longitude (-180 to 180)
/// [maxDistanceKm] - Maximum search radius in kilometers (default 50)
/// [bloodDonorsOnly] - If true, only returns patients who are blood donors
/// [limit] - Maximum number of results (default 50)
///
/// Returns a list of patients with:
/// - patient_id: UUID of the patient
/// - full_name: Patient's full name
/// - avatar_url: Profile picture URL
/// - phone_number: Contact number
/// - country: Country
/// - is_blood_donor: Whether they are a registered blood donor
/// - blood_type: Blood type
/// - blood_donor_status: Donor status
/// - latitude, longitude: Coordinates
/// - distance_km: Distance in kilometers
/// - last_seen_at: Last activity timestamp
Future<List<dynamic>> getNearbyPatients(
  double latitude,
  double longitude,
  double maxDistanceKm,
  bool bloodDonorsOnly,
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
      'get_nearby_patients',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'max_distance_km': maxDistanceKm,
        'blood_donors_only': bloodDonorsOnly,
        'result_limit': limit,
      },
    );

    if (result is List) {
      return result;
    }

    return [];
  } catch (e) {
    debugPrint('Error getting nearby patients: $e');
    return [];
  }
}
