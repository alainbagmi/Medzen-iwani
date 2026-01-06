import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/otp/otp_widget.dart';
import '/components/reset_password/reset_password_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'sign_in_widget.dart' show SignInWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SignInModel extends FlutterFlowModel<SignInWidget> {
  ///  Local state fields for this page.

  String? userphone;

  bool termsAccepted = false;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for MainTap widget.
  TabController? mainTapController;
  int get mainTapCurrentIndex =>
      mainTapController != null ? mainTapController!.index : 0;
  int get mainTapPreviousIndex =>
      mainTapController != null ? mainTapController!.previousIndex : 0;

  // State field(s) for SignIpassword widget.
  FocusNode? signIpasswordFocusNode;
  TextEditingController? signIpasswordTextController;
  late bool signIpasswordVisibility;
  String? Function(BuildContext, String?)? signIpasswordTextControllerValidator;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UsersRow>? resultLOgged;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UserProfilesRow>? loggedRole;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MedicalProviderProfilesRow>? providerStatus;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<FacilityAdminProfilesRow>? facilityAdminStatus;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  String? _passwordTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '4yb91xok' /* Passwod required */,
      );
    }

    if (!RegExp('^(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,}\$')
        .hasMatch(val)) {
      return FFLocalizations.of(context).getText(
        'dkh9yucf' /* Minimum length of 8 characters... */,
      );
    }
    return null;
  }

  // State field(s) for passwordConfirm widget.
  FocusNode? passwordConfirmFocusNode;
  TextEditingController? passwordConfirmTextController;
  late bool passwordConfirmVisibility;
  String? Function(BuildContext, String?)?
      passwordConfirmTextControllerValidator;
  // State field(s) for TermsConditionsBox widget.
  bool? termsConditionsBoxValue;
  // Stores action output result for [Backend Call - API (checkuser)] action in Button widget.
  ApiCallResponse? checkuser;
  // Stores action output result for [Backend Call - API (AWS Send OTP)] action in Button widget.
  ApiCallResponse? apisendotp;
  // Stores action output result for [Backend Call - API (SendOtp)] action in Button widget.
  ApiCallResponse? apiResultefj;

  @override
  void initState(BuildContext context) {
    signIpasswordVisibility = false;
    passwordVisibility = false;
    passwordTextControllerValidator = _passwordTextControllerValidator;
    passwordConfirmVisibility = false;
  }

  @override
  void dispose() {
    mainTapController?.dispose();
    signIpasswordFocusNode?.dispose();
    signIpasswordTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();
  }
}
