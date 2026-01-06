import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/chat_a_i/start_chat/start_chat_widget.dart';
import '/components/admin_top_bar/admin_top_bar_widget.dart';
import '/components/coming_soon/coming_soon_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'facility_admin_landing_page_widget.dart'
    show FacilityAdminLandingPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class FacilityAdminLandingPageModel
    extends FlutterFlowModel<FacilityAdminLandingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (UserDetails)] action in facilityAdminLanding_page widget.
  ApiCallResponse? userData;
  // Stores action output result for [Backend Call - Query Rows] action in facilityAdminLanding_page widget.
  List<AppointmentsRow>? appointmentstats;
  // Stores action output result for [Backend Call - Query Rows] action in facilityAdminLanding_page widget.
  List<MedicalProviderProfilesRow>? providers;
  // Stores action output result for [Backend Call - Query Rows] action in facilityAdminLanding_page widget.
  List<FacilityAdminProfilesRow>? facilityadmins;
  // Stores action output result for [Backend Call - Query Rows] action in facilityAdminLanding_page widget.
  List<FacilitiesRow>? facilityName;
  // Model for AdminTopBar component.
  late AdminTopBarModel adminTopBarModel;
  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    adminTopBarModel = createModel(context, () => AdminTopBarModel());
    topBarModel = createModel(context, () => TopBarModel());
    sideNavModel = createModel(context, () => SideNavModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    adminTopBarModel.dispose();
    topBarModel.dispose();
    sideNavModel.dispose();
    mainBottomNavModel.dispose();
  }
}
