import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/coming_soon/coming_soon_widget.dart';
import '/components/system_admin_bottom_nav/system_admin_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/index.dart';
import 'system_admin_landing_page_widget.dart'
    show SystemAdminLandingPageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class SystemAdminLandingPageModel
    extends FlutterFlowModel<SystemAdminLandingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Model for system_admin_bottom_Nav component.
  late SystemAdminBottomNavModel systemAdminBottomNavModel;

  @override
  void initState(BuildContext context) {
    systemAdminBottomNavModel =
        createModel(context, () => SystemAdminBottomNavModel());
  }

  @override
  void dispose() {
    systemAdminBottomNavModel.dispose();
  }
}
