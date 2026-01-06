import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
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
  // Stores action output result for [Backend Call - API (AWS SMS)] action in Button widget.
  ApiCallResponse? apiResultlfg;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AppointmentsRow? appointment1;
  // Stores action output result for [Backend Call - API (Help Me Pay)] action in Button widget.
  ApiCallResponse? apiResultpdo;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AppointmentsRow? appointment;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<PaymentsRow>? paymenturl;
  // Stores action output result for [Backend Call - API (AWS SMS)] action in Button widget.
  ApiCallResponse? apiResult1qi;
  // Stores action output result for [Backend Call - API (Help Me Pay)] action in Button widget.
  ApiCallResponse? resendhelp;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
