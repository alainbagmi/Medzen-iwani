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

/// Gets nearby medical providers from the user's location.
///
/// This function searches for approved medical providers within a specified
/// distance from the given coordinates. Providers are sorted by distance.
///
/// [latitude] - Search center latitude (-90 to 90)
/// [longitude] - Search center longitude (-180 to 180)
/// [maxDistanceKm] - Maximum search radius in kilometers (default 50)
/// [limit] - Maximum number of results (default 20)
///
/// Returns a list of providers with:
/// - provider_id: UUID of the provider profile
/// - user_id: UUID of the user
/// - provider_number: Provider registration number
/// - full_name: Provider's full name
/// - professional_role: Role (Medical Doctor, Nurse, etc.)
/// - primary_specialization: Medical specialty
/// - avatar_url: Profile picture URL
/// - phone_number: Contact number
/// - facility_id: UUID of affiliated facility
/// - facility_name: Name of affiliated facility
/// - address, city, country: Location details
/// - consultation_fee: Fee for consultation
/// - is_available: Whether accepting new patients
/// - video_enabled: Whether video consultations are enabled
/// - rating: Patient satisfaction rating
/// - years_experience: Years of experience
/// - latitude, longitude: Coordinates
/// - distance_km: Distance in kilometers
Future<List<dynamic>> getNearbyProviders(
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
      'get_nearby_providers',
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
    debugPrint('Error getting nearby providers: $e');
    return [];
  }
}
