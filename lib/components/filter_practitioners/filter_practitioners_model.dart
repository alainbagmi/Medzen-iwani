import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import 'filter_practitioners_widget.dart' show FilterPractitionersWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FilterPractitionersModel
    extends FlutterFlowModel<FilterPractitionersWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for SelectedGender widget.
  FormFieldController<List<String>>? selectedGenderValueController;
  String? get selectedGenderValue =>
      selectedGenderValueController?.value?.firstOrNull;
  set selectedGenderValue(String? val) =>
      selectedGenderValueController?.value = val != null ? [val] : [];
  // State field(s) for Selectedspecialty widget.
  String? selectedspecialtyValue;
  FormFieldController<String>? selectedspecialtyValueController;
  // State field(s) for proximity widget.
  bool? proximityValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
