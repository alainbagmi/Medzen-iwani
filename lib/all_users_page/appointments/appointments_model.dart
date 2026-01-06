import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/appointment_status/appointment_status_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/retry_payment/retry_payment_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/summary_notes/summary_notes_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'appointments_widget.dart' show AppointmentsWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AppointmentsModel extends FlutterFlowModel<AppointmentsWidget> {
  ///  Local state fields for this page.

  List<AppointmentOverviewRow> appointments = [];
  void addToAppointments(AppointmentOverviewRow item) => appointments.add(item);
  void removeFromAppointments(AppointmentOverviewRow item) =>
      appointments.remove(item);
  void removeAtIndexFromAppointments(int index) => appointments.removeAt(index);
  void insertAtIndexInAppointments(int index, AppointmentOverviewRow item) =>
      appointments.insert(index, item);
  void updateAppointmentsAtIndex(
          int index, Function(AppointmentOverviewRow) updateFn) =>
      appointments[index] = updateFn(appointments[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in Appointments widget.
  List<AppointmentOverviewRow>? patientappointments;
  // Stores action output result for [Backend Call - Query Rows] action in Appointments widget.
  List<AppointmentOverviewRow>? providerappointments;
  // Stores action output result for [Backend Call - Query Rows] action in Appointments widget.
  List<AppointmentOverviewRow>? facilityappointments;
  // Stores action output result for [Backend Call - Query Rows] action in Appointments widget.
  List<AppointmentOverviewRow>? allappointments;
  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<PaymentsRow>? appointment;
  // Stores action output result for [Backend Call - API (GetPaymentStatus)] action in Button widget.
  ApiCallResponse? checkpayment;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<PaymentsRow>? paymentdetails;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    topBarModel = createModel(context, () => TopBarModel());
    sideNavModel = createModel(context, () => SideNavModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    topBarModel.dispose();
    sideNavModel.dispose();
    tabBarController?.dispose();
    mainBottomNavModel.dispose();
  }
}
