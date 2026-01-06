import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'payment_referal_model.dart';
export 'payment_referal_model.dart';

class PaymentReferalWidget extends StatefulWidget {
  const PaymentReferalWidget({
    super.key,
    double? amount,
    this.providerid,
    this.facilityid,
    this.startdate,
    this.starttime,
    this.consultationmode,
    this.service,
    required this.helptype,
    this.appointmentID,
  }) : this.amount = amount ?? 0.0;

  final double amount;
  final String? providerid;
  final String? facilityid;
  final DateTime? startdate;
  final DateTime? starttime;
  final String? consultationmode;
  final String? service;

  /// determinds the path to take
  final String? helptype;

  final String? appointmentID;

  @override
  State<PaymentReferalWidget> createState() => _PaymentReferalWidgetState();
}

class _PaymentReferalWidgetState extends State<PaymentReferalWidget>
    with TickerProviderStateMixin {
  late PaymentReferalModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentReferalModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 300.ms),
          MoveEffect(
            curve: Curves.bounceOut,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, 100.0),
            end: Offset(0.0, 0.0),
          ),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).accent4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 2.0, 16.0, 16.0),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 670.0,
              ),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12.0,
                    color: Color(0x1E000000),
                    offset: Offset(
                      0.0,
                      5.0,
                    ),
                  )
                ],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 0.0, 0.0),
                    child: GradientText(
                      FFLocalizations.of(context).getText(
                        'effddxsg' /* Help Me pay */,
                      ),
                      style:
                          FlutterFlowTheme.of(context).headlineMedium.override(
                                font: GoogleFonts.readexPro(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontStyle,
                              ),
                      colors: [
                        FlutterFlowTheme.of(context).primary,
                        FlutterFlowTheme.of(context).secondary
                      ],
                      gradientDirection: GradientDirection.ltr,
                      gradientType: GradientType.linear,
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 4.0, 0.0, 0.0),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        'pxcptbex' /* Please insert the phone number... */,
                      ),
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 12.0, 24.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 10.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 50.0,
                                    child: custom_widgets.CountryPhonePicker(
                                      width: double.infinity,
                                      height: 50.0,
                                      onChanged: (phoneNumber) async {
                                        _model.userphone = phoneNumber;
                                        safeSetState(() {});
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 24.0, 24.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.05),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    'uoqwh0pk' /* Cancel */,
                                  ),
                                  options: FFButtonOptions(
                                    height: 44.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        24.0, 0.0, 24.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).error,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    elevation: 40.0,
                                    borderRadius: BorderRadius.circular(20.0),
                                    hoverColor: Color(0xFFDC2626),
                                    hoverBorderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.05),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (widget!.helptype == 'new') {
                                      _model.initialisepayment =
                                          await PaymentGroup
                                              .initializePaymentCall
                                              .call(
                                        amount: widget!.amount.toString(),
                                        transactionID: 'Medzen-${dateTimeFormat(
                                          "jms",
                                          random_data.randomDate(),
                                          locale: FFLocalizations.of(context)
                                              .languageCode,
                                        )}',
                                      );

                                      if ((_model
                                              .initialisepayment?.succeeded ??
                                          true)) {
                                        if ((String var1) {
                                          return var1.startsWith('+237');
                                        }(_model.userphone!)) {
                                          _model.apiResultlfg =
                                              await AwsSmsCall.call(
                                            phonenumber: _model.userphone,
                                            message:
                                                'Hi From Medzen E-Health .  ${currentUserDisplayName}Has Requested You help them Pay their E-Health bill of ${widget!.amount.toString()}XAF , Please use this link to pay :  ${PaymentGroup.initializePaymentCall.transactionURL(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            )}',
                                          );

                                          if ((_model.apiResultlfg?.succeeded ??
                                              true)) {
                                            _model.appointment1 =
                                                await AppointmentsTable()
                                                    .insert({
                                              'patient_id':
                                                  FFAppState().AuthuserID,
                                              'provider_id': widget!.providerid,
                                              'start_date':
                                                  supaSerialize<DateTime>(
                                                      widget!.startdate),
                                              'appointment_type':
                                                  widget!.service,
                                              'appointment_number':
                                                  'Appt-${random_data.randomInteger(0, 10).toString()}',
                                              'status': 'pending',
                                              'consultation_mode':
                                                  widget!.consultationmode,
                                              'scheduled_start':
                                                  supaSerialize<DateTime>(
                                                      widget!.startdate),
                                              'scheduled_end':
                                                  supaSerialize<DateTime>(
                                                      widget!.starttime),
                                              'facility_id': widget!.facilityid,
                                            });
                                            await PaymentsTable().insert({
                                              'payment_for': widget!.service,
                                              'net_amount': widget!.amount,
                                              'payment_reference': PaymentGroup
                                                  .initializePaymentCall
                                                  .transactionID(
                                                (_model.initialisepayment
                                                        ?.jsonBody ??
                                                    ''),
                                              ),
                                              'gross_amount': widget!.amount,
                                              'payment_status': 'completed',
                                              'payer_id':
                                                  FFAppState().AuthuserID,
                                              'transaction_id': PaymentGroup
                                                  .initializePaymentCall
                                                  .transactionID(
                                                (_model.initialisepayment
                                                        ?.jsonBody ??
                                                    ''),
                                              ),
                                              'appointment_id':
                                                  _model.appointment1?.id,
                                              'facility_id': widget!.facilityid,
                                              'external_transaction_id': '',
                                              'recipient_id':
                                                  widget!.providerid,
                                            });
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .clearSnackBars();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Payment Successful. Booking has been confirmed',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                duration: Duration(
                                                    milliseconds: 4000),
                                                backgroundColor:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                              ),
                                            );

                                            context.pushNamed(
                                                AppointmentsWidget.routeName);
                                          } else {
                                            await showDialog(
                                              context: context,
                                              builder: (alertDialogContext) {
                                                return AlertDialog(
                                                  title: Text(
                                                      'Failed to ask for Help'),
                                                  content: Text(
                                                      'We were unable to to contact the recipient at the moment. Please try again later'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              alertDialogContext),
                                                      child: Text('Ok'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        } else {
                                          _model.apiResultpdo =
                                              await HelpMePayCall.call(
                                            phone: _model.userphone,
                                            sms:
                                                'Hi From Medzen E-Health .  ${currentUserDisplayName}Has Requested You help them Pay their E-Health bill of ${widget!.amount.toString()}XAF , Please use this link to pay ${PaymentGroup.initializePaymentCall.transactionURL(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            )}',
                                          );

                                          if ((_model.apiResultpdo?.succeeded ??
                                              true)) {
                                            _model.appointment =
                                                await AppointmentsTable()
                                                    .insert({
                                              'patient_id':
                                                  FFAppState().AuthuserID,
                                              'provider_id': widget!.providerid,
                                              'start_date':
                                                  supaSerialize<DateTime>(
                                                      widget!.startdate),
                                              'appointment_type':
                                                  widget!.service,
                                              'appointment_number':
                                                  'Appt-${random_data.randomInteger(0, 10).toString()}',
                                              'status': 'pending',
                                              'consultation_mode':
                                                  widget!.consultationmode,
                                              'scheduled_start':
                                                  supaSerialize<DateTime>(
                                                      widget!.startdate),
                                              'scheduled_end':
                                                  supaSerialize<DateTime>(
                                                      widget!.starttime),
                                              'facility_id': widget!.facilityid,
                                            });
                                            await PaymentsTable().insert({
                                              'payment_for': widget!.service,
                                              'net_amount': widget!.amount,
                                              'payment_reference': PaymentGroup
                                                  .initializePaymentCall
                                                  .transactionID(
                                                (_model.initialisepayment
                                                        ?.jsonBody ??
                                                    ''),
                                              ),
                                              'gross_amount': widget!.amount,
                                              'payment_status': 'completed',
                                              'payer_id':
                                                  FFAppState().AuthuserID,
                                              'transaction_id': PaymentGroup
                                                  .initializePaymentCall
                                                  .transactionID(
                                                (_model.initialisepayment
                                                        ?.jsonBody ??
                                                    ''),
                                              ),
                                              'appointment_id':
                                                  _model.appointment?.id,
                                              'facility_id': widget!.facilityid,
                                              'external_transaction_id': '',
                                              'recipient_id':
                                                  widget!.providerid,
                                            });
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .clearSnackBars();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Payment Successful. Booking has been confirmed',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                duration: Duration(
                                                    milliseconds: 4000),
                                                backgroundColor:
                                                    FlutterFlowTheme.of(context)
                                                        .success,
                                              ),
                                            );

                                            context.pushNamed(
                                                AppointmentsWidget.routeName);
                                          } else {
                                            await showDialog(
                                              context: context,
                                              builder: (alertDialogContext) {
                                                return AlertDialog(
                                                  title: Text(
                                                      'Failed to ask for Help'),
                                                  content: Text(
                                                      'We were unable to to contact the recipient at the moment. Please try again later'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              alertDialogContext),
                                                      child: Text('Ok'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        }
                                      } else {
                                        context.safePop();
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Process failed. Please try again later',
                                              style: TextStyle(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                            ),
                                            duration:
                                                Duration(milliseconds: 4000),
                                            backgroundColor:
                                                FlutterFlowTheme.of(context)
                                                    .error,
                                          ),
                                        );
                                      }
                                    } else {
                                      _model.paymenturl =
                                          await PaymentsTable().queryRows(
                                        queryFn: (q) => q.eqOrNull(
                                          'appointment_id',
                                          widget!.appointmentID,
                                        ),
                                      );
                                      if ((String var1) {
                                        return var1.startsWith('+237');
                                      }(_model.userphone!)) {
                                        _model.apiResult1qi =
                                            await AwsSmsCall.call(
                                          phonenumber: _model.userphone,
                                          message:
                                              'Hi From Medzen E-Health. ${currentUserDisplayName}Has Requested You help them Pay their E-Health bill of ${widget!.amount.toString()}XAF , Please use this link to pay  ${_model.paymenturl?.firstOrNull?.paymentUrl}',
                                        );

                                        if ((_model.apiResult1qi?.succeeded ??
                                            true)) {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Help sent ',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                ),
                                              ),
                                              duration:
                                                  Duration(milliseconds: 4000),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Service unavailable. please retry later',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                ),
                                              ),
                                              duration:
                                                  Duration(milliseconds: 4000),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                            ),
                                          );
                                        }
                                      } else {
                                        _model.resendhelp =
                                            await HelpMePayCall.call(
                                          phone: _model.userphone,
                                          sms:
                                              'Hi From Medzen E-Health. ${currentUserDisplayName}Has Requested You help them Pay their E-Health bill of ${widget!.amount.toString()}XAF , Please use this link to pay  ${_model.paymenturl?.firstOrNull?.paymentUrl}',
                                        );

                                        if ((_model.resendhelp?.succeeded ??
                                            true)) {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Help sent ',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                ),
                                              ),
                                              duration:
                                                  Duration(milliseconds: 4000),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Service unavailable. please retry later',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                ),
                                              ),
                                              duration:
                                                  Duration(milliseconds: 4000),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .error,
                                            ),
                                          );
                                        }
                                      }
                                    }

                                    safeSetState(() {});
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    'uzjl28zl' /* Send  */,
                                  ),
                                  options: FFButtonOptions(
                                    height: 44.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        24.0, 0.0, 24.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: Color(0xFF305A8B),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 40.0,
                                    borderSide: BorderSide(
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(20.0),
                                    hoverColor:
                                        FlutterFlowTheme.of(context).primary,
                                    hoverBorderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      width: 1.0,
                                    ),
                                    hoverElevation: 0.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
          ),
        ],
      ),
    );
  }
}
