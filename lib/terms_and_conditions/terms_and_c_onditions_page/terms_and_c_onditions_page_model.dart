import '/components/header_back/header_back_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'terms_and_c_onditions_page_widget.dart'
    show TermsAndCOnditionsPageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TermsAndCOnditionsPageModel
    extends FlutterFlowModel<TermsAndCOnditionsPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Header_Back component.
  late HeaderBackModel headerBackModel;

  @override
  void initState(BuildContext context) {
    headerBackModel = createModel(context, () => HeaderBackModel());
  }

  @override
  void dispose() {
    headerBackModel.dispose();
  }
}
