import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/password_reset_for_settings_page/password_reset_for_settings_page_widget.dart';
import '/components/paymentmethods/paymentmethods_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import 'patients_settings_page_widget.dart' show PatientsSettingsPageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PatientsSettingsPageModel
    extends FlutterFlowModel<PatientsSettingsPageWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading_uploadData6b2 = false;
  FFUploadedFile uploadedLocalFile_uploadData6b2 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData6b2 = '';

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
  }
}
