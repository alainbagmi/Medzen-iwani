import '/components/coming_soon/coming_soon_widget.dart';
import '/components/facility_admin_bottom_nav/facility_admin_bottom_nav_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/index.dart';
import 'facility_admin_landing_page_widget.dart'
    show FacilityAdminLandingPageWidget;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class FacilityAdminLandingPageModel
    extends FlutterFlowModel<FacilityAdminLandingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Model for Facility_admin_bottom_Nav component.
  late FacilityAdminBottomNavModel facilityAdminBottomNavModel;

  @override
  void initState(BuildContext context) {
    facilityAdminBottomNavModel =
        createModel(context, () => FacilityAdminBottomNavModel());
  }

  @override
  void dispose() {
    facilityAdminBottomNavModel.dispose();
  }
}
