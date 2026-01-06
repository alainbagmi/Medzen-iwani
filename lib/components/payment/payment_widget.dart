import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/payment_progress/payment_progress_widget.dart';
import '/components/payment_referal/payment_referal_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_credit_card_form.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'payment_model.dart';
export 'payment_model.dart';

class PaymentWidget extends StatefulWidget {
  const PaymentWidget({
    super.key,
    required this.service,
    required this.amount,
    this.providerid,
    this.facilityid,
    this.startdate,
    this.starttime,
    required this.servicetype,
    this.consultationmode,
  });

  final String? service;
  final double? amount;
  final String? providerid;
  final String? facilityid;
  final DateTime? startdate;
  final DateTime? starttime;

  /// Payment service
  final String? servicetype;

  final String? consultationmode;

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget>
    with TickerProviderStateMixin {
  late PaymentModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PaymentModel());

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 0.0, 0.0),
                    child: GradientText(
                      FFLocalizations.of(context).getText(
                        'ouwo7td1' /* Check Out */,
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
                        'ru0ay34f' /* Fill in the information below ... */,
                      ),
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
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
                                child: FlutterFlowDropDown<String>(
                                  controller:
                                      _model.paymentMethodValueController ??=
                                          FormFieldController<String>(null),
                                  options: [
                                    FFLocalizations.of(context).getText(
                                      '81m6y43n' /* MTN */,
                                    ),
                                    FFLocalizations.of(context).getText(
                                      'g61zr6qp' /* ORANGE */,
                                    ),
                                    FFLocalizations.of(context).getText(
                                      'mvpnsup5' /* CARD */,
                                    )
                                  ],
                                  onChanged: (val) => safeSetState(
                                      () => _model.paymentMethodValue = val),
                                  width: 200.0,
                                  height: 40.0,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                  hintText: FFLocalizations.of(context).getText(
                                    'aocyeiko' /* Select Payment method... */,
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 24.0,
                                  ),
                                  fillColor: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  elevation: 2.0,
                                  borderColor: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  borderWidth: 1.0,
                                  borderRadius: 8.0,
                                  margin: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 0.0, 12.0, 0.0),
                                  hidesUnderline: true,
                                  isOverButton: false,
                                  isSearchable: false,
                                  isMultiSelect: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((_model.paymentMethodValue != null &&
                                _model.paymentMethodValue != '') &&
                            ((_model.paymentMethodValue != 'CARD') ||
                                (_model.paymentMethodValue != 'CARTE')))
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
                                          _model.userPhoneNumber = phoneNumber;
                                          safeSetState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((_model.paymentMethodValue == 'CARD') &&
                            responsiveVisibility(
                              context: context,
                              phone: false,
                              tablet: false,
                              tabletLandscape: false,
                              desktop: false,
                            ))
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 12.0, 24.0, 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: FlutterFlowCreditCardForm(
                                    formKey: _model.creditCardFormKey,
                                    creditCardModel: _model.creditCardInfo,
                                    obscureNumber: false,
                                    obscureCvv: false,
                                    spacing: 10.0,
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
                                    inputDecoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((_model.paymentMethodValue == 'CARD') ||
                            (_model.paymentMethodValue != 'CARTE'))
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                10.0, 0.0, 0.0, 0.0),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'dy2pzba5' /* Card details are required only... */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).error,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        Divider(
                          thickness: 2.0,
                          indent: 10.0,
                          endIndent: 10.0,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GradientText(
                                FFLocalizations.of(context).getText(
                                  'sficywx1' /* Service :  */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                colors: [
                                  FlutterFlowTheme.of(context).primary,
                                  FlutterFlowTheme.of(context).secondary
                                ],
                                gradientDirection: GradientDirection.ltr,
                                gradientType: GradientType.linear,
                              ),
                              Text(
                                valueOrDefault<String>(
                                  widget!.service,
                                  'Service',
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 10.0, 24.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GradientText(
                                FFLocalizations.of(context).getText(
                                  'm7u4dnbs' /* Amount  :  */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                colors: [
                                  FlutterFlowTheme.of(context).primary,
                                  FlutterFlowTheme.of(context).secondary
                                ],
                                gradientDirection: GradientDirection.ltr,
                                gradientType: GradientType.linear,
                              ),
                              Text(
                                '${widget!.amount?.toString()}xaf',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          thickness: 2.0,
                          indent: 10.0,
                          endIndent: 10.0,
                          color: FlutterFlowTheme.of(context).primary,
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
                                    'gax980qf' /* Cancel */,
                                  ),
                                  options: FFButtonOptions(
                                    width: 110.0,
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
                                    hoverColor: Color(0xFFEE0505),
                                    hoverBorderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                    ),
                                    hoverTextColor: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.05),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    _model.initialisepayment =
                                        await PaymentGroup.initializePaymentCall
                                            .call(
                                      amount: widget!.amount?.toString(),
                                      transactionID: 'Medzen-${dateTimeFormat(
                                        "jms",
                                        random_data.randomDate(),
                                        locale: FFLocalizations.of(context)
                                            .languageCode,
                                      )}',
                                    );

                                    if ((_model.initialisepayment?.succeeded ??
                                        true)) {
                                      if ((_model.paymentMethodValue ==
                                              'CARD') ||
                                          (_model.paymentMethodValue ==
                                              'CARTE')) {
                                        await launchURL(PaymentGroup
                                            .initializePaymentCall
                                            .transactionURL(
                                          (_model.initialisepayment?.jsonBody ??
                                              ''),
                                        )!);
                                        if (widget!.servicetype ==
                                            'appointment') {
                                          _model.appointmentCard =
                                              await AppointmentsTable().insert({
                                            'patient_id':
                                                FFAppState().AuthuserID,
                                            'provider_id': widget!.providerid,
                                            'start_date':
                                                supaSerialize<DateTime>(
                                                    widget!.startdate),
                                            'appointment_type': widget!.service,
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
                                            'payment_method': () {
                                              if (_model.paymentMethodValue ==
                                                  'ORANGE') {
                                                return 'orange_money';
                                              } else if (_model
                                                      .paymentMethodValue ==
                                                  'MTN') {
                                                return 'mtn_momo';
                                              } else {
                                                return 'visa';
                                              }
                                            }(),
                                            'payment_reference': PaymentGroup
                                                .initializePaymentCall
                                                .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'gross_amount': widget!.amount,
                                            'payment_status': 'pending',
                                            'payer_id': FFAppState().AuthuserID,
                                            'transaction_id': PaymentGroup
                                                .initializePaymentCall
                                                .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'external_transaction_id':
                                                PaymentGroup
                                                    .initializePaymentCall
                                                    .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'appointment_id':
                                                _model.appointmentCard?.id,
                                            'payment_url': PaymentGroup
                                                .initializePaymentCall
                                                .transactionURL(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'facility_id': widget!.facilityid,
                                            'recipient_id': widget!.providerid,
                                          });
                                          // Check Payment Status
                                          _model.checkCardPayment =
                                              await PaymentGroup
                                                  .getPaymentStatusCall
                                                  .call(
                                            transactionID: PaymentGroup
                                                .initializePaymentCall
                                                .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                          );

                                          if (PaymentGroup.getPaymentStatusCall
                                                  .transactionStatus(
                                                (_model.checkPayment
                                                        ?.jsonBody ??
                                                    ''),
                                              ) ==
                                              'SUCCESS') {
                                            await AppointmentsTable().update(
                                              data: {
                                                'status': 'scheduled',
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'id',
                                                _model.appointmentCard?.id,
                                              ),
                                            );
                                            await PaymentsTable().update(
                                              data: {
                                                'payment_status': 'SUCCESS',
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'transaction_id',
                                                PaymentGroup
                                                    .initializePaymentCall
                                                    .transactionID(
                                                  (_model.initialisepayment
                                                          ?.jsonBody ??
                                                      ''),
                                                ),
                                              ),
                                            );

                                            context.pushNamed(
                                                AppointmentsWidget.routeName);

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Appointment booked successfully',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
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
                                          } else {
                                            context.pushNamed(
                                                AppointmentsWidget.routeName);

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Payment might have failed . please refresh or try again later',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                duration: Duration(
                                                    milliseconds: 4000),
                                                backgroundColor:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                              ),
                                            );
                                          }
                                        } else {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Only appointments are available at this time',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryBackground,
                                                  fontWeight: FontWeight.w600,
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
                                        _model.mobileMoney = await PaymentGroup
                                            .mobileMoneyCall
                                            .call(
                                          transactionID: PaymentGroup
                                              .initializePaymentCall
                                              .transactionID(
                                            (_model.initialisepayment
                                                    ?.jsonBody ??
                                                ''),
                                          ),
                                          paymentMethod:
                                              _model.paymentMethodValue == 'MTN'
                                                  ? 'CM_MTNMOMO'
                                                  : 'CM_ORANGE',
                                          amount: widget!.amount?.toString(),
                                          phone: _model.userPhoneNumber,
                                        );

                                        if (widget!.servicetype ==
                                            'appointment') {
                                          _model.appointment =
                                              await AppointmentsTable().insert({
                                            'patient_id':
                                                FFAppState().AuthuserID,
                                            'provider_id': widget!.providerid,
                                            'start_date':
                                                supaSerialize<DateTime>(
                                                    widget!.startdate),
                                            'appointment_type': widget!.service,
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
                                            'payment_method': () {
                                              if (_model.paymentMethodValue ==
                                                  'ORANGE') {
                                                return 'orange_money';
                                              } else if (_model
                                                      .paymentMethodValue ==
                                                  'MTN') {
                                                return 'mtn_momo';
                                              } else {
                                                return 'visa';
                                              }
                                            }(),
                                            'payment_reference': PaymentGroup
                                                .initializePaymentCall
                                                .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'gross_amount': widget!.amount,
                                            'payment_status': 'pending',
                                            'payer_id': FFAppState().AuthuserID,
                                            'transaction_id': PaymentGroup
                                                .initializePaymentCall
                                                .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'external_transaction_id':
                                                PaymentGroup
                                                    .initializePaymentCall
                                                    .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'appointment_id':
                                                _model.appointment?.id,
                                            'payment_url': PaymentGroup
                                                .initializePaymentCall
                                                .transactionURL(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                            'facility_id': widget!.facilityid,
                                            'recipient_id': widget!.providerid,
                                          });
                                          await showModalBottomSheet(
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            enableDrag: false,
                                            context: context,
                                            builder: (context) {
                                              return Padding(
                                                padding:
                                                    MediaQuery.viewInsetsOf(
                                                        context),
                                                child: PaymentProgressWidget(
                                                  paymentmethod: _model
                                                      .paymentMethodValue!,
                                                ),
                                              );
                                            },
                                          ).then(
                                              (value) => safeSetState(() {}));

                                          // Check Payment Status
                                          _model.checkPayment =
                                              await PaymentGroup
                                                  .getPaymentStatusCall
                                                  .call(
                                            transactionID: PaymentGroup
                                                .initializePaymentCall
                                                .transactionID(
                                              (_model.initialisepayment
                                                      ?.jsonBody ??
                                                  ''),
                                            ),
                                          );

                                          if (PaymentGroup.getPaymentStatusCall
                                                  .transactionStatus(
                                                (_model.checkPayment
                                                        ?.jsonBody ??
                                                    ''),
                                              ) ==
                                              'SUCCESS') {
                                            await AppointmentsTable().update(
                                              data: {
                                                'status': 'scheduled',
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'id',
                                                _model.appointment?.id,
                                              ),
                                            );
                                            await PaymentsTable().update(
                                              data: {
                                                'payment_status': PaymentGroup
                                                    .getPaymentStatusCall
                                                    .transactionStatus(
                                                  (_model.checkPayment
                                                          ?.jsonBody ??
                                                      ''),
                                                ),
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'transaction_id',
                                                PaymentGroup
                                                    .initializePaymentCall
                                                    .transactionID(
                                                  (_model.initialisepayment
                                                          ?.jsonBody ??
                                                      ''),
                                                ),
                                              ),
                                            );

                                            context.pushNamed(
                                                AppointmentsWidget.routeName);

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Appointment booked successfully',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
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
                                          } else {
                                            context.pushNamed(
                                                AppointmentsWidget.routeName);

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Payment might have failed . please refresh or try again later',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                duration: Duration(
                                                    milliseconds: 4000),
                                                backgroundColor:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                              ),
                                            );
                                          }
                                        } else {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .clearSnackBars();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Payment Failed',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryBackground,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              duration:
                                                  Duration(milliseconds: 4000),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .success,
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      await showDialog(
                                        context: context,
                                        builder: (alertDialogContext) {
                                          return AlertDialog(
                                            title: Text('Payment Failed'),
                                            content: Text(
                                                'Sorry we are unable to process your payment please try again later'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    alertDialogContext),
                                                child: Text('Ok'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }

                                    safeSetState(() {});
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    'rpcrguni' /* Pay Now */,
                                  ),
                                  options: FFButtonOptions(
                                    width: 110.0,
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
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 24.0, 24.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.05),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding:
                                              MediaQuery.viewInsetsOf(context),
                                          child: PaymentReferalWidget(
                                            amount: widget!.amount,
                                            providerid: widget!.providerid,
                                            facilityid: widget!.facilityid,
                                            startdate: widget!.startdate,
                                            starttime: widget!.starttime,
                                            consultationmode:
                                                widget!.consultationmode,
                                            service: widget!.service,
                                            helptype: 'new',
                                          ),
                                        );
                                      },
                                    ).then((value) => safeSetState(() {}));
                                  },
                                  text: FFLocalizations.of(context).getText(
                                    '6sdfyf7a' /* Help Me Pay */,
                                  ),
                                  icon: FaIcon(
                                    FontAwesomeIcons.handsHelping,
                                    size: 15.0,
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
                                      color: Colors.transparent,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(20.0),
                                    hoverColor: Color(0xFF0757F9),
                                    hoverBorderSide: BorderSide(
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      width: 1.0,
                                    ),
                                    hoverTextColor: FlutterFlowTheme.of(context)
                                        .primaryBackground,
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
