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

// Imports other custom actions
// Imports custom functions

import 'dart:math' as math;

Future<double> calculateDistanceKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) async {
  if (lat1 < -90 || lat1 > 90 || lat2 < -90 || lat2 > 90) {
    debugPrint('Error: Latitude must be between -90 and 90');
    return -1.0;
  }

  if (lng1 < -180 || lng1 > 180 || lng2 < -180 || lng2 > 180) {
    debugPrint('Error: Longitude must be between -180 and 180');
    return -1.0;
  }

  if (lat1 == lat2 && lng1 == lng2) {
    return 0.0;
  }

  const double earthRadiusKm = 6371.0;

  final double lat1Rad = lat1 * math.pi / 180.0;
  final double lat2Rad = lat2 * math.pi / 180.0;
  final double dLat = (lat2 - lat1) * math.pi / 180.0;
  final double dLng = (lng2 - lng1) * math.pi / 180.0;

  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1Rad) *
          math.cos(lat2Rad) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  final double distance = earthRadiusKm * c;

  return double.parse(distance.toStringAsFixed(2));
}
