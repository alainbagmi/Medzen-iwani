import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/logout/logout_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'facility_admin_profile_page_widget.dart'
    show FacilityAdminProfilePageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FacilityAdminProfilePageModel
    extends FlutterFlowModel<FacilityAdminProfilePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in facilityAdminProfilePage widget.
  List<UsersRow>? loggedUser;
  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel1;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for logout component.
  late LogoutModel logoutModel;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel2;

  @override
  void initState(BuildContext context) {
    topBarModel = createModel(context, () => TopBarModel());
    mainBottomNavModel1 = createModel(context, () => MainBottomNavModel());
    sideNavModel = createModel(context, () => SideNavModel());
    logoutModel = createModel(context, () => LogoutModel());
    mainBottomNavModel2 = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    topBarModel.dispose();
    mainBottomNavModel1.dispose();
    sideNavModel.dispose();
    logoutModel.dispose();
    mainBottomNavModel2.dispose();
  }
}
