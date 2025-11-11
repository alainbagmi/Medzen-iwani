import '/backend/api_requests/api_calls.dart';
import '/components/facility_rejection_d_ialogue/facility_rejection_d_ialogue_widget.dart';
import '/components/header_back/header_back_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'facility_status_page_widget.dart' show FacilityStatusPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FacilityStatusPageModel
    extends FlutterFlowModel<FacilityStatusPageWidget> {
  ///  Local state fields for this page.

  String? facilitySearchQuery;

  String? facilitySelectedStatus;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (Facilities)] action in facilityStatusPage widget.
  ApiCallResponse? facilitiesAPIResponse;
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
