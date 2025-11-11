import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'patient_bottom_nav_widget.dart' show PatientBottomNavWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PatientBottomNavModel extends FlutterFlowModel<PatientBottomNavWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (UserDetails)] action in Patient_bottom_nav widget.
  ApiCallResponse? userdetails;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
