import '/backend/api_requests/api_calls.dart';
import '/components/header_back/header_back_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'facility_search_page_widget.dart' show FacilitySearchPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FacilitySearchPageModel
    extends FlutterFlowModel<FacilitySearchPageWidget> {
  ///  Local state fields for this page.

  String? facilitySearchQuery;

  String? facilitySelectedStatus;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (Facilities)] action in facilitySearchPage widget.
  ApiCallResponse? facilitiesAPIResponse;
  // Model for Header_Back component.
  late HeaderBackModel headerBackModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for DropDownfacilityType widget.
  String? dropDownfacilityTypeValue1;
  FormFieldController<String>? dropDownfacilityTypeValueController1;
  // State field(s) for DropDownfacilityType widget.
  String? dropDownfacilityTypeValue2;
  FormFieldController<String>? dropDownfacilityTypeValueController2;

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
