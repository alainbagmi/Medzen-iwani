import '/components/medzen_footer/medzen_footer_widget.dart';
import '/components/medzen_landing_header/medzen_landing_header_widget.dart';
import '/components/medzen_mobile_footer/medzen_mobile_footer_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'features_widget.dart' show FeaturesWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FeaturesModel extends FlutterFlowModel<FeaturesWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for medzen_landing_header component.
  late MedzenLandingHeaderModel medzenLandingHeaderModel;
  // Model for medzen_mobile_footer component.
  late MedzenMobileFooterModel medzenMobileFooterModel;
  // Model for medzen_footer component.
  late MedzenFooterModel medzenFooterModel;

  @override
  void initState(BuildContext context) {
    medzenLandingHeaderModel =
        createModel(context, () => MedzenLandingHeaderModel());
    medzenMobileFooterModel =
        createModel(context, () => MedzenMobileFooterModel());
    medzenFooterModel = createModel(context, () => MedzenFooterModel());
  }

  @override
  void dispose() {
    medzenLandingHeaderModel.dispose();
    medzenMobileFooterModel.dispose();
    medzenFooterModel.dispose();
  }
}
