import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/payment_referal/payment_referal_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_credit_card_form.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
import 'payment_widget.dart' show PaymentWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class PaymentModel extends FlutterFlowModel<PaymentWidget> {
  ///  Local state fields for this component.

  String? userPhoneNumber;

  ///  State fields for stateful widgets in this component.

  // State field(s) for PaymentMethod widget.
  String? paymentMethodValue;
  FormFieldController<String>? paymentMethodValueController;
  // State field(s) for CreditCardForm widget.
  final creditCardFormKey = GlobalKey<FormState>();
  CreditCardModel creditCardInfo = emptyCreditCard();
  // Stores action output result for [Backend Call - API (Initialize Payment)] action in Button widget.
  ApiCallResponse? initialisepayment;
  // Stores action output result for [Backend Call - API (Mobile Money)] action in Button widget.
  ApiCallResponse? mobileMoney;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AppointmentsRow? appointment;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
