import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'reset_password_widget.dart' show ResetPasswordWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ResetPasswordModel extends FlutterFlowModel<ResetPasswordWidget> {
  ///  Local state fields for this component.

  String? resetphone;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (AWS Reset Pwd)] action in Button widget.
  ApiCallResponse? apiResultiz7;
  // Stores action output result for [Backend Call - API (Twillio Send sms)] action in Button widget.
  ApiCallResponse? apiResultl69;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
