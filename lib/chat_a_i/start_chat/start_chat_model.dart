import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'start_chat_widget.dart' show StartChatWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class StartChatModel extends FlutterFlowModel<StartChatWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - createAIConversation] action in StartNewChatButton widget.
  String? newConversationId;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
