import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/random_data_util.dart' as random_data;
import 'payment_referal_widget.dart' show PaymentReferalWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class PaymentReferalModel extends FlutterFlowModel<PaymentReferalWidget> {
  ///  Local state fields for this component.

  String? userphone;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (Initialize Payment)] action in Button widget.
  ApiCallResponse? initialisepayment;
  // Stores action output result for [Backend Call - API (Help Me Pay)] action in Button widget.
  ApiCallResponse? apiResultpdo;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
