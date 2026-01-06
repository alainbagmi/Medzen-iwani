import '/backend/api_requests/api_calls.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'care_center_search_page_widget.dart' show CareCenterSearchPageWidget;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CareCenterSearchPageModel
    extends FlutterFlowModel<CareCenterSearchPageWidget> {
  ///  Local state fields for this page.

  String? facilitySearchQuery;

  String? facilitySelectedStatus;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (Facilities)] action in CareCenterSearchPage widget.
  ApiCallResponse? facilitiesAPIResponse;
  // Model for TopBar component.
  late TopBarModel topBarModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  Completer<ApiCallResponse>? apiRequestCompleter;
  // State field(s) for DropDownfacilityType widget.
  String? dropDownfacilityTypeValue1;
  FormFieldController<String>? dropDownfacilityTypeValueController1;
  // State field(s) for DropDownfacilityType widget.
  String? dropDownfacilityTypeValue2;
  FormFieldController<String>? dropDownfacilityTypeValueController2;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    topBarModel = createModel(context, () => TopBarModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    topBarModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();

    mainBottomNavModel.dispose();
  }

  /// Additional helper methods.
  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
