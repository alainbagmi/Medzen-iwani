import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/header_back/header_back_widget.dart';
import '/components/provider_rejection_dialogue/provider_rejection_dialogue_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'provider_status_page_widget.dart' show ProviderStatusPageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProviderStatusPageModel
    extends FlutterFlowModel<ProviderStatusPageWidget> {
  ///  Local state fields for this page.

  String? providerSearchQuery;

  String? providerSelecetedStatus;

  String? providerSelectedRejectionText;

  ///  State fields for stateful widgets in this page.

  // Model for Header_Back component.
  late HeaderBackModel headerBackModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  Completer<ApiCallResponse>? apiRequestCompleter;

  @override
  void initState(BuildContext context) {
    headerBackModel = createModel(context, () => HeaderBackModel());
  }

  @override
  void dispose() {
    headerBackModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  /// Additional helper methods.
  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
