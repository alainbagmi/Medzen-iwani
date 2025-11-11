import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/logout/logout_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'patient_profile_page_widget.dart' show PatientProfilePageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class PatientProfilePageModel
    extends FlutterFlowModel<PatientProfilePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in PatientProfile_page widget.
  List<UsersRow>? loggedUser;
  // Model for logout component.
  late LogoutModel logoutModel;

  @override
  void initState(BuildContext context) {
    logoutModel = createModel(context, () => LogoutModel());
  }

  @override
  void dispose() {
    logoutModel.dispose();
  }
}
