import '/components/header_back/header_back_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'appoitment_status_page_widget.dart' show AppoitmentStatusPageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AppoitmentStatusPageModel
    extends FlutterFlowModel<AppoitmentStatusPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Header_Back component.
  late HeaderBackModel headerBackModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    headerBackModel = createModel(context, () => HeaderBackModel());
  }

  @override
  void dispose() {
    headerBackModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
