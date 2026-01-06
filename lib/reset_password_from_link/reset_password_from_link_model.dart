import '/components/medzen_landing_header/medzen_landing_header_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'reset_password_from_link_widget.dart' show ResetPasswordFromLinkWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ResetPasswordFromLinkModel
    extends FlutterFlowModel<ResetPasswordFromLinkWidget> {
  ///  Local state fields for this page.

  String? newPassword;

  String? confirmPassword;

  bool? isLoading;

  ///  State fields for stateful widgets in this page.

  // Model for medzen_landing_header component.
  late MedzenLandingHeaderModel medzenLandingHeaderModel;
  // State field(s) for Newpassword widget.
  FocusNode? newpasswordFocusNode;
  TextEditingController? newpasswordTextController;
  late bool newpasswordVisibility;
  String? Function(BuildContext, String?)? newpasswordTextControllerValidator;
  // State field(s) for ConfirmPassword widget.
  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  late bool confirmPasswordVisibility;
  String? Function(BuildContext, String?)?
      confirmPasswordTextControllerValidator;

  @override
  void initState(BuildContext context) {
    medzenLandingHeaderModel =
        createModel(context, () => MedzenLandingHeaderModel());
    newpasswordVisibility = false;
    confirmPasswordVisibility = false;
  }

  @override
  void dispose() {
    medzenLandingHeaderModel.dispose();
    newpasswordFocusNode?.dispose();
    newpasswordTextController?.dispose();

    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }
}
