import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/backend/schema/structs/index.dart';
import '/index.dart';
import 'provider_landing_page_widget.dart' show ProviderLandingPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class ProviderLandingPageModel
    extends FlutterFlowModel<ProviderLandingPageWidget> {
  ///  Local state fields for this page.

  String? userID;

  dynamic upcomingAppointment;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (PatientAppointments)] action in provider_landing_page widget.
  ApiCallResponse? patientappointment;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
