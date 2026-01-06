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

/// Gets nearby places (facilities AND providers) from the user's location.
///
/// This is the combined "near me" search that returns both facilities and
/// medical providers sorted by distance.
///
/// [latitude] - User's latitude (-90 to 90)
/// [longitude] - User's longitude (-180 to 180)
/// [radiusMeters] - Search radius in meters (default 50000 = 50km)
/// [types] - Optional filter for place types (e.g., ['facility', 'provider', 'Clinic', 'Medical Doctor'])
/// [limit] - Maximum number of results (default 50)
///
/// Returns a list of places with the following structure:
/// - place_kind: 'facility' or 'provider'
/// - id: UUID of the place
/// - name: Name of the facility or provider
/// - subtype: Facility type or provider specialty
/// - image_url: Profile image
/// - phone_number: Contact number
/// - address, city, country: Location details
/// - lat, lng: Coordinates
/// - distance_m: Distance in meters
/// - distance_km: Distance in kilometers
/// - consultation_fee: Fee for consultation
/// - is_available: Whether accepting new patients/active
/// - rating: Patient satisfaction rating (for providers)
/// - metadata: Additional type-specific information
Future<List<dynamic>> getNearbyPlaces(
  double latitude,
  double longitude,
  int radiusMeters,
  List<String>? types,
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

    // Build parameters with dynamic type to support both numbers and lists
    final Map<String, dynamic> params = {
      'p_lat': latitude,
      'p_lng': longitude,
      'p_radius_m': radiusMeters,
      'p_limit': limit,
    };

    // Add types filter if provided
    if (types != null && types.isNotEmpty) {
      params['p_types'] = types;
    }

    // Call the Supabase RPC function
    final result = await SupaFlow.client.rpc(
      'nearby_places',
      params: params,
    );

    if (result is List) {
      return result;
    }

    return [];
  } catch (e) {
    debugPrint('Error getting nearby places: $e');
    return [];
  }
}
