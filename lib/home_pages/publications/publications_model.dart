import '/components/medzen_landing_header/medzen_landing_header_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'publications_widget.dart' show PublicationsWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PublicationsModel extends FlutterFlowModel<PublicationsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for medzen_landing_header component.
  late MedzenLandingHeaderModel medzenLandingHeaderModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for DropDown widget.
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  // State field(s) for DropDown widget.
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;
  // State field(s) for DropDown widget.
  String? dropDownValue3;
  FormFieldController<String>? dropDownValueController3;

  @override
  void initState(BuildContext context) {
    medzenLandingHeaderModel =
        createModel(context, () => MedzenLandingHeaderModel());
  }

  @override
  void dispose() {
    medzenLandingHeaderModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
