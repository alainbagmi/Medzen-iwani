import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'appointments_widget.dart' show AppointmentsWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class AppointmentsModel extends FlutterFlowModel<AppointmentsWidget> {
  ///  Local state fields for this page.

  List<dynamic> appointments = [];
  void addToAppointments(dynamic item) => appointments.add(item);
  void removeFromAppointments(dynamic item) => appointments.remove(item);
  void removeAtIndexFromAppointments(int index) => appointments.removeAt(index);
  void insertAtIndexInAppointments(int index, dynamic item) =>
      appointments.insert(index, item);
  void updateAppointmentsAtIndex(int index, Function(dynamic) updateFn) =>
      appointments[index] = updateFn(appointments[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (PatientAppointments)] action in Appointments widget.
  ApiCallResponse? patientappointments;
  // Stores action output result for [Backend Call - API (MedicalProviderAppointments)] action in Appointments widget.
  ApiCallResponse? providerappointments;
  // Stores action output result for [Backend Call - API (FacilityAppointments)] action in Appointments widget.
  ApiCallResponse? facilityAppointments;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
  }
}
