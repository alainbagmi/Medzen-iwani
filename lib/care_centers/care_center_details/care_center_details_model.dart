import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/booking_summary/booking_summary_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/medzen_header_back/medzen_header_back_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'care_center_details_widget.dart' show CareCenterDetailsWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class CareCenterDetailsModel extends FlutterFlowModel<CareCenterDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (GetFacilities)] action in CareCenterDetails widget.
  ApiCallResponse? allFacilities;
  // Model for medzen_header_back component.
  late MedzenHeaderBackModel medzenHeaderBackModel;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    medzenHeaderBackModel = createModel(context, () => MedzenHeaderBackModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    medzenHeaderBackModel.dispose();
    tabBarController?.dispose();
    mainBottomNavModel.dispose();
  }
}
