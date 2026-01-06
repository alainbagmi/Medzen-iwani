import '/backend/supabase/supabase.dart';
import '/chat_a_i/start_chat/start_chat_widget.dart';
import '/components/admin_top_bar/admin_top_bar_widget.dart';
import '/components/coming_soon/coming_soon_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'system_admin_landing_page_widget.dart'
    show SystemAdminLandingPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SystemAdminLandingPageModel
    extends FlutterFlowModel<SystemAdminLandingPageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for AdminTopBar component.
  late AdminTopBarModel adminTopBarModel;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    topBarModel = createModel(context, () => TopBarModel());
    adminTopBarModel = createModel(context, () => AdminTopBarModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    topBarModel.dispose();
    adminTopBarModel.dispose();
    mainBottomNavModel.dispose();
  }
}
