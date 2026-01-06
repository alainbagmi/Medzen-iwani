import '/auth/firebase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/main_bottom_nav/main_bottom_nav_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/components/top_bar/top_bar_widget.dart';
import '/components/withdraw_request/withdraw_request_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'payment_history_widget.dart' show PaymentHistoryWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class PaymentHistoryModel extends FlutterFlowModel<PaymentHistoryWidget> {
  ///  Local state fields for this page.

  List<PaymentsRow> payments = [];
  void addToPayments(PaymentsRow item) => payments.add(item);
  void removeFromPayments(PaymentsRow item) => payments.remove(item);
  void removeAtIndexFromPayments(int index) => payments.removeAt(index);
  void insertAtIndexInPayments(int index, PaymentsRow item) =>
      payments.insert(index, item);
  void updatePaymentsAtIndex(int index, Function(PaymentsRow) updateFn) =>
      payments[index] = updateFn(payments[index]);

  List<WithdrawalsRow> withdrawals = [];
  void addToWithdrawals(WithdrawalsRow item) => withdrawals.add(item);
  void removeFromWithdrawals(WithdrawalsRow item) => withdrawals.remove(item);
  void removeAtIndexFromWithdrawals(int index) => withdrawals.removeAt(index);
  void insertAtIndexInWithdrawals(int index, WithdrawalsRow item) =>
      withdrawals.insert(index, item);
  void updateWithdrawalsAtIndex(int index, Function(WithdrawalsRow) updateFn) =>
      withdrawals[index] = updateFn(withdrawals[index]);

  double? totalamt;

  double? withdrawn = 0.0;

  double? balance = 0.0;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<PaymentsRow>? patientpayments;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<PaymentsRow>? facilitypayments;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<WithdrawalsRow>? withdrawfacility;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<PaymentTotalsRow>? total;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<WithdrawalTotalsRow>? withdrawaltotal;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<PaymentsRow>? providerpayments;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<WithdrawalsRow>? withdrawpraactitioner;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<PaymentTotalsRow>? providertotal;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<WithdrawalTotalsRow>? providerwithdrawal;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<PaymentsRow>? allpayments;
  // Stores action output result for [Backend Call - Query Rows] action in PaymentHistory widget.
  List<WithdrawalsRow>? allwithdrawals;
  // Model for TopBar component.
  late TopBarModel topBarModel;
  // Model for SideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for TabBar widget.
  TabController? tabBarController1;
  int get tabBarCurrentIndex1 =>
      tabBarController1 != null ? tabBarController1!.index : 0;
  int get tabBarPreviousIndex1 =>
      tabBarController1 != null ? tabBarController1!.previousIndex : 0;

  // State field(s) for TabBar widget.
  TabController? tabBarController2;
  int get tabBarCurrentIndex2 =>
      tabBarController2 != null ? tabBarController2!.index : 0;
  int get tabBarPreviousIndex2 =>
      tabBarController2 != null ? tabBarController2!.previousIndex : 0;

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
    tabBarController1?.dispose();
    tabBarController2?.dispose();
    mainBottomNavModel.dispose();
  }
}
