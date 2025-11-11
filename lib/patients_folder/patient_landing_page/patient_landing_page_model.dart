import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/patient_bottom_nav/patient_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'patient_landing_page_widget.dart' show PatientLandingPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class PatientLandingPageModel
    extends FlutterFlowModel<PatientLandingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Patient_bottom_nav component.
  late PatientBottomNavModel patientBottomNavModel;

  @override
  void initState(BuildContext context) {
    patientBottomNavModel = createModel(context, () => PatientBottomNavModel());
  }

  @override
  void dispose() {
    patientBottomNavModel.dispose();
  }
}
