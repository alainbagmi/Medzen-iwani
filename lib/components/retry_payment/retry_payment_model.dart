import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/payment_progress/payment_progress_widget.dart';
import '/components/payment_referal/payment_referal_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'retry_payment_widget.dart' show RetryPaymentWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class RetryPaymentModel extends FlutterFlowModel<RetryPaymentWidget> {
  ///  Local state fields for this component.

  String? phoneNumber;

  ///  State fields for stateful widgets in this component.

  // State field(s) for PaymentMethod widget.
  String? paymentMethodValue;
  FormFieldController<String>? paymentMethodValueController;
  // Stores action output result for [Backend Call - API (Mobile Money)] action in Button widget.
  ApiCallResponse? payment;
  // Stores action output result for [Backend Call - API (GetPaymentStatus)] action in Button widget.
  ApiCallResponse? paymentstatus;
  // Stores action output result for [Backend Call - API (GetPaymentStatus)] action in Button widget.
  ApiCallResponse? paymentstatus1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
