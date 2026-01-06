import '/components/medzen_header_back/medzen_header_back_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'terms_and_conditions_widget.dart' show TermsAndConditionsWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TermsAndConditionsModel
    extends FlutterFlowModel<TermsAndConditionsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for medzen_header_back component.
  late MedzenHeaderBackModel medzenHeaderBackModel;

  @override
  void initState(BuildContext context) {
    medzenHeaderBackModel = createModel(context, () => MedzenHeaderBackModel());
  }

  @override
  void dispose() {
    medzenHeaderBackModel.dispose();
  }
}
