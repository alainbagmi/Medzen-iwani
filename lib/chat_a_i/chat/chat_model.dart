import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/chat_a_i/writing_indicator/writing_indicator_widget.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import 'chat_widget.dart' show ChatWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatModel extends FlutterFlowModel<ChatWidget> {
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

  // Stores action output result for [Backend Call - Query Rows] action in chat widget.
  List<AiConversationsRow>? modelcurrentConversation;
  // Stores action output result for [Backend Call - Query Rows] action in chat widget.
  List<AiMessagesRow>? modelmessages;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for ConversationListView widget.
  ScrollController? conversationListViewScrollController;
  // State field(s) for PromptTextField widget.
  FocusNode? promptTextFieldFocusNode;
  TextEditingController? promptTextFieldTextController;
  String? Function(BuildContext, String?)?
      promptTextFieldTextControllerValidator;
  // Stores action output result for [Custom Action - buildConversationHistory] action in SendIconButton widget.
  List<dynamic>? conversationHistory;
  // Stores action output result for [Custom Action - sendBedrockMessage] action in SendIconButton widget.
  dynamic? aiResponse;
  // Stores action output result for [Backend Call - Query Rows] action in SendIconButton widget.
  List<AiMessagesRow>? messagesResult;
  // Model for main_bottom_nav component.
  late MainBottomNavModel mainBottomNavModel;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    conversationListViewScrollController = ScrollController();
    mainBottomNavModel = createModel(context, () => MainBottomNavModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    conversationListViewScrollController?.dispose();
    promptTextFieldFocusNode?.dispose();
    promptTextFieldTextController?.dispose();

    mainBottomNavModel.dispose();
  }
}
