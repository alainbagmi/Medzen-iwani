import '/backend/supabase/supabase.dart';
import '/components/booking_summary/booking_summary_widget.dart';
import '/components/filter_practitioners/filter_practitioners_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'medical_practitioners_widget.dart' show MedicalPractitionersWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MedicalPractitionersModel
    extends FlutterFlowModel<MedicalPractitionersWidget> {
  ///  Local state fields for this page.

  String? searchProviders;

  String? gender;

  String? specialty;

  ///  State fields for stateful widgets in this page.

  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for SearchProviders widget.
  FocusNode? searchProvidersFocusNode;
  TextEditingController? searchProvidersTextController;
  String? Function(BuildContext, String?)?
      searchProvidersTextControllerValidator;
  // Stores action output result for [Bottom Sheet - FilterPractitioners] action in IconButton widget.
  String? filters;

  @override
  void initState(BuildContext context) {
    topBarModel = createModel(context, () => TopBarModel());
    sideNavModel = createModel(context, () => SideNavModel());
  }

  @override
  void dispose() {
    topBarModel.dispose();
    sideNavModel.dispose();
    searchProvidersFocusNode?.dispose();
    searchProvidersTextController?.dispose();
  }
}
