import '/components/medzen_footer/medzen_footer_widget.dart';
import '/components/medzen_header_back/medzen_header_back_widget.dart';
import '/components/medzen_mobile_footer/medzen_mobile_footer_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'role_page_widget.dart' show RolePageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RolePageModel extends FlutterFlowModel<RolePageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for medzen_header_back component.
  late MedzenHeaderBackModel medzenHeaderBackModel;
  // Model for medzen_footer component.
  late MedzenFooterModel medzenFooterModel;
  // Model for medzen_mobile_footer component.
  late MedzenMobileFooterModel medzenMobileFooterModel;

  @override
  void initState(BuildContext context) {
    medzenHeaderBackModel = createModel(context, () => MedzenHeaderBackModel());
    medzenFooterModel = createModel(context, () => MedzenFooterModel());
    medzenMobileFooterModel =
        createModel(context, () => MedzenMobileFooterModel());
  }

  @override
  void dispose() {
    medzenHeaderBackModel.dispose();
    medzenFooterModel.dispose();
    medzenMobileFooterModel.dispose();
  }
}
