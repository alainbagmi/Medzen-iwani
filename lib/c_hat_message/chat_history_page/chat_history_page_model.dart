import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
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
import 'chat_history_page_widget.dart' show ChatHistoryPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatHistoryPageModel extends FlutterFlowModel<ChatHistoryPageWidget> {
  ///  Local state fields for this page.

  List<AiConversationsRow> conversations = [];
  void addToConversations(AiConversationsRow item) => conversations.add(item);
  void removeFromConversations(AiConversationsRow item) =>
      conversations.remove(item);
  void removeAtIndexFromConversations(int index) =>
      conversations.removeAt(index);
  void insertAtIndexInConversations(int index, AiConversationsRow item) =>
      conversations.insert(index, item);
  void updateConversationsAtIndex(
          int index, Function(AiConversationsRow) updateFn) =>
      conversations[index] = updateFn(conversations[index]);

  ///  State fields for stateful widgets in this page.

  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
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
    mainBottomNavModel.dispose();
  }
}
