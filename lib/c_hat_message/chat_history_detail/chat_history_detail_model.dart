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
import 'chat_history_detail_widget.dart' show ChatHistoryDetailWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatHistoryDetailModel extends FlutterFlowModel<ChatHistoryDetailWidget> {
  ///  Local state fields for this page.

  bool isLoading = false;

  List<AiMessagesRow> messages = [];
  void addToMessages(AiMessagesRow item) => messages.add(item);
  void removeFromMessages(AiMessagesRow item) => messages.remove(item);
  void removeAtIndexFromMessages(int index) => messages.removeAt(index);
  void insertAtIndexInMessages(int index, AiMessagesRow item) =>
      messages.insert(index, item);
  void updateMessagesAtIndex(int index, Function(AiMessagesRow) updateFn) =>
      messages[index] = updateFn(messages[index]);

  List<AiConversationsRow> currentConversation = [];
  void addToCurrentConversation(AiConversationsRow item) =>
      currentConversation.add(item);
  void removeFromCurrentConversation(AiConversationsRow item) =>
      currentConversation.remove(item);
  void removeAtIndexFromCurrentConversation(int index) =>
      currentConversation.removeAt(index);
  void insertAtIndexInCurrentConversation(int index, AiConversationsRow item) =>
      currentConversation.insert(index, item);
  void updateCurrentConversationAtIndex(
          int index, Function(AiConversationsRow) updateFn) =>
      currentConversation[index] = updateFn(currentConversation[index]);

  ///  State fields for stateful widgets in this page.

  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;
  // Model for TopBar component.
  late TopBarModel topBarModel;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
    topBarModel = createModel(context, () => TopBarModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    mainBottomNavModel.dispose();
    topBarModel.dispose();
  }
}
