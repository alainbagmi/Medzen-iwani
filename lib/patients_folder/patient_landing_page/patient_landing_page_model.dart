import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/chat_a_i/start_chat/start_chat_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/patient_creation/patient_creation_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/support/support_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientLandingPageModel
    extends FlutterFlowModel<PatientLandingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    topBarModel = createModel(context, () => TopBarModel());
    sideNavModel = createModel(context, () => SideNavModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    topBarModel.dispose();
    sideNavModel.dispose();
    mainBottomNavModel.dispose();
  }
}
