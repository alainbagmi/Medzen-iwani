import '/components/medzen_footer/medzen_footer_widget.dart';
import '/components/medzen_mobile_footer/medzen_mobile_footer_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for medzen_footer component.
  late MedzenFooterModel medzenFooterModel;
  // Model for medzen_mobile_footer component.
  late MedzenMobileFooterModel medzenMobileFooterModel;

  @override
  void initState(BuildContext context) {
    medzenFooterModel = createModel(context, () => MedzenFooterModel());
    medzenMobileFooterModel =
        createModel(context, () => MedzenMobileFooterModel());
  }

  @override
  void dispose() {
    medzenFooterModel.dispose();
    medzenMobileFooterModel.dispose();
  }
}
