import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import 'adminrejection_dialogue_widget.dart' show AdminrejectionDialogueWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AdminrejectionDialogueModel
    extends FlutterFlowModel<AdminrejectionDialogueWidget> {
  ///  Local state fields for this component.

  bool submitrejectionSelected = false;

  ///  State fields for stateful widgets in this component.

  // State field(s) for Reasons widget.
  FormFieldController<List<String>>? reasonsValueController;
  List<String>? get reasonsValues => reasonsValueController?.value;
  set reasonsValues(List<String>? val) => reasonsValueController?.value = val;
  // Stores action output result for [Backend Call - API (AWS SMS)] action in Button widget.
  ApiCallResponse? awssms;
  // Stores action output result for [Backend Call - API (Twillio Send sms)] action in Button widget.
  ApiCallResponse? twilliosms;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
