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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SignInModel extends FlutterFlowModel<SignInWidget> {
  ///  Local state fields for this page.

  String? userphone;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for SignUp widget.
  TabController? signUpController;
  int get signUpCurrentIndex =>
      signUpController != null ? signUpController!.index : 0;
  int get signUpPreviousIndex =>
      signUpController != null ? signUpController!.previousIndex : 0;

  // State field(s) for password widget.
  FocusNode? passwordFocusNode1;
  TextEditingController? passwordTextController1;
  late bool passwordVisibility1;
  String? Function(BuildContext, String?)? passwordTextController1Validator;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UsersRow>? resultLOgged;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UserProfilesRow>? loggedRole;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<MedicalProviderProfilesRow>? providerStatus;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<FacilityAdminProfilesRow>? facilityAdminStatus;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode2;
  TextEditingController? passwordTextController2;
  late bool passwordVisibility2;
  String? Function(BuildContext, String?)? passwordTextController2Validator;
  String? _passwordTextController2Validator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'f1eom26b' /* Password is required */,
      );
    }

    if (val.length < 8) {
      return FFLocalizations.of(context).getText(
        'yelrhjwb' /* Password does not meet require... */,
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
  // Stores action output result for [Backend Call - API (SendOtp)] action in Button widget.
  ApiCallResponse? apiResultefj;

  @override
  void initState(BuildContext context) {
    passwordVisibility1 = false;
    passwordVisibility2 = false;
    passwordTextController2Validator = _passwordTextController2Validator;
    passwordConfirmVisibility = false;
  }

  @override
  void dispose() {
    signUpController?.dispose();
    passwordFocusNode1?.dispose();
    passwordTextController1?.dispose();

    passwordFocusNode2?.dispose();
    passwordTextController2?.dispose();

    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();
  }
}
