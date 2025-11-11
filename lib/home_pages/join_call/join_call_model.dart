import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'join_call_widget.dart' show JoinCallWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class JoinCallModel extends FlutterFlowModel<JoinCallWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  // State field(s) for channelName widget.
  FocusNode? channelNameFocusNode;
  TextEditingController? channelNameTextController;
  String? Function(BuildContext, String?)? channelNameTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    channelNameFocusNode?.dispose();
    channelNameTextController?.dispose();
  }
}
