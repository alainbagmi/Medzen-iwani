import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/coming_soon/coming_soon_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'care_center_settings_page_widget.dart'
    show CareCenterSettingsPageWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CareCenterSettingsPageModel
    extends FlutterFlowModel<CareCenterSettingsPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (GetFacilities)] action in careCenterSettingsPage widget.
  ApiCallResponse? allFacilitiess;
  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  bool isDataUploading_uploadData23t = false;
  FFUploadedFile uploadedLocalFile_uploadData23t =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData23t = '';

  // State field(s) for consultation_fee widget.
  FocusNode? consultationFeeFocusNode;
  TextEditingController? consultationFeeTextController;
  String? Function(BuildContext, String?)?
      consultationFeeTextControllerValidator;
  // State field(s) for EmailAddress widget.
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  // State field(s) for phonenumber widget.
  FocusNode? phonenumberFocusNode;
  TextEditingController? phonenumberTextController;
  String? Function(BuildContext, String?)? phonenumberTextControllerValidator;
  // State field(s) for location widget.
  FocusNode? locationFocusNode;
  TextEditingController? locationTextController;
  String? Function(BuildContext, String?)? locationTextControllerValidator;
  // State field(s) for website widget.
  FocusNode? websiteFocusNode;
  TextEditingController? websiteTextController;
  String? Function(BuildContext, String?)? websiteTextControllerValidator;
  // State field(s) for about widget.
  FocusNode? aboutFocusNode;
  TextEditingController? aboutTextController;
  String? Function(BuildContext, String?)? aboutTextControllerValidator;
  // State field(s) for DropDown widget.
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  // State field(s) for DropDown widget.
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;
  // State field(s) for Switch widget.
  bool? switchValue1;
  // State field(s) for Switch widget.
  bool? switchValue2;
  // State field(s) for Switch widget.
  bool? switchValue3;
  // State field(s) for Switch widget.
  bool? switchValue4;
  // State field(s) for newDepartmentName widget.
  FocusNode? newDepartmentNameFocusNode;
  TextEditingController? newDepartmentNameTextController;
  String? Function(BuildContext, String?)?
      newDepartmentNameTextControllerValidator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue1;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode1;
  TextEditingController? endTimeTextController1;
  String? Function(BuildContext, String?)? endTimeTextController1Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode2;
  TextEditingController? endTimeTextController2;
  String? Function(BuildContext, String?)? endTimeTextController2Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue2;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode1;
  TextEditingController? startTimeTextController1;
  String? Function(BuildContext, String?)? startTimeTextController1Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode3;
  TextEditingController? endTimeTextController3;
  String? Function(BuildContext, String?)? endTimeTextController3Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue3;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode2;
  TextEditingController? startTimeTextController2;
  String? Function(BuildContext, String?)? startTimeTextController2Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode4;
  TextEditingController? endTimeTextController4;
  String? Function(BuildContext, String?)? endTimeTextController4Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue4;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode3;
  TextEditingController? startTimeTextController3;
  String? Function(BuildContext, String?)? startTimeTextController3Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode5;
  TextEditingController? endTimeTextController5;
  String? Function(BuildContext, String?)? endTimeTextController5Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue5;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode4;
  TextEditingController? startTimeTextController4;
  String? Function(BuildContext, String?)? startTimeTextController4Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode6;
  TextEditingController? endTimeTextController6;
  String? Function(BuildContext, String?)? endTimeTextController6Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue6;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode5;
  TextEditingController? startTimeTextController5;
  String? Function(BuildContext, String?)? startTimeTextController5Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode7;
  TextEditingController? endTimeTextController7;
  String? Function(BuildContext, String?)? endTimeTextController7Validator;
  // State field(s) for SelectDay widget.
  bool? selectDayValue7;
  // State field(s) for StartTime widget.
  FocusNode? startTimeFocusNode6;
  TextEditingController? startTimeTextController6;
  String? Function(BuildContext, String?)? startTimeTextController6Validator;
  // State field(s) for EndTime widget.
  FocusNode? endTimeFocusNode8;
  TextEditingController? endTimeTextController8;
  String? Function(BuildContext, String?)? endTimeTextController8Validator;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    topBarModel = createModel(context, () => TopBarModel());
    sideNavModel = createModel(context, () => SideNavModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    topBarModel.dispose();
    sideNavModel.dispose();
    consultationFeeFocusNode?.dispose();
    consultationFeeTextController?.dispose();

    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    phonenumberFocusNode?.dispose();
    phonenumberTextController?.dispose();

    locationFocusNode?.dispose();
    locationTextController?.dispose();

    websiteFocusNode?.dispose();
    websiteTextController?.dispose();

    aboutFocusNode?.dispose();
    aboutTextController?.dispose();

    newDepartmentNameFocusNode?.dispose();
    newDepartmentNameTextController?.dispose();

    endTimeFocusNode1?.dispose();
    endTimeTextController1?.dispose();

    endTimeFocusNode2?.dispose();
    endTimeTextController2?.dispose();

    startTimeFocusNode1?.dispose();
    startTimeTextController1?.dispose();

    endTimeFocusNode3?.dispose();
    endTimeTextController3?.dispose();

    startTimeFocusNode2?.dispose();
    startTimeTextController2?.dispose();

    endTimeFocusNode4?.dispose();
    endTimeTextController4?.dispose();

    startTimeFocusNode3?.dispose();
    startTimeTextController3?.dispose();

    endTimeFocusNode5?.dispose();
    endTimeTextController5?.dispose();

    startTimeFocusNode4?.dispose();
    startTimeTextController4?.dispose();

    endTimeFocusNode6?.dispose();
    endTimeTextController6?.dispose();

    startTimeFocusNode5?.dispose();
    startTimeTextController5?.dispose();

    endTimeFocusNode7?.dispose();
    endTimeTextController7?.dispose();

    startTimeFocusNode6?.dispose();
    startTimeTextController6?.dispose();

    endTimeFocusNode8?.dispose();
    endTimeTextController8?.dispose();

    mainBottomNavModel.dispose();
  }
}
