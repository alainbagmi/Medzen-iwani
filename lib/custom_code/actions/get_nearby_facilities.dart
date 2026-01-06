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

import 'index.dart';
import '/flutter_flow/custom_functions.dart';

Future<List<dynamic>> getNearbyFacilities(
  double latitude,
  double longitude,
  double maxDistanceKm,
  int resultLimit,
) async {
  try {
    if (latitude < -90 || latitude > 90) {
      debugPrint('Invalid latitude: $latitude');
      return [];
    }
    if (longitude < -180 || longitude > 180) {
      debugPrint('Invalid longitude: $longitude');
      return [];
    }

    final result = await SupaFlow.client.rpc(
      'get_nearby_facilities',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'max_distance_km': maxDistanceKm,
        'result_limit': resultLimit,
      },
    );

    if (result is List) {
      return result;
    }

    return [];
  } catch (e) {
    debugPrint('Error getting nearby facilities: $e');
    return [];
  }
}
