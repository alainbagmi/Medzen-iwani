import '/components/medzen_landing_header/medzen_landing_header_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'facility_details_page_widget.dart' show FacilityDetailsPageWidget;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FacilityDetailsPageModel
    extends FlutterFlowModel<FacilityDetailsPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for medzen_landing_header component.
  late MedzenLandingHeaderModel medzenLandingHeaderModel;
  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;
  // State field(s) for RatingBar widget.
  double? ratingBarValue;

  @override
  void initState(BuildContext context) {
    medzenLandingHeaderModel =
        createModel(context, () => MedzenLandingHeaderModel());
  }

  @override
  void dispose() {
    medzenLandingHeaderModel.dispose();
  }
}
