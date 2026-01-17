import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/supabase/supabase.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/password_reset_for_settings_page/password_reset_for_settings_page_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'provider_settings_page_widget.dart' show ProviderSettingsPageWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProviderSettingsPageModel
    extends FlutterFlowModel<ProviderSettingsPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  bool isDataUploading_uploadDataGr8 = false;
  FFUploadedFile uploadedLocalFile_uploadDataGr8 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataGr8 = '';

  // State field(s) for LicenseNumber widget.
  FocusNode? licenseNumberFocusNode;
  TextEditingController? licenseNumberTextController;
  String? Function(BuildContext, String?)? licenseNumberTextControllerValidator;
  // State field(s) for consultationFee widget.
  FocusNode? consultationFeeFocusNode;
  TextEditingController? consultationFeeTextController;
  String? Function(BuildContext, String?)?
      consultationFeeTextControllerValidator;
  // State field(s) for insuranceprovider widget.
  FocusNode? insuranceproviderFocusNode;
  TextEditingController? insuranceproviderTextController;
  String? Function(BuildContext, String?)?
      insuranceproviderTextControllerValidator;
  // State field(s) for policynumber widget.
  FocusNode? policynumberFocusNode;
  TextEditingController? policynumberTextController;
  String? Function(BuildContext, String?)? policynumberTextControllerValidator;
  // State field(s) for emergencyName widget.
  FocusNode? emergencyNameFocusNode;
  TextEditingController? emergencyNameTextController;
  String? Function(BuildContext, String?)? emergencyNameTextControllerValidator;
  // State field(s) for emergencyrelationship widget.
  FocusNode? emergencyrelationshipFocusNode;
  TextEditingController? emergencyrelationshipTextController;
  String? Function(BuildContext, String?)?
      emergencyrelationshipTextControllerValidator;
  // State field(s) for emergencyPhone widget.
  FocusNode? emergencyPhoneFocusNode;
  TextEditingController? emergencyPhoneTextController;
  String? Function(BuildContext, String?)?
      emergencyPhoneTextControllerValidator;
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
  // State field(s) for Switch widget.
  bool? switchValue1;
  // State field(s) for Switch widget.
  bool? switchValue2;
  // State field(s) for Switch widget.
  bool? switchValue3;
  // State field(s) for Switch widget.
  bool? switchValue4;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;
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
    licenseNumberFocusNode?.dispose();
    licenseNumberTextController?.dispose();

    consultationFeeFocusNode?.dispose();
    consultationFeeTextController?.dispose();

    insuranceproviderFocusNode?.dispose();
    insuranceproviderTextController?.dispose();

    policynumberFocusNode?.dispose();
    policynumberTextController?.dispose();

    emergencyNameFocusNode?.dispose();
    emergencyNameTextController?.dispose();

    emergencyrelationshipFocusNode?.dispose();
    emergencyrelationshipTextController?.dispose();

    emergencyPhoneFocusNode?.dispose();
    emergencyPhoneTextController?.dispose();

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
