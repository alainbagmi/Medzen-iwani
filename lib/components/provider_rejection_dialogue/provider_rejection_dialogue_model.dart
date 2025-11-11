import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import 'provider_rejection_dialogue_widget.dart'
    show ProviderRejectionDialogueWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProviderRejectionDialogueModel
    extends FlutterFlowModel<ProviderRejectionDialogueWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Reasons widget.
  FormFieldController<List<String>>? reasonsValueController;
  List<String>? get reasonsValues => reasonsValueController?.value;
  set reasonsValues(List<String>? val) => reasonsValueController?.value = val;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
