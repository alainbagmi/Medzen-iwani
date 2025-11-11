import '/backend/api_requests/api_calls.dart';
import '/components/password_reset_for_settings_page/password_reset_for_settings_page_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'provider_settings_page_widget.dart' show ProviderSettingsPageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProviderSettingsPageModel
    extends FlutterFlowModel<ProviderSettingsPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for phonenumber widget.
  FocusNode? phonenumberFocusNode;
  TextEditingController? phonenumberTextController;
  String? Function(BuildContext, String?)? phonenumberTextControllerValidator;
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

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    phonenumberFocusNode?.dispose();
    phonenumberTextController?.dispose();

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
  }
}
