import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'side_nav_widget.dart' show SideNavWidget;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class SideNavModel extends FlutterFlowModel<SideNavWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (UserDetails)] action in Row widget.
  ApiCallResponse? userData;
  // Stores action output result for [Backend Call - API (UserDetails)] action in Payments widget.
  ApiCallResponse? userDatas;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
